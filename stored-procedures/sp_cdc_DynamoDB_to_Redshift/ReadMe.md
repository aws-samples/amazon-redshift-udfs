CDC changes from DynamoDB table to Redshift table:

The solutions below enable data replication between DynamoDB and Redshift in a generic way where schema changes are handled by Redshift process. A scheduled process keeps DynamoDB table and corresponding Redshift table in sync both in data and structure. Additional analytics processes can be built on these base tables as use case demands.

At high level the steps are 

- Create a Kinesis data stream (KDS) and turn on the data stream to KDS for tables to be replicated from DynamoDB. 
- Create a materialized view in your Amazon Redshift cluster to consume streaming data from the Kinesis Data Stream.
- The streaming data gets ingested as a JSON payload. This JSON data is processed into Redshift tables via a Stored Procedure. 

DynamoDB can stream multiple tables into a single stream. So, there will be one stream processed by Redshift to apply changes.


Steps:

- Create Kinesis Data Stream. (Example name: *redshift\_cdc*) 
- Create a Dynamo DB table and enable data streaming to Kinesis Data Stream created in step 1. 
- Create an IAM role with ability to read KDS streams and attach it to Redshift cluster. (Sample Role in the folder policy.json. Example name: *my\_streaming\_role*)
- Create Redshift process. 
  - Create Stored Procedure on Redshift Cluster either in QEv2 or via any SQL tool. Create procedures as per the sp\_cdc\_DynamoDB\_to\_Redshift.sql file. 
  - Verify below procedures are created
    - sp\_create\_table\_varchar\_max(varchar)
    - sp\_cursor\_loop\_alter\_tables()
    - sp\_cursor\_loop\_create\_tables()
    - sp\_cursor\_loop\_process\_merge\_tables()
    - sp\_ddb\_to\_redshift\_incremental\_refresh\_cdc()
    - sp\_ddb\_to\_redshift\_setup\_process\_tables()
    - sp\_ddb\_to\_redshift\_setup\_schema\_mv(varchar,varchar,varchar)
    - sp\_delete\_table\_key\_data()
    - sp\_merge\_table\_key\_data()
  - Execute procedure below to create materialized view and schema replacing with IAM role, Account\_Number and KDS name. one time process.
    - call public.sp\_ddb\_to\_redshift\_setup\_schema\_mv(*'my\_streaming\_role','123456781234','redshift\_cdc')*;
    - This will create necessary schema and materialized view to capture data from DynamoDB.
  - Execute procedure below to create tables needed for replication process. one time process.
    - call public.sp\_ddb\_to\_redshift\_setup\_process\_tables();
- Procedure to replicate data -   Execute below procedure on demand or schedule:

call public.sp\_ddb\_to\_redshift\_incremental\_refresh\_cdc();

Verify table and data by running a query on Redshift cluster for the tables. It should have captured data since DynamoDB table started streaming into Kinesis Data Stream




Notes:

- This is for CDC only for an existing table. In production scenario you may want to do a full copy/load via S3 and then use this process for ongoing changes.
- For a new table this can capture data from initial changes if process is configured prior to new data.
- You can run CDC with multiple tables pointing to same Kinesis Data Stream.
- A new column is added to target table (dist\_Key) to track keys and distribution.
- Target data table has all columns defined and stored as **varchar** to accommodate any future changes to attributes. 

