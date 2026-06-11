/*
Purpose: Provides a simple, non-locale aware way to format a number with user defined
         thousands and decimal separator.

2015-11-09: written by sdia
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_format_number(float, varchar, varchar, int, int, bool) RETURNS varchar IMMUTABLE
LAMBDA 'f-format-number-float-varchar-varchar-int-int-bool' IAM_ROLE ':RedshiftRole';
