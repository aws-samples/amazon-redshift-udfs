/* UDF: f_next_business_day.sql

Purpose: Returns the next business day with respect to US Federal Holidays and a M-F work week.

Internal dependencies: pandas

External dependencies: None

2015-09-10: written by chriz@
*/

CREATE OR REPLACE FUNCTION f_next_business_day(dt DATE)
RETURNS date
STABLE
AS $$
    import pandas
    from pandas.tseries.offsets import CustomBusinessDay
    from pandas.tseries.holiday import USFederalHolidayCalendar

    bday_us = CustomBusinessDay(calendar=USFederalHolidayCalendar())
    return dt + bday_us
$$ LANGUAGE plpythonu;

/* Example usage:

udf=# SELECT f_next_business_day('2015-09-04');
 f_next_business_day 
---------------------
 2015-09-08
(1 row)

udf=# SELECT f_next_business_day('2015-09-05');
 f_next_business_day 
---------------------
 2015-09-08
(1 row)

udf=# SELECT f_next_business_day('2015-09-08');
 f_next_business_day 
---------------------
 2015-09-09
(1 row)

*/
