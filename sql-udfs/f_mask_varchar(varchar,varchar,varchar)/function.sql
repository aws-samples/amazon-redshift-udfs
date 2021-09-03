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

2021-09-03: written by rjvgupta
*/
create or replace function f_mask_varchar (varchar, varchar, varchar)
  returns varchar
immutable
as $$
  select case
    when $3 = 'N' then $1
    when $3 = 'F' then md5($1)
    when $3 = 'P' then case $2
      when 'ssn' then substring($1, 1, 7)||'xxxx'
      when 'email' then substring(SPLIT_PART($1, '@', 1), 1, 3) + 'xxxx@' + SPLIT_PART($1, '@', 2)
      else substring($1, 1, 3)||'xxxxx' end
    else null
    end
$$ language sql;
