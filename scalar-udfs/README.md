# Redshift Scalar UDF Examples
Scalar UDF examples are intended to showcase various functionality of UDFs.
If you are using psql, you can use \i &lt;script.sql&gt; to run.

| Script | Purpose |
| ------------- | ------------- |
| f_encryption.sql | Uses pyaes library to encrypt/decrypt strings using passphrase |
| f_next_business_day.sql | Uses pandas library to return dates which are US Federal Holiday aware |
| f_null_syns.sql | Uses python sets to match strings, similar to a SQL IN condition |
| f_parse_url_query_string.sql | Uses urlparse to parse the field-value pairs from a url query string |
| f_parse_xml.sql | Uses xml.etree.ElementTree to parse XML |
| f_unixts_to_timestamp.sql | Uses pandas library to convert a unix timestamp to UTC datetime |
