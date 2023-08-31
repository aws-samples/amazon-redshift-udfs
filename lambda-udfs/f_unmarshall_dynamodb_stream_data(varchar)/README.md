# f_unmarshall_dynamodb_stream_data(varchar)

This sample function demonstrates how to convert DynamoDB marshalled data in a Kinesis stream
from DynamoDB streams into unmarshalled (normal JSON) format for usage in Redshift materialized views.
Blog link TODO.

![Example Architecture](https://github.com/aws-samples/amazon-redshift-udfs/blob/master/lambda-udfs/f_unmarshall_dynamodb_stream_data(varchar)/example.png)

## Arguments: 
1.  `payload`: The data from DynamoDB streams

## Returns:
The same payload, with DynamoDB data encoded as normal unmarshalled JSON

## Example usage:
This example demonstrates creating a materialized view with SUPER data where data is in normal JSON
unmarshalled format from DynamoDB streams. [blog post](link_todo):

```
-- Step 1 
CREATE EXTERNAL SCHEMA kds FROM KINESIS 

-- Step 2 
CREATE MATERIALIZED VIEW {name} AUTO REFRESH YES AS 
SELECT 
    t.kinesis_data AS binary_avro, 
    t.sequence_number,
    t.refresh_time, 
    t.approximate_arrival_timestamp, 
    t.shard_id,
    f_unmarshall_dynamodb_stream_data(payload) AS json_string, 
    JSON_PARSE(json_string) AS super_data,
    super_data."awsRegion" AS region,
    super_data."eventID" AS event_id,
    super_data."eventName" AS event_name,
    super_data."tableName" AS table_name,
    super_data."dynamodb"."ApproximateCreationDateTime" AS approximate_creation_date_time,
    super_data."dynamodb"."Keys" AS keys,
    super_data."dynamodb"."NewImage" AS new_image,
    super_data."dynamodb"."OldImage" AS old_image,
    super_data."dynamodb"."SizeBytes" AS size_bytes,
    super_data."eventSource" AS event_source
FROM kds.{stream_name} AS t
```