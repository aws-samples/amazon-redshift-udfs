/*
Purpose:
    This sample function demonstrates how to create/use lambda UDFs in java

2021-08-01: written by rjvgupta
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_upper_java(varchar) RETURNS varchar IMMUTABLE
LAMBDA 'f-upper-java-varchar' IAM_ROLE ':RedshiftRole';
