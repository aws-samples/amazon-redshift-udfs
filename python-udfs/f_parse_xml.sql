/* UDF: f_parse_xml.sql

Purpose: This function showcases how parsing XML is possible with UDFs.

Internal dependencies: xml.etree.ElementTree

External dependencies: None

2015-09-10: written by chriz@
*/

CREATE OR REPLACE FUNCTION f_parse_xml(xml VARCHAR(MAX))
RETURNS varchar(max)
STABLE
AS $$
    import xml.etree.ElementTree as ET
    root = ET.fromstring(xml)
    for country in root.findall('country'):
        rank = country.find('rank').text
        name = country.get('name')
        return name + ':' + rank
$$ LANGUAGE plpythonu;

/* Example usage:

udf=# CREATE TABLE xml_log (id INT, xml VARCHAR(MAX));
CREATE TABLE

udf=# INSERT INTO xml_log VALUES (1,'<data>
udf'#     <country name="Liechtenstein">
udf'#         <rank>1</rank>
udf'#         <year>2008</year>
udf'#         <gdppc>141100</gdppc>
udf'#         <neighbor name="Austria" direction="E"/>
udf'#         <neighbor name="Switzerland" direction="W"/>
udf'#     </country></data>');
INSERT 0 1

udf=# SELECT f_parse_xml(xml) FROM xml_log;
   f_parse_xml   
-----------------
 Liechtenstein:1
(1 row)

*/
