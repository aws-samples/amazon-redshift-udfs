-- Create schema, table, and insert few records
CREATE SCHEMA test_user_management;
create table test_user_management.sales(
sales_id integer,
seller_id integer,
buyer_id integer ,
qty_sold smallint ,
price_paid decimal(8,2));

INSERT INTO test_user_management.sales(sales_id ,seller_id ,buyer_id  ,qty_sold  ,price_paid)
    VALUES (11,11,111,30,13.31),
            (12,11,111,33,13.31),
            (13,10,100,1,1.01),
            (14,10,100,2,11.11)

SELECT *
FROM test_user_management.sales;

-- Create users and groups
create user user1 password 'testAccess8';
create user user2 password 'testAccess8';
create group group1 with user user2;

REVOKE USAGE ON SCHEMA test_user_management FROM public;
REVOKE SELECT ON dms_sample_dbo.mlb_data from PUBLIC;

/*--- Test 1: GRANT access to user ---*/
-- Load user_access_details1.csv into S3 bucket and execute SP (as superuser)
-- Expected result: user1 should be able to query the table
SET SESSION AUTHORIZATION 'user1';
SELECT *
FROM test_user_management.sales;

-- Query should fail for user2 
SET SESSION AUTHORIZATION 'user2';
SELECT *
FROM test_user_management.sales;


/*--- Test 2: REVOKE access from user1 & GRANT access to group1 ---*/
-- Load user_access_details2.csv into S3 bucket, delete user_access_details1.csv and execute SP (as superuser)
-- Expected result: user1 should NOT be able to query the table now, since his access is revoked. user2 should be able to query the table, since he is part of the group

SET SESSION AUTHORIZATION 'user1';
SELECT *
FROM test_user_management.sales;

-- Query should fail for user2 
SET SESSION AUTHORIZATION 'user2';
SELECT *
FROM test_user_management.sales;


/*--- Test 3: GRANT column-level access to user1 & GRANT execute function permission to user1 ---*/
-- First create the function
SET SESSION AUTHORIZATION '[superuser]';
CREATE function f_sql_greater (float, float)
  returns float
stable
as $$
  select case when $1 > $2 then $1
    else $2
  end
$$ language sql;

REVOKE EXECUTE ON FUNCTION f_sql_greater (float, float) FROM PUBLIC;

-- Load user_access_details3.csv into S3 bucket, delete user_access_details2.csv and execute SP (as superuser)
-- Expected result: user1 should be able to only query the columns he's got access to. He should be able execute SQL function too

SET SESSION AUTHORIZATION 'user1';
SELECT buyer_id, price_paid
FROM test_user_management.sales;


SELECT f_sql_greater (10,20);

/*--- Test 4: REVOKE execute function permission from user1 & GRANT execute function permission to group1. Note that the same mechanism works for stored procedures as well. ---*/
-- Load user_access_details4.csv into S3 bucket, delete user_access_details3.csv and execute SP (as superuser)
-- Expected result: user1 should NOT be able to execute function. user2 should be able to execute function, sinc ehe is member of group1

SET SESSION AUTHORIZATION 'user1';
SELECT f_sql_greater (10,20);

SET SESSION AUTHORIZATION 'user2';
SELECT f_sql_greater (10,20);

/*--- Test 5: GRANT access to all tables in schema & grant access with RBAC ---*/
-- First creatae role
SET SESSION AUTHORIZATION '[superuser]';
CREATE ROLE role1;
GRANT ROLE role1 to user1;

-- Load user_access_details5.csv into S3 bucket, delete user_access_details4.csv and execute SP (as superuser)
-- Expected result: user1 should be able to query the table and see all columns, since he is assigned role1. user2 should be able to query the table as well, since the group he is a member of is given access to all tables in the schema
SET SESSION AUTHORIZATION 'user1';
SELECT *
FROM test_user_management.sales;

SET SESSION AUTHORIZATION 'user2';
SELECT *
FROM test_user_management.sales;


/*--- Test 6: RLS ---*/
-- First alter table and add a new column
SET SESSION AUTHORIZATION '[superuser]';
alter table test_user_management.sales
add column seller_name varchar(50)
default 'user2';

UPDATE test_user_management.sales
SET seller_name = 'user1'
WHERE seller_id = 10

SELECT *
FROM test_user_management.sales;

-- Then create RLS policy and attach it to the table
SET SESSION AUTHORIZATION '[superuser]';
CREATE RLS POLICY only_self_sales WITH ( seller_name varchar(50) ) USING (seller_name = current_user);
ALTER TABLE test_user_management.sales row level security ON;

-- Load user_access_details6.csv into S3 bucket, delete user_access_details5.csv and execute SP (as superuser)
-- Expected result: user1 should only see the 2 records related to his sales when querying the table

SET SESSION AUTHORIZATION 'user1';
SELECT *
FROM test_user_management.sales;

