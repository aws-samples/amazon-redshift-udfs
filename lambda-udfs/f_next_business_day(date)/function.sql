/*
Purpose: Returns the next business day with respect to US Federal Holidays and a M-F work week.

Arguments:
    • `dt` - date to be shifted

2015-09-10: written by chriz@
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_next_business_day(date) RETURNS date STABLE
LAMBDA 'f-next-business-day-date' IAM_ROLE ':RedshiftRole';
