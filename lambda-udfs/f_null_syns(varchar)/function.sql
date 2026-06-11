/*
Purpose: This function showcases python SET and BOOLEAN support as well as how an argument
         can be matched against synonyms, similar to a SQL IN condition.

2015-09-10: written by chriz@
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_null_syns(varchar) RETURNS bool STABLE
LAMBDA 'f-null-syns-varchar' IAM_ROLE ':RedshiftRole';
