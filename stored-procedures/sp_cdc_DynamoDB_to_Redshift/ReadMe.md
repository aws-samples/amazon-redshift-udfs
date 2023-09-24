# CDC changes from DynamoDB table to Redshift table:

## Introduction

The solution enables change data capture (CDC) replication between DynamoDB and Redshift.
This process makes it easier to replicate multiple tables without the need for coding replication for each table.
Schema changes are detected and handled in the Redshift process to keep it in sync with DynamoDB.
Also provides the ability to control multiple table CDC work load by scheduling for better cluster resource management.

At high level the steps are 

- Create a Kinesis data stream (KDS) and turn on the data stream to KDS for tables to be replicated from DynamoDB. 
- Create a materialized view in your Amazon Redshift cluster to consume streaming data from the Kinesis Data Stream.
- The streaming data gets ingested as a JSON payload. This JSON data is processed into Redshift tables via a Stored Procedure. 

DynamoDB can stream multiple tables into a single stream. So, there will be one stream processed by Redshift to apply changes.
On Redshift there is no need to write custom parsing procedures for each table.


### Pre-Requisites
- Create Kinesis Data Stream. (Example name: *redshift\_cdc*) 
- Create a Dynamo DB table(s) and enable data streaming to Kinesis Data Stream created. 
- Create an IAM role with ability to read KDS streams and attach it to Redshift cluster. (Example name: *my_streaming_role*)



  
### Setup
- Create Redshift process. 
  - Create Stored Procedure on Redshift Cluster either in QEv2 or via any SQL tool. Create procedures as per the sp\_cdc\_DynamoDB\_to\_Redshift.sql file. 
  - Verify below procedures are created
    - sp\_create\_table\_varchar\_max(varchar). Routine to create table if it does not exist.
    - sp\_cursor\_loop\_alter\_tables(). Routine to alter table if schema changes are detected.
    - sp\_cursor\_loop\_create\_tables(). Routine to create table when multiple new tables are in CDC.
    - sp\_cursor\_loop\_process\_merge\_tables(). Routine to merge data to target Redshift table.
    - sp\_ddb\_to\_redshift\_incremental\_refresh\_cdc(). Main routine to execute on demand or schedule.
    - sp\_ddb\_to\_redshift\_setup\_process\_tables(). Setup routine to create tables needed for ongoing replication process.
    - sp\_ddb\_to\_redshift\_setup\_schema\_mv(varchar,varchar,varchar). Setup routine to create materialized view and schema.
    - sp\_delete\_table\_key\_data(). Routine to handle deleted records.
    - sp\_merge\_table\_key\_data(). Routine to handle updates.
  - Execute procedure below to create materialized view and schema replacing with IAM role, Account\_Number and KDS name. one time process.
    - call public.sp\_ddb\_to\_redshift\_setup\_schema\_mv(*'my\_streaming\_role','123456781234','redshift\_cdc')*;
    - This will create necessary schema and materialized view to capture data from DynamoDB.
  - Execute procedure below to create tables needed for replication process.
    - call public.sp\_ddb\_to\_redshift\_setup\_process\_tables(). Verify list of tables in the procedure is created by refreshing schema.
    - Please see below table name and how it is used in the process.  
       1. public.metadata_etl.	This table is used to control the current batch that is running with start time and end time.
       2. public.dynamodb_kds_mv_staging.	Ingesting Materialized View data into staging table in the right format and audit fields.
       3. public.dynamodb_kds_mv_staging_batch. 	Select data to be processed based on last execution. Filters the new data from data already processed. 
       4. public.dynamodb_kds_staging_cdc.  Select data to be processed based on last execution. Filters the new data from data already processed. 
       5. public.dynamodb_kds_staging_cdc_unique.	Removes duplicates if there are multiple records for same unique key by selecting most recent record.
       6. public.metadata_dd_table_columns.	Stores table name, column name and data types.
       7. public.metadata_dd_table_keys.	Stores table name, column name and if a column is a key or not.
       8. public.metadata_dd_table_columns_hist.	Stores list of distinct columns for each table to compare with new data.
       9. public.temp_table_pivot_data.	Temporary table to unnest and format data to prepare for DML operations.
       
    
### Ongoing process
- Procedure to replicate data -   Execute below procedure on demand or schedule:

*call public.sp\_ddb\_to\_redshift\_incremental\_refresh\_cdc();*

Verify table and data by running a query on Redshift cluster for the tables to be replicated.
It should have captured data since DynamoDB table started streaming into Kinesis Data Stream.

Refer query [scheduling process in redshift query editor v2](https://docs.aws.amazon.com/redshift/latest/mgmt/query-editor-schedule-query.html) for query scheduling steps.



### Notes

- This is for CDC only for an existing table. In production scenario you may want to do a full copy/load via S3 and then use this process for ongoing changes.
- For a new table this can capture data from initial changes if process is configured prior to new data.
- You can run CDC with multiple tables pointing to same Kinesis Data Stream.
- A new column is added to target table (dist\_Key) to track keys and distribution.
- Target data table has all columns defined and stored as **varchar** to accommodate any future changes to attributes.

### Frequently Asked Questions

Can this process be used for non DynamDb Json sources?

    Not at this time. But the framework of process is reusable for other JSON data ingestion. 
    This requires extending parts of the process to handle other Json formats.
What happens when multiple updates happen to a single key item within the window of refresh?

    Only last image of the record will be processed ignoring other duplicate CDC entries.

Can this process run CDC for multiple table sources?

    The process will handle As long as these multiple DynamoDB tables are streaming changes to same Kinesis Data Stream.

How data is stored in Materialized View?

    Data is stored in SUPER data type column in JSON format.

What happens when a source table column is renamed?

    Change record is processed as if a new column is added. 
    Target table in Redshift will have both columns and old column will have NULL values.



#### Sample IAM role

Sample IAM role will look like this.
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
     "Sid": "ReadStream",
     "Effect": "Allow",
       "Action": [
          "kinesis:DescribeStreamSummary",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:DescribeStream"
        ],
    "Resource": "arn:aws:kinesis:*:123443211234:stream/*"
    },
    {
      "Sid": "ListStream",
      "Effect": "Allow",
      "Action": [
        "kinesis:ListStreams",
        "kinesis:ListShards"
      ],
      "Resource": "*"
    }
  ]
}
```
