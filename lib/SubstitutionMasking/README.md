# SubstitutionMasking Library
=====

This library uses the `pycipher` module (https://pypi.python.org/pypi/pycipher and http://pycipher.readthedocs.org/en/latest) to perform simple data masking, which can be useful when exporting datasets between different databases or environments. This module is focused on data masking rather than Encryption, and if you require strong encryption then please see the `pyaes` library in the `lib` directory.

## Functions

The module contains the following functions:

| Function | Purpose |
| ------------- | ------------- |
| `generateCiphertextKey()`| Generates a seed key to be used by the data masking module. All enciphering requires an input key, which can be generated from this function or generated externally. Please note that in order to perform deciphering, you must supply the same cipher key that was used for enciphering |
| `simpleEncipher(value,key)` | Enciphers a value supplied using the specified cipher key|
| `simpleDecipher(value,key)` | Deciphers the supplied masked value using the specified cipher key |
| `affineEncipher(value,mult,add)` | Applies an [Affine Cipher](https://en.wikipedia.org/wiki/Affine_cipher) to the specified value using the supplied multiple and additive values |
| `affineDecipher(value,mult,add)` | Deciphers a value created with an Affine Cipher with the specific multiple and additive values |