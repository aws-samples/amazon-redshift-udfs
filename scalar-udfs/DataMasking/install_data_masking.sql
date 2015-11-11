CREATE LIBRARY pycipher
LANGUAGE plpythonu
from 'https://s3.amazonaws.com/udf-bucket/pycipher.zip';

create or replace function f_generate_ciphertext_key()
RETURNS VARCHAR
VOLATILE   
AS $$
    import random
    import string
    
    # alphabet as charlist 
    l = list(string.ascii_lowercase)
    
    # shuffle charlist
    random.shuffle(l)
    
    # return new string from shuffled charlist
    return ''.join(l)
$$ LANGUAGE plpythonu;

create or replace function f_simple_encipher(value VARCHAR, key VARCHAR)
RETURNS VARCHAR
STABLE   
AS $$
    from pycipher import SimpleSubstitution
    
    ss = SimpleSubstitution(key)
    return ss.encipher(str(value), True)[::-1]
$$ LANGUAGE plpythonu;

create or replace function f_simple_decipher(value VARCHAR, key VARCHAR)
RETURNS VARCHAR
STABLE   
AS $$
    from pycipher import SimpleSubstitution
    
    ss = SimpleSubstitution(key)
    return ss.decipher(str(value)[::-1], True)
$$ LANGUAGE plpythonu;

create or replace function f_affine_encipher(value VARCHAR, mult INT, add INT)
RETURNS VARCHAR
STABLE   
AS $$
    from pycipher import Affine
    
    af = Affine(mult, add)
    return af.encipher(str(value), True)[::-1]
$$ LANGUAGE plpythonu;

create or replace function f_affine_decipher(value VARCHAR, mult INT, add INT)
RETURNS VARCHAR
STABLE   
AS $$
    from pycipher import Affine
    
    af = Affine(mult, add)
    return af.decipher(str(value)[::-1], True)
$$ LANGUAGE plpythonu;
