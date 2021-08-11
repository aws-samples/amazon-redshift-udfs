# Amazon Redshift UDFs
A collection of example user-defined functions (UDFs) and utilities for Amazon Redshift. The intent of this collection is to provide examples for defining python UDFs, but the UDF examples themselves may not be optimal to achieve your requirements.

## Contents

This project is divided into several areas:

- `bin/`

Contains utilities related to working with UDFs. This includes the the following functions:

**libraryInstaller.sh** - Applicable for `plpythonu` functions, this script will take any python module which is not available on the Redshift server, package it in a `*.whl` file, upload the package to S3 and map it to a library within Redshift which can be referenced in your function.  

**deployFunction.sh** - This script will orchestrate the deployment of the UDF to your AWS environment. This includes
1. Looping through modules in a `requirements.txt` file (if present) and installing them using the `libraryInstall.sh` script.
2. If deploying a lambda UDF, deploying a CloudFormation template `lambda.yaml` (if present) defining the function.
3. Creating the UDF function by executing the `function.sql` sql script.

**testFunction.sh** - This script will test the UDF by
1. Creating a temp table containing the input parameters of the function.
2. Loading sample input data of the function using the `input.csv` file.  Note: Strings in this file should be delimited by a single-quote (').
3. Running the function leveraging the sample data and comparing the output to the `output.csv` file.

- `python-udfs/`

Contains UDF code written in `plpythonu`.  Some are intended as example functions to demonstrate how to write/deploy your function.  Others are intended to extend the functionality of  Redshift platform.

- `views/`

Contains helpful views to simplify administration of UDFs.  E.g. A view to generate the UDF ddl.

## Contributing

We would love to receive your pull requests for new functionality. See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.  

**Note:** Pull requests will be tested using a Github workflow which expects the following input parameters gathered from the Github secrets. It's recommended you set these parameter in your local repository and trigger the workflow prior to submitting a pull request to ensure to ensure the function will be approved:

1. AWS_ID /  AWS_KEY - The AWS API Key. See [Suggested Deployment Policy](#suggested-deployment-policy).
1. CLUSTER - The Redshift cluster name.
1. DB - The Redshift cluster database.
1. USER - The Redshift cluster user.
1. AWS_REGION - The Redshift cluster region.
1. SCHEMA - The Redshift cluster schema.
1. S3_LOC - (optional) needed if deploying a python function which requires an external library.  
1. IAM_ROLE - (optional) needed if deploying a python function which requires an external library.   or when deploying Lambda UDF function.  This role should be attached to the Redshift cluster.

###Suggested Deployment Policy
```json
```

Suggested Execution Policy
```json
If so, `IAM_ROLE` should have s3 get/list privileges to the location specified in the S3_LOC parameter and be a role attached to the Redshift cluster.
If so, the `IAM_ROLE` should also be attached to the Redshift cluster with execute privileges on the Lambda function.
and have CloudWatch log privileges.
```

Suggested Execution Trust Relationship
```json
In addition, it should have a trust relationship to be assumed by the Lambda service,
```
