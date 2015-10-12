/* Purpose: This UDF takes a URL as an argument, and parses out the field-value pairs.
Returns pairs in JSON for further parsing if needed.

Internal dependencies: urlparse, json

External dependencies: None

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

/* Example usage:

udf=# CREATE TABLE url_log (id INT, url VARCHAR(MAX));
CREATE TABLE

udf=# INSERT INTO url_log VALUES (1,'http://example.com/over/there?name=ferret'),
udf-#     (2,'http://example.com/Sales/DeptData/Elites.aspx?Status=Elite'),
udf-#     (3,'http://example.com/home?status=Currently'),
udf-#     (4,'https://example.com/ops/search?utf8=%E2%9C%93&query=redshift');
INSERT 0 4

udf=# SELECT id, TRIM(url) AS url, f_parse_url_query_string(url) FROM url_log;
 id |                             url                              |        f_parse_url_query_string         
----+--------------------------------------------------------------+-----------------------------------------
  1 | http://example.com/over/there?name=ferret                    | {"name": "ferret"}
  2 | http://example.com/Sales/DeptData/Elites.aspx?Status=Elite   | {"Status": "Elite"}
  3 | http://example.com/home?status=Currently                     | {"status": "Currently"}
  4 | https://example.com/ops/search?utf8=%E2%9C%93&query=redshift | {"utf8": "\u2713", "query": "redshift"}
(4 rows)

udf=# SELECT id, TRIM(url) AS url FROM url_log WHERE json_extract_path_text(f_parse_url_query_string(url),'query') = 'redshift';
 id |                             url                              
----+--------------------------------------------------------------
  4 | https://example.com/ops/search?utf8=%E2%9C%93&query=redshift
(1 row)

*/
