/*
Purpose: Returns the next business day with respect to US Federal Holidays and a M-F work week.
Arguments:
    • `dt` - date to be shifted
test
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
