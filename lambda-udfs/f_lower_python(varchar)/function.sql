/*
Purpose:
    This sample function demonstrates how to create/use lambda UDFs in python
2021-08-01: written by rjvgupta
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_lower_python(varchar) RETURNS varchar IMMUTABLE
LAMBDA 'f-lower-python-varchar' IAM_ROLE ':RedshiftRole';
