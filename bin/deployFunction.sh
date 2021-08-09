#!/bin/bash
set -eux

# Depends on Python installed, and the AWS CLI configured including the region, iam priv to write to the location and get DB credentials for the user supplied
category=$1
function=$2
s3Loc=$3 #only if requirements.txt file, todo: make optional
iamRole=$4 #if requirements.txt or lambda function, todo: make optional
cluster=$5
db=$6
user=$7
schema=$8

#to-do: create dependent services, set outputs to env
#to-do: if lambda cfn, deploy, pass in parameters from env

execQuery()
{
  output=`aws redshift-data execute-statement --cluster-identifier $cluster --database $db --db-user $user --parameters [{"name":"iamRole","value":"$iamRole"}] --sql "set search_path to $schema; $1"`
  id=`echo $output | jq -r .Id`

  status="SUBMITTED"
  while [ "$status" != "FINISHED" ] && [ "$status" != "FAILED" ]
  do
    sleep 1
    status=`aws redshift-data describe-statement --id $id | jq -r .Status`
  done
  if [ "$status" == "FAILED" ]; then
    aws redshift-data describe-statement --id $id
    exit 1
  else
    echo $id:$status
  fi
}


if test -f "../$category/$function/requirements.txt"; then
  sql=""
  while read dep; do
    ./installPipModuleAsRedshiftLibrary.sh -m $dep -s $s3Loc -r $iamRole -c $cluster -d $db -u $user
  done < ../$category/$function/requirements.txt
fi

if test -f "../$category/$function/lambda.yaml"; then
  template=$(<"../$category/$function/lambda.yaml")
  stackname=${function//(/-}
  stackname=${stackname//)/-}
  stackname=${stackname//_/-}
  output=`aws cloudformation update-stack --stack-name ${stackname} --parameters ParameterKey=LambdaRole,ParameterValue=$iamRole --template-body "$template"`
  if [ $? != 0 ]; then
		output=`aws cloudformation create-stack --stack-name ${stackname} --parameters ParameterKey=LambdaRole,ParameterValue=$iamRole --template-body "$template"`
	fi
  if [ $? != 0 ]; then
    echo $output
    exit $?
  fi
fi


sql=$(<"../$category/$function/function.sql")
echo execQuery "$sql"
execQuery "$sql"
#to-do: handle parameters (i.e. lambda arn, role arn)
