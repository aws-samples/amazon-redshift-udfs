/*
Purpose:
    This UDF takes a string and length of digest value,
    and returns SHA2 hash digest value.

Internal dependencies: hashlib

External dependencies: None

2017-07-11: written by inohiro
*/

CREATE OR REPLACE FUNCTION f_sha2(str VARCHAR(MAX), digest_length integer)
RETURNS VARCHAR(128)
IMMUTABLE
AS $$
    if str is None:
        return None
    else:
        import hashlib
        if digest_length == 224:
            return hashlib.sha224(str).hexdigest()
        elif digest_length == 256:
            return hashlib.sha256(str).hexdigest()
        elif digest_length == 384:
            return hashlib.sha384(str).hexdigest()
        elif digest_length == 512:
            return hashlib.sha512(str).hexdigest()
        else:
            return None
$$ LANGUAGE plpythonu
;

/* Example usages:

udf=# SELECT f_sha2('', 256) ;
                              f_sha2
------------------------------------------------------------------
 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
(1 row)

udf=# SELECT f_sha2('', 512) ;
                                                              f_sha2
----------------------------------------------------------------------------------------------------------------------------------
 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e
(1 row)

*/
