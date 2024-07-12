/*
Purpose:
    This sample function demonstrates how use lambda to call the titan embedding model to convert your text to an embedding.

2024-07-11: written by rjvgupta
*/ 
CREATE OR REPLACE EXTERNAL FUNCTION f_fastembed_embedding (varchar) RETURNS varchar(max) STABLE
LAMBDA 'f-fastembed-embedding-varchar' IAM_ROLE ':RedshiftRole';
