/*
Purpose: Bitwise operations are very fast in Redshift and are invaluable when dealing
         with many thousands of BOOLEAN columns. This function creates a VARCHAR
         representation of an INT column containing bit-wise encoded BOOLEAN values,
         e.g. 281 => '100011001'

Arguments:
    • `bitwise_column` - column containing bit-wise encoded BOOLEAN values
    • `bits_in_column` - number of bits encoded in the column

2015-10-15: created by Joe Harris (https://github.com/joeharris76)
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_bitwise_to_string(bigint, int) RETURNS varchar STABLE
LAMBDA 'f-bitwise-to-string-bigint-int' IAM_ROLE ':RedshiftRole';
