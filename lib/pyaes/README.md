pyaes 
=====

Forked from https://github.com/ricmoo/pyaes

A pure-Python implmentation of the AES block cipher algorithm and the common modes of operation (CBC, CFB, CTR, ECB and OFB).

### Common Modes of Operation

There are many modes of operations, each with various pros and cons. In general though, the **CBC** and **CTR** modes are recommended. The **ECB is NOT recommended.**, and is included primarilty for completeness.

Each of the following examples assumes the following key:
```python
import pyaes

# A 256 bit (32 byte) key
key = "This_key_for_demo_purposes_only!"

# For some modes of operation we need a random initialization vector
# of 16 bytes
iv = "InitializationVe"
```


#### Counter Mode of Operation (recommended)

```python
aes = pyaes.AESModeOfOperationCTR(key)
plaintext = "Text may be any length you wish, no padding is required"
ciphertext = aes.encrypt(plaintext)

# '''\xb6\x99\x10=\xa4\x96\x88\xd1\x89\x1co\xe6\x1d\xef;\x11\x03\xe3\xee
#    \xa9V?wY\xbfe\xcdO\xe3\xdf\x9dV\x19\xe5\x8dk\x9fh\xb87>\xdb\xa3\xd6
#    \x86\xf4\xbd\xb0\x97\xf1\t\x02\xe9 \xed'''
print repr(ciphertext)

# The counter mode of operation maintains state, so decryption requires
# a new instance be created
aes = pyaes.AESModeOfOperationCTR(key)
decrypted = aes.decrypt(ciphertext)

# True
print decrypted == plaintext

# To use a custom initial value
counter = pyaes.Counter(initial_value = 100)
aes = pyaes.AESModeOfOperationCTR(key, counter = counter)
ciphertext = aes.encrypt(plaintext)

# '''WZ\x844\x02\xbfoY\x1f\x12\xa6\xce\x03\x82Ei)\xf6\x97mX\x86\xe3\x9d
#    _1\xdd\xbd\x87\xb5\xccEM_4\x01$\xa6\x81\x0b\xd5\x04\xd7Al\x07\xe5
#    \xb2\x0e\\\x0f\x00\x13,\x07'''
print repr(ciphertext)
```
