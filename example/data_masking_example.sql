// please ensure that you have installed data masking with ../scalar-udfs/DataMasking/install_data_masking.sql

create table test_substitution_masking (
	id integer not null,
	value_to_mask varchar(25) not null
)
diststyle even;

insert into test_substitution_masking (id, value_to_mask) values (1, 'Value 1');
insert into test_substitution_masking (id, value_to_mask) values (2, 'Value 2');
insert into test_substitution_masking (id, value_to_mask) values (3, 'Value 3');

select f_generate_ciphertext_key() into #my_key;

// simple encipher
select a.id, f_simple_encipher(a.value_to_mask, b.f_generate_ciphertext_key)
from test_substitution_masking a, #my_key b;

// simple encipher, and then decipher the results
select a.id, f_simple_decipher(f_simple_encipher(a.value_to_mask, b.f_generate_ciphertext_key), b.f_generate_ciphertext_key)
from test_substitution_masking a, #my_key b;

// affine enciphering
select a.id, f_affine_encipher(a.value_to_mask, 9, 22)
from test_substitution_masking a;

// affine encipher, then decipher the result
select a.id, f_affine_decipher(f_affine_encipher(a.value_to_mask, 3, 18), 3, 18)
from test_substitution_masking a;