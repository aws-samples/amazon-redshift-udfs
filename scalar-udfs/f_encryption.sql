/* f_encryption.sql

Purpose: f_encrypt_str encrypts a 256 character string with AES256 encryption using a 32 character key.
f_decrypt_str decrypts this encrypted string and returns the original plaintext.  

Internal dependencies: base64

External dependencies: pyaes (https://github.com/ricmoo/pyaes)

2015-09-10: created by chriz@  
*/

CREATE LIBRARY pyaes
LANGUAGE plpythonu 
FROM 'https://s3.amazonaws.com/udf-bucket/pyaes.zip';

CREATE OR REPLACE FUNCTION f_encrypt_str(a VARCHAR(256), key CHAR(32))
RETURNS varchar(max)
STABLE
AS $$
    import pyaes
    import base64
    aes = pyaes.AESModeOfOperationCTR(key)
    e = base64.b64encode(aes.encrypt(a))
    return e
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION f_decrypt_str(a VARCHAR(MAX),key CHAR(32))
RETURNS varchar(max)
STABLE
AS $$
    import base64
    import pyaes
    aes = pyaes.AESModeOfOperationCTR(key)
    c = base64.b64decode(a)
    d = aes.decrypt(c)
    return d
$$ LANGUAGE plpythonu;

/* Example usage:

udf=# CREATE TABLE base (c_comment VARCHAR);
CREATE TABLE

udf=# INSERT INTO base VALUES
udf-# ('deposits eat slyly ironic, even instructions. express foxes detect slyly. blithely even accounts abov'),
udf-# ('ainst the ironic, express theodolites. express, even pinto beans among the exp'),
udf-# ('ckages. requests sleep slyly. quickly even pinto beans promise above the slyly regular pinto beans.'),
udf-# ('platelets. regular deposits detect asymptotes. blithely unusual packages nag slyly at the fluf'),
udf-# ('nag. furiously careful packages are slyly at the accounts. furiously regular in');
INSERT 0 5

udf=# CREATE TABLE encrypted AS SELECT c_comment, f_encrypt_str(c_comment,'PassphrasePassphrasePassphrase32') AS c_comment_encrypted FROM base;
SELECT

udf=# CREATE TABLE decrypted AS SELECT c_comment, f_decrypt_str(c_comment_encrypted,'PassphrasePassphrasePassphrase32') AS c_comment_decrypted FROM encrypted;
SELECT

udf=# SELECT * FROM decrypted;
                                               c_comment                                               |                                          c_comment_decrypted
-------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------
 platelets. regular deposits detect asymptotes. blithely unusual packages nag slyly at the fluf        | platelets. regular deposits detect asymptotes. blithely unusual packages nag slyly at the fluf
 deposits eat slyly ironic, even instructions. express foxes detect slyly. blithely even accounts abov | deposits eat slyly ironic, even instructions. express foxes detect slyly. blithely even accounts abov
 nag. furiously careful packages are slyly at the accounts. furiously regular in                       | nag. furiously careful packages are slyly at the accounts. furiously regular in
 ckages. requests sleep slyly. quickly even pinto beans promise above the slyly regular pinto beans.   | ckages. requests sleep slyly. quickly even pinto beans promise above the slyly regular pinto beans.
 ainst the ironic, express theodolites. express, even pinto beans among the exp                        | ainst the ironic, express theodolites. express, even pinto beans among the exp
(5 rows)


udf=# CREATE TABLE decryption_failure AS SELECT c_comment, f_decrypt_str(c_comment_encrypted,'PassphrasePassphrasePassphrase12') AS c_comment_decrypted FROM encrypted;
SELECT

udf=# SELECT * FROM decryption_failure ;
                                               c_comment                                               |                                          c_comment_decrypted
-------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------
 platelets. regular deposits detect asymptotes. blithely unusual packages nag slyly at the fluf        | YJ\x0EA|Ɯ^$J\x057^\x06D\x0Bڊ(~\x0C\x08^ =]k?^$҃:\x1D\x0BX7x\rv\x02I/VD\x12OX`\x16\x16љ
 deposits eat slyly ironic, even instructions. express foxes detect slyly. blithely even accounts abov | MC\x1FZڛ9ӑU$G\x04-T^\x17NȊߊ2-\r\x06^\x1F`Ap.Э\x11)مi\x0C\x0F\x1B:r\x03uKM3VD\x12KZ%^\x12ёPd?P\x07\x02
 nag. furiously careful packages are slyly at the accounts. furiously regular in                       | GG\x08\x1BΜuɜ^aHJ4V\x11\Jي\u008A.;\x0C\x1C\x11\x18n\x11c(
                                                                                                       : "/\x1D\x18WvlXv\x02K
 ckages. requests sleep slyly. quickly even pinto beans promise above the slyly regular pinto beans.   | JM\x0ERʚ|_hKJ7[\x0B[R?5\x06
 ainst the ironic, express theodolites. express, even pinto beans among the exp                        | HO\x01F䂉ҝv\x0CaV\x0F7DRCCۀ5*\x0CEA     =Tt.\x10%+\r\x0BܠV8\x7FE7Z
(5 rows)

*/
