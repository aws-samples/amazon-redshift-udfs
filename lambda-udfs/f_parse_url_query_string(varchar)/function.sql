/*
Purpose: This UDF takes a URL as an argument, and parses out the field-value pairs.
         Returns pairs in JSON for further parsing if needed.

2015-09-10: written by chriz@
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_parse_url_query_string(varchar) RETURNS varchar STABLE
LAMBDA 'f-parse-url-query-string-varchar' IAM_ROLE ':RedshiftRole';
