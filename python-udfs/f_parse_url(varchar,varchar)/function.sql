/*
Purpose:
    This UDF takes a URL and attribute name as arguments,
    and return the specified attribute of the given URL.
    Attributes definition: https://docs.python.org/2.7/library/urlparse.html#module-urlparse

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
