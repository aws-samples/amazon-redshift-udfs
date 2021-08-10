/* Purpose: Converts a UNIX timestamp to a UTC datetime with up to microseconds granularity.
 
2015-09-10: written by chriz@
*/

CREATE OR REPLACE FUNCTION f_unixts_to_timestamp(ts BIGINT, units CHAR(2))
RETURNS timestamp
STABLE
AS $$
    import pandas
    return pandas.to_datetime(ts, unit=units.rstrip())
$$ LANGUAGE plpythonu;
