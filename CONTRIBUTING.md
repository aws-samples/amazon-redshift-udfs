# Contributing Guidelines

Thank you for your interest in contributing to our project. Whether it's a bug report, new feature, correction, or additional
documentation, we greatly value feedback and contributions from our community.

Please read through this document before submitting any issues or pull requests to ensure we have all the necessary
information to effectively respond to your bug report or contribution.

## Testing via GitHub Actions
You can configure GitHub actions in your fork by enabling the actions and setting up the corresponding secrets for the actions. The required secrets are:

* `AWS_ID` - The AWS Access Key ID for the GitHub runner to use
* `AWS_KEY` - The AWS Secret Access Key for the GitHub runner to use
* `REGION` - The region to run in
* `CLUSTER` - The Redshift cluster name
* `DB` - The Redshift cluster DB
* `SCHEMA` - The Redshift schema to use
* `USER` - The Redshift username to use
* `IAM_ROLE` - The Redshift IAM role name
* `S3_BUCKET` - The S3 bucket to use for artifacts
* `SECURITY_GROUP` - The Security Group to deploy into, if deploying Lambda in-VPC
* `SUBNET` - The Subnet to deploy into, if deploying Lambda in-VPC

The GitHub runner assumes you already have the Redshift cluster, S3 bucket, IAM role, etc. already configured in your AWS account.

The GitHub runner needs an IAM user with permissions to provision Lambda functions and execute tests. A minimal IAM policy for this GitHub user would be as follows - additional policies may be needed for your Lambda depending on the infrastructure you create in your CloudFormation templates:

```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"redshift-data:BatchExecuteStatement",
				"redshift-data:ExecuteStatement"
			],
			"Resource": [
				"arn:aws-us-gov:redshift:*:*:cluster:{redshift-cluster}"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"redshift-data:GetStatementResult",
				"redshift-data:DescribeStatement"
			],
			"Resource": [
				"*"
			],
			"Condition": {
				"StringEquals": {
					"redshift-data:statement-owner-iam-userid": "${aws:userid}"
				}
			}
		},
		{
			"Effect": "Allow",
			"Action": [
				"cloudformation:CreateChangeSet",
				"cloudformation:DescribeStacks",
				"cloudformation:ExecuteChangeSet",
				"cloudformation:DescribeChangeSet",
				"cloudformation:DeleteStack",
				"cloudformation:GetTemplateSummary"
			],
			"Resource": [
				"arn:aws-us-gov:cloudformation:*:*:stack/f-*"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"iam:DeleteRolePolicy",
				"iam:PutRolePolicy",
				"iam:DetachRolePolicy",
				"iam:GetRolePolicy",
				"iam:CreateRole",
				"iam:GetRole",
				"iam:DeleteRole",
				"iam:AttachRolePolicy",
				"iam:PassRole"
			],
			"Resource": [
				"arn:aws-us-gov:iam::*:role/f-*"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"lambda:CreateFunction",
				"lambda:DeleteFunction",
				"lambda:GetFunction",
				"lambda:PublishLayerVersion",
				"lambda:UpdateFunctionConfiguration",
				"lambda:DeleteLayerVersion",
				"lambda:GetLayerVersion"
			],
			"Resource": [
				"arn:aws-us-gov:lambda:*:*:function:f-*",
				"arn:aws-us-gov:lambda:*:*:layer:*",
				"arn:aws-us-gov:lambda:*:*:layer:*:*"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"sts:GetCallerIdentity"
			],
			"Resource": [
				"*"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"kms:Decrypt",
				"kms:GenerateDataKey"
			],
			"Resource": [
				"arn:aws-us-gov:kms:*:*:key/*"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"s3:GetObject",
				"s3:PutObject"
			],
			"Resource": [
				"arn:aws-us-gov:s3:::{s3-bucket}/*"
			]
		},
		{
			"Effect": "Allow",
			"Action": [
				"redshift:GetClusterCredentials"
			],
			"Resource": [
				"arn:aws-us-gov:redshift:*:*:dbuser:{redshift-cluster}/{user}",
				"arn:aws-us-gov:redshift:*:*:dbname:{redshift-cluster}/{database}"
			]
		}
	]
}
```


## Reporting Bugs/Feature Requests

We welcome you to use the GitHub issue tracker to report bugs or suggest features.

When filing an issue, please check existing open, or recently closed, issues to make sure somebody else hasn't already
reported the issue. Please try to include as much information as you can. Details like these are incredibly useful:

* A reproducible test case or series of steps
* The version of our code being used
* Any modifications you've made relevant to the bug
* Anything unusual about your environment or deployment


## Contributing via Pull Requests
Contributions via pull requests are much appreciated. Before sending us a pull request, please ensure that:

1. You are working against the latest source on the *main* branch.
2. You check existing open, and recently merged, pull requests to make sure someone else hasn't addressed the problem already.
3. You open an issue to discuss any significant work - we would hate for your time to be wasted.

To send us a pull request, please:

1. Fork the repository.  
2. Modify the source; please focus on the specific change you are contributing. If you also reformat all the code, it will be hard for us to focus on your change.
3. Ensure local tests pass.
4. Commit to your fork using clear commit messages.
5. Send us a pull request, answering any default questions in the pull request interface.
6. Pay attention to any automated CI failures reported in the pull request, and stay involved in the conversation.

GitHub provides additional document on [forking a repository](https://help.github.com/articles/fork-a-repo/) and
[creating a pull request](https://help.github.com/articles/creating-a-pull-request/).


## Finding contributions to work on
Looking at the existing issues is a great way to find something to contribute on. As our projects, by default, use the default GitHub issue labels (enhancement/bug/duplicate/help wanted/invalid/question/wontfix), looking at any 'help wanted' issues is a great place to start.


## Code of Conduct
This project has adopted the [Amazon Open Source Code of Conduct](https://aws.github.io/code-of-conduct).
For more information see the [Code of Conduct FAQ](https://aws.github.io/code-of-conduct-faq) or contact
opensource-codeofconduct@amazon.com with any additional questions or comments.


## Security issue notifications
If you discover a potential security issue in this project we ask that you notify AWS/Amazon Security via our [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/). Please do **not** create a public github issue.


## Licensing

See the [LICENSE](LICENSE.txt) file for our project's licensing. We will ask you to confirm the licensing of your contribution.
