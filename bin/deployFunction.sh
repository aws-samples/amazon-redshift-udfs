#!/bin/bash
set -eux

# Depends on Python installed, and the AWS CLI configured including the region, iam priv to write to the location and get DB credentials for the user supplied
category=$1
function=$2
s3Loc=$3 #only if requirements.txt file
iamRole=$4 #if requirements.txt or lambda function
cluster=$5
db=$6
user=$7
schema=$8

#to-do: create dependent services, set outputs to env
#to-do: if lambda cfn, deploy, pass in parameters from env

execQuery()
{
  output=`aws redshift-data execute-statement --cluster-identifier $1 --database $2 --db-user $3 --sql "set search_path to $4; $5"`
  id=`echo $output | jq -r .Id`

  status="SUBMITTED"
  while [ "$status" != "FINISHED" ] && [ "$status" != "FAILED" ]
  do
    sleep 1
    status=`aws redshift-data describe-statement --id $id | jq -r .Status`
  done
  echo $id:$status
}

if test -f "../$category/$function/requirements.txt"; then
  sql=""
  while read dep; do
    ./installPipModuleAsRedshiftLibrary.sh -m $dep -s $s3Loc -r $iamRole -c $cluster -d $db -u $user
  done < ../$category/$function/requirements.txt
fi

sql=$(<"../$category/$function/function.sql")
echo execQuery $cluster $db $user $schema "$sql"
execQuery $cluster $db $user $schema "$sql"
#to-do: handle parameters (i.e. lambda arn, role arn)
if [ $? != 0 ]; then
	exit $?
fi
