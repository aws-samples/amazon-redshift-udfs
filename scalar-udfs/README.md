# Redshift Scalar UDF Examples
Scalar UDF examples are intended to showcase various functionality of UDFs.
If you are using psql, you can use \i &lt;script.sql&gt; to run.

| Script | Purpose |
| ------------- | ------------- |
| f_bitwise_to_delimited.sql | Convert a column of booleans "packed" into an integer to a delimited string of 1s and 0s. |
| f_bitwise_to_string.sql | Convert a column of booleans "packed" into an integer to a string of 1s and 0s. |
| f\_format\_number.sql | Provides a simple, non-locale aware way to format a number with user defined  thousands and decimal separator |
| f\_next\_business\_day.sql | Uses pandas library to return dates which are US Federal Holiday aware |
| f\_null\_syns.sql | Uses python sets to match strings, similar to a SQL IN condition |
| f\_parse\_url\_query\_string.sql | Uses urlparse to parse the field-value pairs from a url query string |
| f\_parse\_url.sql | Uses urlparse to parse URL and returns specified attribute of given URL |
| f\_parse\_xml.sql | Uses xml.etree.ElementTree to parse XML |
| f\_unixts\_to\_timestamp.sql | Uses pandas library to convert a unix timestamp to UTC datetime |
| install\_substitution\_masking.sql | Installs a series of functions which allow you to perform simple data masking using either a simple substitution cipher, or an Affine cipher |

## install\_substitution\_masking.sql

This script installs the following functions into your Redshift database:

| function | Mode | Purpose | Linked Module |
| ------------- | ------------- | ------------- | ------------- |
| f\_generate\_ciphertext\_key() | Volatile | Generates a pseudo-random ciphertext key | SubstitutionMasking.generateCiphertextKey() |
| f\_simple\_encipher(value VARCHAR, key VARCHAR) | Stable | Enciphers the specified value using a ciphertext key | SubstitutionMasking.simpleEncipher() |
| f\_simple\_decipher(value VARCHAR, key VARCHAR) | Stable | Deciphers the specified value using the original ciphertext key | SubstitutionMasking.simpleDecipher() |
| f\_affine\_encipher(value VARCHAR, mult INT, add INT) | Stable | Enciphers a specified value using the specified multiple and additive values (default 5,9) | SubstitutionMasking.affineEncipher() |
| f\_affine\_decipher(value VARCHAR, mult INT, add INT) | Stable | Deciphers the supplied value using the original multiple and additive values | SubstitutionMasking.affineDecipher() |
