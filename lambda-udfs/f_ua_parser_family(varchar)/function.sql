/*
Purpose: This function will extract the browser family from the user_agent string.

2021-08-08: written by rjvgupta
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_ua_parser_family(varchar) RETURNS varchar IMMUTABLE
LAMBDA 'f-ua-parser-family-varchar' IAM_ROLE ':RedshiftRole';
