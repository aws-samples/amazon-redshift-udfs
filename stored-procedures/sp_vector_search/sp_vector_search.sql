/**********************************************************************************************
Purpose: Execute vector search leveraging vector indexes 
Notes:  
        This procedure is used to execute a vectorized searh of your query string.  The procedure will create
        and on-the-fly embedding using the LambdaUDF f_titan_embeding(varchar) and compare the result to your 
        K-Means clusters create using the stored procedure sp_vector_search.  See the following article for more info:
        https://repost.aws/articles/ARPoweQIN2ROOXZiJAtSQvkQ/vector-search-with-amazon-redshift

Parameters:
        tablename : The table which was the source of the data which contains the batch embeddings and K-Means clusters. 
        search    : The texst you want to search
        cnt       : The number of results you want to return
        tmp_name  : The name of the temp table that will be created to return your search results.

Requirements:
        expects a table with the following tables to exist and be populated:
            CREATE TABLE $(tablename)_embeddings
                ( recordid VARCHAR(15),
                  modeloutput SUPER ) DISTKEY (recordid);
            CREATE TABLE $(tablename)_kmeans 
                ( cluster int, 
                  centroid SUPER, 
                  startts timestamp, 
                  endts timestamp, 
                  interations int) DISTSTYLE ALL;
            CREATE TABLE $(tablename)_kmeans_clusters 
                ( cluster int, 
                  recordid VARCHAR(15), 
                  similarity float, 
                  rnk int) DISTKEY (recordid);

History:
2024-07-19 - rjvgupta - Created
**********************************************************************************************/

CREATE OR REPLACE PROCEDURE sp_vector_search (tablename IN varchar, search IN varchar, cnt IN int, tmp_name IN varchar) AS $$
BEGIN
    EXECUTE 'drop table if exists #'||tmp_name;
    EXECUTE 'create table #'||tmp_name ||' (recordid varchar(100), similarity float)';
    EXECUTE 'insert into #'||tmp_name ||'
        select re.recordid, sum(rv::float*qv::float)/SQRT(sum(rv::float*rv::float)*sum(qv::float*qv::float)) esimilarity
        from (
            select k.cluster, q.q, sum(kv::float*qv::float)/SQRT(sum(kv::float*kv::float)*sum(qv::float*qv::float)) csimilarity
            from '||tablename||'_kmeans k, k.centroid kv at kvi, 
            (select JSON_PARSE(f_titan_embedding('''+search+''')) as q) q, q.q qv at qvi
            where kvi = qvi 
            group by 1,2
            qualify rank() over (order by csimilarity desc) = 1
        ) q, '||tablename||'_kmeans_clusters c, '||tablename||'_embeddings re, q.q qv at qvi, re.modeloutput.embedding rv at rvi 
        where rvi = qvi and c.cluster = q.cluster and c.recordid = re.recordid
        group by 1
        qualify rank() over (order by esimilarity desc) <= '||cnt;
END $$ LANGUAGE plpgsql;

/* Usage Example:
call sp_kmeans('reviews', 'bat product quality', 100, 'searchresults')

select review_id, product_title, review_title, review_desc, similarity 
from  #searchresults 
join reviews on review_id = recordid
*/
