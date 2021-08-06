/* f_bitwise_to_string.sql

Purpose: Bitwise operations are very fast in Redshift and are invaluable when dealing
         with many thousands of BOOLEAN columns. This function, most useful for reporting,
         creates a VARCHAR representation of an INT column containing bit-wise encoded
         BOOLEAN values, e.g. 281 => '100011001'

Arguments:
    • `bitwise_column` - column containing bit-wise encoded BOOLEAN values
    • `bits_in_column` - number of bits encoded in the column

Internal dependencies: none

External dependencies: none

2015-10-15: created by Joe Harris (https://github.com/joeharris76)
*/
CREATE OR REPLACE FUNCTION f_bitwise_to_string(bitwise_column BIGINT, bits_in_column INT)
    RETURNS VARCHAR(255)
STABLE
AS $$
  # Convert column to binary, strip "0b" prefix, pad out with zeroes
  b = bin(bitwise_column)[2:].zfill(bits_in_column)
  return b
$$ LANGUAGE plpythonu;
