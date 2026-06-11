/*
Purpose: This function showcases how parsing XML is possible with UDFs.

2015-09-10: written by chriz@
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_parse_xml(varchar) RETURNS varchar STABLE
LAMBDA 'f-parse-xml-varchar' IAM_ROLE ':RedshiftRole';
