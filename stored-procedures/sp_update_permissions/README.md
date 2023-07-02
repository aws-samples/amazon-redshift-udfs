# sp_update_permissions

Stored procedure that reads user, group and role permission matrix from Amazon S3 and updates authorisation in Redshift accordingly. It helps startups and small to medium organisations that haven't integrated Amazon Redshift with an identity provider to streamline security measures and acceess control for their data warehouse built with Amazon Redshift. This SP can be used for bulk update of permissions for principals mentioned above, at schema, table, column and row level. 

It expects the file in delimited text format with following schema and "|" as delimiter:          
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;id|operation|principal|principal_type|object_type|object_name|access_option

For example:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1|grant|group_1|group|schema|schema_1|usage

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2|revoke|user_1|user|table|table_1|select

## Pre-requisites

1- Create an S3 bucket: The first step before starting to use the stored procedure is to load the first version of the file into an Amazon S3 bucket. Take a note of the S3 bucket name.

2- Create IAM role for Redshift to access external data: Since the stored procedure reads data stored in S3 using external schema, you need a Redshift role with relevant permissions. Please make sure you have created the role by following the steps [here](https://docs.aws.amazon.com/redshift/latest/dg/c-getting-started-using-spectrum-create-role.html). After the role is created, attach it to your Redshift cluster in the Properties tab of Amazon Redshift console page.

3- AWS Lake Formation access for Redshift external role: If you have Lake Formation enabled for your account and region, you need to add the IAM role created to access external data as admin in AWS Lake Formation. Follow the steps below:

- Navigate to AWS Lake Formation console
- From the left pane, choose "Administrative roles and tasks" under Permissions
- In the Data lake administrators section click on Choose administrators
- Search for and select your role from drop-down list
- Click on Save

Note that this step is needed only if you have enabled AWS Lake Formation for the account and region where your Amazon Redshift cluster resides.

The rest of the steps from here should be executed from Amazon Redshift Query Editor Version 2 (QEv2) as superuser.


## Install
1- Create external schema: Run the following command to create external schema. You would need to replace the IAM Role ARN for your Spectrum role:

```sql
create external schema access_management 
from data catalog database redshift 
iam_role '[Spectrum_Role_ARN]' 
create external database if not exists;

```
Feel free to change the name of the schema. Take a note of it if you prefer a different name.

2- Create external table: Run the following command to create external table: 
```sql
create external table access_management.redshift_access_details(
    id integer,
    operation varchar(50),
    principal varchar(50),
    principal_type varchar(50),
    object_type varchar(50),
    object_name varchar(50),
    access_option varchar(50))
    row format delimited
    fields terminated by '|'
    stored as textfile
    location 's3://[path_to_location_your_file_is_stored_in_s3]'
;

```
Same as previous step, feel free to change the name of the table and take a note of it.

3- Test external table: Copy the first user access details file, "user_access_details_1.csv" into your S3 bucket and run the following command. Make sure you can query the file you uploaded to S3:

```sql
SELECT * FROM access_management.redshift_access_details;

```
You are ready to move to the next steps if your query returns the rows from the file.


4- Login to Redshift Query Editor Version 2 (QEv2) as superuser, copy and paste the code in "create_sp.sql" in QEv2 and execute it. 


## Usage
To execute the stored procedure, replace input parameters in the command below with the names you used in pre-requisites steps:

```sql
CALL sp_update_permissions('[external_schema_name]', '[external_table_name]');

```
If you didn't change schema and table names, the command should be:
```sql
CALL sp_update_permissions('access_management', 'redshift_access_details','[iam_role_arn]');
```

## Test

A set of test scenarios are covered in "test_scenarios.sql". 
