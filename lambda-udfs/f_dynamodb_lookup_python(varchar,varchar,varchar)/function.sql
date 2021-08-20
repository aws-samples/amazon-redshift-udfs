/*
Purpose:
    This sample function demonstrates how to create/use lambda UDFs in python to use external services like dynamoDB.
    https://aws.amazon.com/blogs/big-data/accessing-external-components-using-amazon-redshift-lambda-udfs/

2021-08-01: written by rjvgupta
*/ 
CREATE OR REPLACE EXTERNAL FUNCTION f_dynamodb_lookup_python (varchar, varchar, varchar) RETURNS varchar STABLE
LAMBDA 'f-dynamodb-lookup-python-varchar-varchar-varchar' IAM_ROLE ':RedshiftRole';
