# Amazon Redshift UDFs
A collection of user-defined functions (UDFs) for Amazon Redshift. The intent of this collection is to provide examples for defining python UDFs as well as useful functions which extend Amazon Redshift capabilities as well as support migrations from legacy DB platforms.

## Contents
Each function is allocated a folder.  At minimal each function will have the the following files:

**function.sql** - the SQL script to be run in the Redshift DB to create the function.  
**input.csv** - a list of sample input parameters to the function, delimited by comma (,) and where strings are denoted with single-quotes.
**output.csv** - a list of expected output values from the function.  

### python-udfs

See the AWS Documentation for more details on [creating a scalar python UDF]((https://docs.aws.amazon.com/redshift/latest/dg/udf-creating-a-scalar-udf.html).  If your function requires custom libraries include the following file.  

**requirements.txt** - a list of libraries to be packaged, uploaded to S3 to the `S3Loc`, and mapped in Redshift using the `RedshiftRole`.  See [f_ua_parser_family](python-udfs/f_ua_parser_family(varchar)) for an example.  The role should be one that can be assumed by the Redshift service, is attached to your Redshift cluster and has the GetObject permission for the `S3Loc`.

### lambda-udfs

See the AWS documentation for more detail on [create a scalar Lambda UDF](https://docs.aws.amazon.com/redshift/latest/dg/udf-creating-a-lambda-sql-udf.html).  For lambda UDFs, also include the following file.

**lambda.yaml** - a CFN template containing the Lambda function. The template should contain an input parameter for the `LambdaRole` which will be attached to the function.  This role should be one that can be assumed by the Lambda service.
**function.sql** - this SQL code should reference the Lambda function name referenced in the lambda.yaml file and should also contain a parameter `:RedshiftRole`.  This role should be one that can be assumed by the Redshift service and is attached to your Redshift cluster.

### sql-udfs
See the AWS documentation for more detail on [create a scalar SQL UDF](https://docs.aws.amazon.com/redshift/latest/dg/udf-creating-a-scalar-sql-udf.html).  For lambda UDFs, also include the following file.

## Deployment & Testing
Located in the `bin` directory are tools to deploy and test your UDF functions.  **Note:** Pull requests will be tested using a Github workflow which leverages these scripts. Please execute these script prior to submitting a pull request to ensure the request is approved quickly.

**deployFunction.sh** - This script will orchestrate the deployment of the UDF to your AWS environment. This includes
1. Looping through modules in a `requirements.txt` file (if present) and installing them using the `libraryInstall.sh` script by uploading the packages to the `S3Loc` and creating the library in Redshift using the `RedshiftRole`.
2. If deploying a lambda UDF, deploying a CloudFormation template `lambda.yaml` (if present) passing in the `LambdaRole` parameter.
3. Creating the UDF function by executing the `function.sql` sql script using the `RedshiftRole` parameter (for Lambda functions).

```
./deployFunction.sh -t lambda-udfs -f "f_upper_python(varchar)" -c $CLUSTER -d $DB -u $USER -n $SCHEMA -r $REDSHIFT_ROLE -l $LAMBDA_ROLE

./deployFunction.sh -t python-udfs -f "f_ua_parser_family(varchar)" -c $CLUSTER -d $DB -u $USER -n $SCHEMA -r $REDSHIFT_ROLE -s $S3_LOC
```

**testFunction.sh** - This script will test the UDF by
1. Creating a temporary table containing the input parameters of the function.
2. Loading sample input data of the function using the `input.csv` file.  
3. Running the function leveraging the sample data and comparing the output to the `output.csv` file.

```
./testFunction.sh -t lambda-udfs -f "f_upper_python(varchar)" -c $CLUSTER -d $DB -u $USER -n $SCHEMA

./testFunction.sh -t python-udfs -f "f_ua_parser_family(varchar)" -c $CLUSTER -d $DB -u $USER -n $SCHEMA
```

## Contributing
We would love to receive your pull requests for new functionality. See [CONTRIBUTING.md](CONTRIBUTING.md) for more details.  

## RedshiftRole

Suggested `RedshiftRole` Policy
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
                "arn:aws:s3:::$S3_LOC*"
            ]
        }
    ]
}
```
