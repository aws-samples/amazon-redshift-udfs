/*
Purpose: This UDF takes a URL and attribute name as arguments, and returns the specified
         attribute of the given URL.

2016-12-29: written by inohiro
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_parse_url(varchar, varchar) RETURNS varchar IMMUTABLE
LAMBDA 'f-parse-url-varchar-varchar' IAM_ROLE ':RedshiftRole';
