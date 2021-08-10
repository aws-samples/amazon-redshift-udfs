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
sqlparam=

#to-do: create dependent services, set outputs to env
#to-do: if lambda cfn, deploy, pass in parameters from env

execQuery()
{
  output=`aws redshift-data execute-statement --cluster-identifier $cluster --database $db --db-user $user --sql "set search_path to $schema; $1"`
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
  stackname=${stackname//)/}
  stackname=${stackname//_/-}
  stackname=${stackname//,/-}
  #aws cloudformation update-stack --stack-name ${stackname} --parameters ParameterKey=LambdaRole,ParameterValue=$iamRole  --template-body "$template" || aws cloudformation create-stack --on-failure DELETE --stack-name ${stackname} --parameters ParameterKey=LambdaRole,ParameterValue=$iamRole --template-body "$template"
  #aws cloudformation wait stack-create-complete --stack-name ${stackname}
  aws cloudformation deploy --template-file ../${category}/${function}/lambda.yaml --stack-name ${stackname} --parameter-overrides LambdaRole=${iamRole} --no-fail-on-empty-changeset
  #sqlparm=`echo --parameters "[{\"name\":\"iamRole\",\"value\":\"$iamRole\"}]"`
fi


sql=$(<"../$category/$function/function.sql")
echo execQuery "${sql//:iamRole/$iamRole}"
execQuery "${sql//:iamRole/$iamRole}"
#to-do: handle parameters (i.e. lambda arn, role arn)
