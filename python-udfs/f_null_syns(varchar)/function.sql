/* UDF:

Purpose: This function showcases python SET and BOOLEAN support as well as how an argument can be matched against synonyms,
similar to a SQL IN condition.  You might use it as follows:

UPDATE null_tbl SET a = NULL WHERE f_null_syns(a) = TRUE;

2015-09-10: written by chriz@
*/

CREATE OR REPLACE FUNCTION f_null_syns(a VARCHAR)
RETURNS boolean
STABLE
AS $$
    s = {"null", "invalid", "unknown", "n/a", "not applicable", "void", "nothing", "nonexistent", "null and void", ""}
    b = str(a).lower()
    return b in s
$$ LANGUAGE plpythonu;
