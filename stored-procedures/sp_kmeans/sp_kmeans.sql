/**********************************************************************************************
Purpose: Generate K-Means clusters from vector embeddings.
Notes:  
        This procedure is used to support vector search capabilities by creating K-Means clusters 
        generated and loaded into Redshift from embeddings; typically created by foundational models.
        The ouput of this procedure will be the <tablename>_kmeans table containing the cluster & centroid 
        and a <tablename>_kmeans_clusters table contain the member records of the cluster.  
        See the following article for more info:
        https://repost.aws/articles/ARPoweQIN2ROOXZiJAtSQvkQ/vector-search-with-amazon-redshift

Parameters:
        tablename : The table which was the source of the data which contains the batch embeddings. 
        clusters  : The number of K-Means clusters to create

Requirements:
        expects a table with the following tables to exist and be populated:
            CREATE TABLE $(tablename)_embeddings
                ( recordid VARCHAR,
                  modeloutput SUPER );

History:
2024-07-19 - rjvgupta - Created
**********************************************************************************************/

CREATE OR REPLACE PROCEDURE sp_kmeans (tablename IN varchar, clusters IN int) AS $$
DECLARE 
    cluster_size int;
    cluster int := 1;
    similarity float;
    i int;
BEGIN
    --will error if table doesn't exist
    EXECUTE 'select * from '||tablename||'_embeddings limit 1';

    EXECUTE 'SELECT CEIL(count(1)/'||clusters ||') 
        from ' || tablename||'_embeddings' INTO cluster_size;
    
    -- create kmeans tables and choose random starting centroids
    EXECUTE 'CREATE TABLE IF NOT EXISTS ' || tablename || '_kmeans (
        cluster int, centroid SUPER, startts timestamp, endts timestamp, 
        interations int) DISTSTYLE ALL';
    EXECUTE 'TRUNCATE TABLE ' || tablename || '_kmeans';

    EXECUTE 'CREATE TABLE IF NOT EXISTS ' || tablename || '_kmeans_clusters (
        cluster int, recordid varchar(15), similarity float, rnk int) 
        DISTKEY(recordid)';
    EXECUTE 'TRUNCATE TABLE ' || tablename || '_kmeans_clusters';
    
    WHILE cluster <= clusters LOOP
        --choose a random starting centroid from the remaining embeddings
        EXECUTE 'INSERT INTO ' || tablename || '_kmeans
            SELECT '||cluster||', modeloutput.embedding, 
                CURRENT_TIMESTAMP, NULL, NULL 
            FROM ' || tablename || '_embeddings 
            WHERE modeloutput.embedding is not null 
            AND recordid not in (
                select recordid from ' || tablename || '_kmeans_clusters) LIMIT 1';
        COMMIT;
        i := 1;
        similarity := 0;
        WHILE similarity < .999 LOOP
            --get embeddings closest to centroid
            EXECUTE 'DELETE FROM ' || tablename || '_kmeans_clusters 
                where cluster = '||cluster;
            EXECUTE 'INSERT INTO ' || tablename || '_kmeans_clusters
                select * from (select *, rank() over (partition by k.cluster order by k.similarity desc) rnk from (
                    select cluster, e.recordid, sum(kv::float*ev::float)/SQRT(sum(kv::float*kv::float)*sum(ev::float*ev::float)) similarity 
                    from ' || tablename || '_kmeans k, k.centroid kv at kvi,
                        ' || tablename || '_embeddings e, e.modeloutput.embedding ev at evi 
                    where kvi = evi and k.cluster = '||cluster||'
                    AND e.recordid not in (
                        select recordid from ' || tablename || '_kmeans_clusters)
                    group by 1,2) k
                ) r where r.rnk <= ' || cluster_size;
            COMMIT;
            -- determine new center
            EXECUTE 'DROP TABLE IF EXISTS #centroid';
            EXECUTE 'CREATE TABLE #centroid as
                SELECT JSON_PARSE(''['' || listagg(po::varchar, '','') within group (order by poi) || '']'') centroid 
                FROM (
                    select poi, avg(po::float) po
                    from ' || tablename || '_kmeans_clusters as nn, ' || tablename || '_embeddings re, re.modeloutput.embedding as po at poi
                        where nn.recordid = re.recordid and nn.cluster = ' || cluster || '
                    group by poi) as c';
            COMMIT;
            -- determine distance from new center to old center
            EXECUTE 'SELECT sum(kv::float*mv::float)/SQRT(sum(kv::float*kv::float)*sum(mv::float*mv::float))  
                    from #centroid k, k.centroid kv at kvi,
                        ' || tablename || '_kmeans m, m.centroid mv at mvi 
                    where m.cluster = '|| cluster ||' and kvi = mvi' INTO similarity;
            COMMIT;
            EXECUTE 'UPDATE ' || tablename || '_kmeans SET centroid = (select centroid from #centroid), endts = CURRENT_TIMESTAMP, interations = '|| i ||' where cluster = ' || cluster;
            COMMIT;
            i := i+1;
            COMMIT;
        END LOOP;
        cluster := cluster+1;
    END LOOP;
END
$$ LANGUAGE plpgsql;

/* Usage Example:
call sp_kmeans('reviews', 10)
*/
