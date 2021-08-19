# Amazon Redshift UDFs
A collection of user-defined functions (UDFs) for Amazon Redshift. The intent of this collection is to provide examples for defining python UDFs as well as useful functions which extend Amazon Redshift capabilities as well as support migrations from legacy DB platforms.

## Contents
Each function is allocated a folder.  At minimal each function will have the the following files which will be used by the [deployFunction.sh](#deployFunctionsh) script and [testFunction.sh](#testFunctionsh) scripts:

- **function.sql** - the SQL script to be run in the Redshift DB which creates the UDF.  If a Lambda function, use the string `:RedshiftRole` for the IAM role to be passed in by the deployment script.
- **input.csv** - a list of sample input parameters to the function, delimited by comma (,) and where strings are denoted with single-quotes.
- **output.csv** - a list of expected output values from the function.

### python-udfs

[Python UDFs](https://docs.aws.amazon.com/redshift/latest/dg/udf-creating-a-scalar-udf.html) may include the following additional file:

- **requirements.txt** - If your function requires modules not available already in Redshift, a list of modules.  The modules will be packaged, uploaded to S3, and mapped to a [library](https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_LIBRARY.html) in Redshift.  

### lambda-udfs

[Lambda UDFs](https://docs.aws.amazon.com/redshift/latest/dg/udf-creating-a-lambda-sql-udf.html) must include the following additional file:

- **lambda.yaml** - a CFN template containing the Lambda function.  The lambda function name should match the redshift function name with '_' replaced with '-'  e.g. (f-upper-python-varchar). The template may contain additional AWS services required by the lambda function and should contain an IAM Role which can be assumed by the lambda service and which grants access to those additional services (if applicable).  In a production deployment, be sure to add resource restrictions to the Lambda IAM Role to ensure the permissions are scoped down.

- **resources.yaml** - a CFN template containing external resources which may be referenced by the Lambda function.   These resources are for testing only.

- **package.json** - (NodeJS Only) If your function requires modules not available already in Lambda, a list of modules.  The modules will be packaged, uploaded to S3, and mapped to your Lambda function. See (f_mysql_lookup_nodejs)[lambda-udfs/f_mysql_lookup_nodejs-varchar-varchar-varchar] for and example.  

- **requirements.txt** - (Python Only) If your function requires modules not available already in Redshift, a list of modules.  The modules will be packaged, uploaded to S3, and mapped to your Lambda function.  See (f_mysql_lookup_python)[lambda-udfs/f_mysql_lookup_python-varchar-varchar-varchar] for and example.

### sql-udfs
[SQL UDFs](https://docs.aws.amazon.com/redshift/latest/dg/udf-creating-a-scalar-sql-udf.html) do not require any additional files.

## Deployment & Testing
Located in the `bin` directory are tools to deploy and test your UDF functions.  

### deployFunction.sh
This script will orchestrate the deployment of the UDF to your AWS environment. This includes
1. Looping through modules in a `requirements.txt` file (if present) and installing them using the `libraryInstall.sh` script by uploading the packages to the `$S3_LOC` and creating the library in Redshift using the `$REDSHIFT_ROLE`.
2. If deploying a lambda UDF, deploying a CloudFormation template `lambda.yaml` (if present) passing in the `LambdaRole` parameter.
3. Creating the UDF function by executing the `function.sql` sql script using the `RedshiftRole` parameter (for Lambda functions).

```
./deployFunction.sh -t lambda-udfs -f "f_upper_python(varchar)" -c $CLUSTER -d $DB -u $USER -n $SCHEMA -r $REDSHIFT_ROLE

./deployFunction.sh -t python-udfs -f "f_ua_parser_family(varchar)" -c $CLUSTER -d $DB -u $USER -n $SCHEMA -r $REDSHIFT_ROLE -s $S3_LOC
```

### testFunction.sh
This script will test the UDF by
1. Creating a temporary table containing the input parameters of the function.
2. Loading sample input data of the function using the `input.csv` file.  
3. Running the function leveraging the sample data and comparing the output to the `output.csv` file.

```
./testFunction.sh -t lambda-udfs -f "f_upper_python(varchar)" -c $CLUSTER -d $DB -u $USER -n $SCHEMA

./testFunction.sh -t python-udfs -f "f_ua_parser_family(varchar)" -c $CLUSTER -d $DB -u $USER -n $SCHEMA
```

## Contributing / Pull Requests

We would love your contributions.  See the [contributing](contributing.md) page for more details no creating a fork of the project and a pull request of your contribution.

> Pull requests will be tested using a Github workflow which leverages the above testing scripts. Please execute these script prior to submitting a pull request to ensure the request is approved quickly.  When executed in the test enviornment the [RedshiftRole](#redshift-role) will be defined as follows. You can create a similar role in your local environment for testing.

### Redshift Role
These privileges ensure the UDF can invoke the Lambda Function as well as access the uploaded `*.whl` files located in s3.  
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "arn:aws:lambda:*:*:function:f-*",
                "arn:aws:s3:::<test bucket>/*"
            ]
        }
    ]
}
```
