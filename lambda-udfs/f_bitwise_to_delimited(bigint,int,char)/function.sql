/*
Purpose: Bitwise operations are very fast in Redshift and are invaluable when dealing
         with many thousands of BOOLEAN columns. This function creates a VARCHAR,
         delimited by a specified character, from an INT column containing bit-wise
         encoded BOOLEAN values, e.g. 281 => '1,0,0,0,1,1,0,0,1'

Arguments:
    • `bitwise_column` - column containing bit-wise encoded BOOLEAN values
    • `bits_in_column` - number of bits encoded in the column
    • `delimiter`      - character that will delimit the output

2015-10-15: created by Joe Harris (https://github.com/joeharris76)
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_bitwise_to_delimited(bigint, int, char) RETURNS varchar STABLE
LAMBDA 'f-bitwise-to-delimited-bigint-int-char' IAM_ROLE ':RedshiftRole';
