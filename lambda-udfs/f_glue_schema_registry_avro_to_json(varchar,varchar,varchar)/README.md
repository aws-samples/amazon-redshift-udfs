# f_glue_schema_registry_avro_to_json(varchar,varchar,varchar)

This sample function demonstrates how to create/use lambda UDFs in Python to convert Avro encoded data into JSON for use in Redshift SUPER data type using the Glue Schema Registry (refer to [Non-JSON ingestion using Amazon Kinesis Data Streams, Amazon MSK, and Amazon Redshift Streaming Ingestion](https://aws.amazon.com/blogs/big-data/non-json-ingestion-using-amazon-kinesis-data-streams-amazon-msk-and-amazon-redshift-streaming-ingestion/).

![Example Architecture](https://github.com/aws-samples/amazon-redshift-udfs/blob/master/lambda-udfs/f_glue_schema_registry_avro_to_json(varchar%2Cvarchar%2Cvarchar)/example.png)

## Arguments: 
1.  `registry_name`: The Glue Schema Registry name for the schema
2.  `schema_name`: The schema name for the data to retrieve from the registry
3.  `data`: The Hex-encoded Avro binary data

## Returns:
The data encoded as JSON

## Example usage:
This example demonstrates creating a materialized view with SUPER data converted from Avro that's 
published to a Kinesis stream. This uses the "Assumed schema" approach, as described in the
[blog post](https://aws.amazon.com/blogs/big-data/non-json-ingestion-using-amazon-kinesis-data-streams-amazon-msk-and-amazon-redshift-streaming-ingestion/):

```
-- Step 1 
CREATE EXTERNAL SCHEMA kds FROM KINESIS 

-- Step 2 
CREATE MATERIALIZED VIEW {name} AUTO REFRESH YES AS 
    SELECT 
    -- Step 3 
    t.kinesis_data AS binary_avro, 
    to_hex(binary_avro) AS hex_avro,
    -- Step 5 
    f_glue_schema_registry_avro_to_json('{registry-name}', '{stream-name}', hex_avro) AS json_string, 
    -- Step 6 JSON_PARSE(json_string) AS super_data, 
    t.sequence_number,
    t.refresh_time, 
    t.approximate_arrival_timestamp, 
    t.shard_id 
FROM kds.{stream_name} AS t
```
