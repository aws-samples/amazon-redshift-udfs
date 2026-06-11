/*
Purpose: This function uses numpy to determine the similarity between two vectors.

2021-08-08: written by rjvgupta
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_cosine_similarity(varchar, varchar) RETURNS float8 IMMUTABLE
LAMBDA 'f-cosine-similarity-varchar-varchar' IAM_ROLE ':RedshiftRole';
