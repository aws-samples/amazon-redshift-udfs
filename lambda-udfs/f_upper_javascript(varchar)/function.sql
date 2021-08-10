/*
Purpose:
    This sample function demonstrates how to create/use lambda UDFs in python

Internal dependencies: None
External dependencies: None

2021-08-01: written by rjvgupta
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_upper_javascript(varchar) RETURNS varchar IMMUTABLE
LAMBDA 'f-upper-javascript-varchar' IAM_ROLE ':iamRole';
