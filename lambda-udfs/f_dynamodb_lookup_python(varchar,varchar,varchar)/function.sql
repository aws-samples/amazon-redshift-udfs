/*
Purpose:
    This sample function demonstrates how to create/use lambda UDFs in python to use external services like dynamoDB.

2021-08-01: written by rjvgupta
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_dynamodb_lookup_python (varchar, varchar, varchar) RETURNS varchar STABLE
LAMBDA 'f-dynamodb-lookup-python' IAM_ROLE ':RedshiftRole';
