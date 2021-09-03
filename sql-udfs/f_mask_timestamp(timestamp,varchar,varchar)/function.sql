/*
Purpose:
    This sample function demonstrates how to use a UDF for dynamic masking.  This function can be particular
    useful when used in a security view and the parameter for the "priv" are dynamically populate via a control table.
    See the following for more details:
    https://github.com/aws-samples/amazon-redshift-dynamic-data-masking

    inputs:
      src - the table column which needs to be masked/unmasked
      class - the classification of data, i.e. different class values may have different masking partial or full masking rules.
      priv - the level of privilage allowed for this user.  e.g. if
        not supplied/null, function should return null
        if 'N' - no masking, will return source value
        if 'F' - the data should be fully masked
        if 'P' - the data should be partially masked

    note:
      this function is volitile and will fail on the test for full masking because it uses a RANDOM function, this is by design.

2021-09-03: written by rjvgupta
*/
create or replace function f_mask_timestamp (timestamp, varchar, varchar)
  returns timestamp
volatile
as $$
  select case
    when $3 = 'N' then $1
    when $3 = 'F' then dateadd(day, (random() * 100)::int-50, '1/1/2021'::date)
    when $3 = 'P' then case $2
      when 'dob' then date_trunc('year',$1)
      else dateadd(year, -1*date_part('year', $1)::int+1900,$1) end
    else null
    end
$$ language sql;
