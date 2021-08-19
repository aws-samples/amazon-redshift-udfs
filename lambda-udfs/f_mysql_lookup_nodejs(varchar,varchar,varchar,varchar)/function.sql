/*
Purpose:
    This sample function demonstrates how to create/use lambda UDFs in nodejs to use external services like mySQL.
    https://aws.amazon.com/blogs/big-data/accessing-external-components-using-amazon-redshift-lambda-udfs/

    Usage: p1 - schema.table
           p2 - join column
           p3 - secretArn containing host, user, password
           p4 - join value

2021-08-01: written by rjvgupta
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_mysql_lookup_nodejs (varchar, varchar, varchar, varchar) RETURNS varchar STABLE
LAMBDA 'f-mysql-lookup-nodejs-varchar-varchar-varchar-varchar' IAM_ROLE ':RedshiftRole';
