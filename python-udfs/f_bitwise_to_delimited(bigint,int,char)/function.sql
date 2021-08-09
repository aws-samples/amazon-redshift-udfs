/*
Purpose: Bitwise operations are very fast in Redshift and are invaluable when dealing
         with many thousands of BOOLEAN columns. This function, most useful for exports,
         creates a VARCHAR, delimited by a specified character, from an INT column
         containing bit-wise encoded BOOLEAN values, e.g. 281 => '1,0,0,0,1,1,0,0,1'

Arguments:
    • `bitwise_column` - column containing bit-wise encoded BOOLEAN values
    • `bits_in_column` - number of bits encoded in the column
    • `delimiter`      - character that will delimit the output
test
2015-10-15: created by Joe Harris (https://github.com/joeharris76)
*/
CREATE OR REPLACE FUNCTION f_bitwise_to_delimited(bitwise_column BIGINT, bits_in_column INT, delimter CHAR(1))
    RETURNS VARCHAR(512)
STABLE
AS $$
  # Convert column to binary, strip "0b" prefix, pad out with zeroes
  b = bin(bitwise_column)[2:].zfill(bits_in_column)
  # Convert each character to a member of an array, join array into string using delimiter
  o = delimter.join([b[i:i+1] for i in range(0, len(b), 1)])
  return o
$$ LANGUAGE plpythonu;
