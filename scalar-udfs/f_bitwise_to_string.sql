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
CREATE OR REPLACE FUNCTION dba.f_bitwise_to_string(bitwise_column BIGINT, bits_in_column INT)
    RETURNS VARCHAR(255)
STABLE
AS $$
  # Convert column to binary, strip "0b" prefix, pad out with zeroes
  b = bin(bitwise_column)[2:].zfill(bits_in_column)
  return b
$$ LANGUAGE plpythonu;

/* Example usage:

udf=# CREATE TEMP TABLE bitwise_example (id INT, packed_bools BIGINT, packed_count INT);
CREATE TABLE

udf=# INSERT INTO bitwise_example 
udf-# VALUES (1, B'100011001'::integer, 9),
udf-#        (2, B'000011010'::integer, 9),
udf-#        (3, B'100011101'::integer, 9),
udf-#        (4, B'000110001'::integer, 9);
INSERT 0 4

udf=# SELECT id, packed_bools, f_bitwise_to_string(packed_bools,packed_count) FROM bitwise_example;
 id | packed_bools | f_bitwise_to_string 
----+--------------+--------------------
  2 |           26 | 000011010
  3 |          285 | 100011101
  4 |           49 | 000110001
  1 |          281 | 100011001
(4 rows)

*/