/*
Purpose:
    This sample function demonstrates how use lambda to call the titan embedding model to convert your text to an embedding.

2024-07-11: written by rjvgupta 
*/ 
CREATE OR REPLACE EXTERNAL FUNCTION f_titan_embedding (varchar) RETURNS varchar(max) STABLE
LAMBDA 'f-titan-embedding-varchar' IAM_ROLE ':RedshiftRole';
