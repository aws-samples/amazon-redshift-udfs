/**********************************************************************************************
Purpose: Execute vector search leveraging vector indexes 
Notes:  
        This procedure is used to execute a vectorized searh of your query string.  The procedure will create
        and on-the-fly embedding using the LambdaUDF f_titan_embeding(varchar) and compare the result to all
        data in your $(tablename)_embeddings table.  See the following article for more info:
        https://repost.aws/articles/ARPoweQIN2ROOXZiJAtSQvkQ/vector-search-with-amazon-redshift

Parameters:
        tablename : The table which was the source of the data which contains the batch embeddings and K-Means clusters. 
        search    : The texst you want to search
        cnt       : The number of results you want to return
        tmp_name  : The name of the temp table that will be created to return your search results.

Requirements:
        expects a table with the following tables to exist and be populated:
            CREATE TABLE $(tablename)_embeddings
                ( "recordId" VARCHAR(15),
                  "modelOutput" SUPER ) DISTKEY (recordid);
History:
2024-10-25 - rjvgupta - Created
**********************************************************************************************/
SET enable_case_sensitive_identifier TO true;

CREATE OR REPLACE PROCEDURE sp_vector_search_all (tablename IN varchar, search IN varchar, cnt IN int, tmp_name IN varchar) AS $$
BEGIN
    EXECUTE 'drop table if exists #'||tmp_name;
    EXECUTE 'create table #'||tmp_name ||' ("recordId" varchar(100), similarity float)';
    EXECUTE 'insert into #'||tmp_name ||'
        select re."recordId", sum(rv::float*qv::float)/SQRT(sum(rv::float*rv::float)*sum(qv::float*qv::float)) esimilarity
        from (select JSON_PARSE(f_titan_embedding('''+search+''')) as q) q, q.q qv at qvi, 
           '||tablename||'_embeddings re, re."modelOutput".embedding rv at rvi 
        where rvi = qvi
        group by 1
        qualify rank() over (order by esimilarity desc) <= '||cnt;
END $$ LANGUAGE plpgsql;

/* Usage Example:
SET enable_case_sensitive_identifier TO true;
call sp_vector_search_all('reviews', 'bat product quality', 100, 'searchresults')

select review_id, product_title, review_title, review_desc, similarity 
from  #searchresults 
join reviews on review_id = "recordId"
*/
