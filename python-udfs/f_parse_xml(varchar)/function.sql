/* UDF:

Purpose: This function showcases how parsing XML is possible with UDFs.

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
