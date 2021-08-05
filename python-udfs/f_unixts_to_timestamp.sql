/* Purpose: Converts a UNIX timestamp to a UTC datetime with up to microseconds granularity. 

Internal dependencies: pandas

External dependencies: None

2015-09-10: written by chriz@
*/

CREATE OR REPLACE FUNCTION f_unixts_to_timestamp(ts BIGINT, units CHAR(2))
RETURNS timestamp
STABLE
AS $$
    import pandas
    return pandas.to_datetime(ts, unit=units.rstrip())
$$ LANGUAGE plpythonu;

/* Example usage:

udf=# SELECT f_unixts_to_timestamp(1349720105,'s');
 f_unixts_to_timestamp 
-----------------------
 2012-10-08 18:15:05
(1 row)

udf=# SELECT f_unixts_to_timestamp(1349720105123,'ms');
  f_unixts_to_timestamp  
-------------------------
 2012-10-08 18:15:05.123
(1 row)

udf=# SELECT f_unixts_to_timestamp(1349720105123123,'us');
   f_unixts_to_timestamp    
----------------------------
 2012-10-08 18:15:05.123123
(1 row)

*/

