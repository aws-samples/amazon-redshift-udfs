/*
Purpose:
    This sample function demonstrates how to convert DynamoDB marshalled data in a Kinesis stream
    from DynamoDB streams into unmarshalled (normal JSON) format for usage in Redshift materialized views.
    TODO: Blog link when published

2022-08-30: written by mmehrten
*/ 
CREATE OR REPLACE EXTERNAL FUNCTION f_unmarshall_dynamodb_stream_data(VARCHAR(MAX)) RETURNS VARCHAR(MAX) IMMUTABLE
LAMBDA 'f-unmarshall-dynamodb-stream-data-varchar' IAM_ROLE ':RedshiftRole';
