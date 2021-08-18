#!/bin/bash
set -e

#to-do: create dependent services, set outputs to env
#to-do: if lambda cfn, deploy, pass in parameters from env

function usage {
	echo "./deployFunction.sh -t <type> -f <function> -s <s3 location> -r <redshift role> -c <cluster> -d <database> -u <db user> -n <namespace>"
	echo
	echo "where <type> is the type of function to be installed. e.g. python-udfs, lambda-udfs, sql-udfs"
	echo "      <function> is the name of the function, including the parameters and enclosed in quotes e.g. \"f_bitwise_to_string(bigint,int)\""
	echo "      <s3 location> (optional) is the location on S3 to upload the artifact to. Must be in format s3://bucket/prefix/"
	echo "      <redshift role> (optional) is the role which is attached to the Redshift cluster and has access to read from the s3 upload location (for python libs) and/or lambda execute permissions (for lambda fns)"
	echo "      <cluster> is the Redshift cluster you will deploy the function to"
	echo "      <database> is the database you will deploy the function to"
	echo "      <db user> is the db user who will create the function"
	echo "      <namespace> is the db namespace (schema) where the function will be created"
	exit 0;
}

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
    exit 0
  fi
}

function checkDep {
	which $1 >> /dev/null
	if [ $? -ne 0 ]; then
		echo "Unable to find required dependency $1"
		exit -1
	fi
}

function notNull {
	if [ "$1x" == "x" ]; then
		echo $2
		exit -1
	fi
}

# make sure we have pip and the aws cli installed
checkDep "aws"

# look up runtime arguments of the module name and the destination S3 Prefix
while getopts "t:f:s:l:r:c:d:u:n:h" opt; do
	case $opt in
		t) type="$OPTARG";;
		f) function="$OPTARG";;
		s) s3Loc="$OPTARG";;
		r) redshiftRole="$OPTARG";;
		c) cluster="$OPTARG";;
		d) db="$OPTARG";;
		u) user="$OPTARG";;
		n) schema="$OPTARG";;
		h) usage;;
		\?) echo "Invalid option: -"$OPTARG"" >&2
			exit 1;;
		:) usage;;
	esac
done

# validate required arguments
notNull "$type" "Please provide the function type -t"
notNull "$function" "Please provide the function name -f"
notNull "$cluster" "Please provide the Redshift cluster name -c"
notNull "$db" "Please provide the Redshift cluster db name -d"
notNull "$user" "Please provide the Redshift cluster user name -u"
notNull "$schema" "Please provide the Redshift cluster namespace (schema) -n"


if test -f "../$type/$function/requirements.txt"; then
  # check that the s3 prefix is in the right format
  # starts with 's3://'
  notNull "$s3Loc" "Please provide the S3 Location to store the library package -s"
  notNull "$redshiftRole" "Please provide the Redshift role which is attached to the Redshift cluster and has access to read from the s3 upload location -r"

  if ! [[ $s3Loc == s3:\/\/* ]]; then
  	echo "S3 Prefix must start with 's3://'"
  	echo
  	usage
  fi

  while read dep; do
    echo Installing: $dep
    ./libraryInstaller.sh -m $dep -s $s3Loc -r $redshiftRole -c $cluster -d $db -u $user
  done < ../$type/$function/requirements.txt
fi

if test -f "../$type/$function/lambda.yaml"; then
  template=$(<"../$type/$function/lambda.yaml")
  stackname=${function//(/-}
  stackname=${stackname//)/}
  stackname=${stackname//_/-}
  stackname=${stackname//,/-}
  if ! aws cloudformation deploy --template-file ../${type}/${function}/lambda.yaml --stack-name ${stackname} --no-fail-on-empty-changeset --capabilities CAPABILITY_IAM; then
		aws cloudformation delete-stack --stack-name ${stackname}
		exit 1
	fi
fi


sql=$(<"../$type/$function/function.sql")
echo execQuery "${sql//:RedshiftRole/$redshiftRole}"
execQuery "${sql//:RedshiftRole/$redshiftRole}"
