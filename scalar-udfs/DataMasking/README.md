# Data Masking Functions
=====

This library uses the `pycipher` module (https://pypi.python.org/pypi/pycipher and http://pycipher.readthedocs.org/en/latest) to perform simple data masking, which can be useful when exporting datasets between different databases or environments. Please note that one unfortunate side effect of the enciphering is that all characters are translated to UPPERCASE. 

## THIS IS NOT ENCRYPTION - USE WITH CAUTION
This module is focused on data masking rather than Encryption, and if you require strong encryption then please see the `pyaes` library in the `lib` directory.

## Functions

The module contains the following functions:

| function | Mode | Purpose | 
| ------------- | ------------- | ------------- | 
| f\_generate\_ciphertext\_key() | Volatile | Generates a pseudo-random ciphertext key | 
| f\_simple\_encipher(value VARCHAR, key VARCHAR) | Stable | Enciphers the specified value using a ciphertext key | 
| f\_simple\_decipher(value VARCHAR, key VARCHAR) | Stable | Deciphers the specified value using the original ciphertext key | 
| f\_affine\_encipher(value VARCHAR, mult INT, add INT) | Stable | Enciphers a specified value using the specified multiple and additive values (default 5,9) | 
| f\_affine\_decipher(value VARCHAR, mult INT, add INT) | Stable | Deciphers the supplied value using the original multiple and additive values |

## A Note on Affine Ciphers

For use of the Affine Ciphers, you must use a `mult` value that has no common factors to the supported alphabet character length (current 26). Given this, as set of possible mult values are: `1,3,5,7,9,11,15,17,19,21,23 and 25`; The `add` value can be any integer below 26 (including 0).