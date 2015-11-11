/* install_data_masking.sql

Purpose: Installs a series of user defined functions which perform encipher and
decipher operations using Pycipher.

Please note that data masking IS NOT ENCRYPTION and should be used with caution

Internal dependencies: random, string

External dependencies: pycipher (https://pypi.python.org/pypi/pycipher and http://pycipher.readthedocs.org/en/latest) 

2015-11-11: created by meyersi@  
*/
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
