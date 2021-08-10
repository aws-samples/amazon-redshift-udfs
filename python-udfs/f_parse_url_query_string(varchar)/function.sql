/* Purpose: This UDF takes a URL as an argument, and parses out the field-value pairs.
Returns pairs in JSON for further parsing if needed.
 
2015-09-10: written by chriz@
*/

CREATE OR REPLACE FUNCTION f_parse_url_query_string(url VARCHAR(MAX))
RETURNS varchar(max)
STABLE
AS $$
    from urlparse import urlparse, parse_qsl
    import json
    return json.dumps(dict(parse_qsl(urlparse(url)[4])))
$$ LANGUAGE plpythonu;
