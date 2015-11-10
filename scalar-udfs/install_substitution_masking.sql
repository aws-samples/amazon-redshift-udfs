CREATE LIBRARY pycipher
LANGUAGE plpythonu
from 'https://s3.amazonaws.com/udf-bucket/pycipher.zip';

CREATE LIBRARY substitution_masking
LANGUAGE plpythonu
from 'https://s3.amazonaws.com/udf-bucket/SubstitutionMasking.zip';

create or replace function f_generate_ciphertext_key()
RETURNS VARCHAR
VOLATILE   
AS $$
	import SubstitutionMasking as sm
	return sm.generateCiphertextKey()
$$ LANGUAGE plpythonu;

create or replace function f_simple_encipher(value VARCHAR, key VARCHAR)
RETURNS VARCHAR
STABLE   
AS $$
	import SubstitutionMasking as sm
	return sm.simpleEncipher(value, key)
$$ LANGUAGE plpythonu;

create or replace function f_simple_decipher(value VARCHAR, key VARCHAR)
RETURNS VARCHAR
STABLE   
AS $$
	import SubstitutionMasking as sm
	return sm.simpleDecipher(value, key)
$$ LANGUAGE plpythonu;

create or replace function f_affine_encipher(value VARCHAR, mult INT, add INT)
RETURNS VARCHAR
STABLE   
AS $$
	import SubstitutionMasking as sm
	return sm.affineEncipher(value, key)
$$ LANGUAGE plpythonu;

create or replace function f_affine_decipher(value VARCHAR, mult INT, add INT)
RETURNS VARCHAR
STABLE   
AS $$
	import SubstitutionMasking as sm
	return sm.affineDecipher(value, key)
$$ LANGUAGE plpythonu;