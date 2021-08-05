/*
Purpose:
    This UDF takes a URL and attribute name as arguments,
    and return the specified attribute of the given URL.
    Attributes definition: https://docs.python.org/2.7/library/urlparse.html#module-urlparse

Internal dependencies: urlparse

External dependencies: None

2016-12-29: written by inohiro
*/

CREATE OR REPLACE FUNCTION f_parse_url(url VARCHAR(MAX), part VARCHAR(20))
RETURNS VARCHAR(MAX)
IMMUTABLE
AS $$
    if url is None:
        return None
    else:
        import urlparse
        parsed = urlparse.urlparse(url)
        return getattr(parsed, part)
$$ LANGUAGE plpythonu
;

/* Example usages:

udf=# SELECT f_parse_url('https://example.com/issues/23?hello=world', 'scheme') ;
 f_parse_url
-------------
 https
(1 row)

udf=# SELECT f_parse_url('https://example.com/issues/23?hello=world', 'hostname') ;
 f_parse_url
-------------
 example.com
(1 row)

udf=# SELECT f_parse_url('https://example.com/issues/23?hello=world', 'path') ;
 f_parse_url
-------------
 /issues/23
(1 row)

udf=# SELECT f_parse_url('https://example.com/issues/23?hello=world', 'query') ;
 f_parse_url
-------------
 hello=world
(1 row)

*/
