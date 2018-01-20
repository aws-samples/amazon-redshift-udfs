/* UDF: f_null_syns.sql

Purpose: This function showcases python SET and BOOLEAN support as well as how an argument can be matched against synonyms,
similar to a SQL IN condition.

Internal dependencies: jellyfish

External dependencies: None

2018-01-14: written by chriz@
*/

CREATE OR REPLACE FUNCTION f_string_distance(a VARCHAR, b VARCHAR, distance_func VARCHAR)
RETURNS float
STABLE
AS $$
    a,b = unicode(a),unicode(b)
    import jellyfish
    if distance_func == 'levenshtein' or distance_func is None:
        return jellyfish.levenshtein_distance(a, b)
    elif distance_func == 'jaro':
        return jellyfish.jaro_distance(a, b)
    elif distance_func == 'hamming':
        return jellyfish.hamming_distance(a, b)
    elif distance_func == 'jaro_winkler':
        return jellyfish.jaro_winkler(a, b)
    elif distance_func == 'damerau_levenshtein':
        return jellyfish.damerau_levenshtein_distance(a, b)
$$ LANGUAGE plpythonu;

CREATE OR REPLACE FUNCTION f_string_distance(a VARCHAR, b VARCHAR)
RETURNS float
STABLE
AS $$
    a,b = unicode(a),unicode(b)
    import jellyfish
    return jellyfish.levenshtein_distance(a, b)
$$ LANGUAGE plpythonu;

/* Example usage:


--select f_string_distance('enciclopedia', 'enciclopedai','jaro');
--select f_string_distance('enciclopedia', 'enciclopedai','jaro_winkler');
--select f_string_distance('enciclopedia', 'enciclopedai','hamming');
--select f_string_distance('enciclopedia', 'enciclopedai','levenshtein');
--select f_string_distance('enciclopedia', 'enciclopedai');
