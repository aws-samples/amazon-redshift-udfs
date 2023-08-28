/*
Purpose:
    This sample function demonstrates how to create/use lambda UDFs in python to convert Avro encoded data into JSON for use in
    Redshift SUPER data type using the Glue Schema Registry.
    TODO: Link to blog

2023-08-25: written by mmehrten
*/ 
CREATE OR REPLACE EXTERNAL FUNCTION f_glue_schema_registry_avro_to_json (varchar, varchar, varchar) 
RETURNS varchar 
IMMUTABLE
LAMBDA 'f-glue-schema-registry-avro-to-json-varchar-varchar-varchar' 
IAM_ROLE ':RedshiftRole';
