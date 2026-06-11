/*
Purpose: This function uses Levenshtein Distance to calculate the differences between sequences.

2022-08-14: written by saeedsb
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_fuzzy_string_match(varchar, varchar) RETURNS float IMMUTABLE
LAMBDA 'f-fuzzy-string-match-varchar-varchar' IAM_ROLE ':RedshiftRole';
