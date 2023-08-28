#!/bin/bash
set -e

#to-do: create dependent services, set outputs to env
#to-do: if lambda cfn, deploy, pass in parameters from env

function usage {
	echo "./deployFunction.sh -t <type> -f <function> -s <s3 bucket> -k <s3 key> -r <redshift role> -c <cluster> -d <database> -u <db user> -n <namespace> -g <security group> -x subnet"
	echo
	echo "where <type> is the type of function to be installed. e.g. python-udfs, lambda-udfs, sql-udfs"
	echo "      <function> is the name of the function, including the parameters and enclosed in quotes e.g. \"f_bitwise_to_string(bigint,int)\""
	echo "      <cluster> is the Redshift cluster you will deploy the function to"
	echo "      <database> is the database you will deploy the function to"
	echo "      <db user> is the db user who will create the function"
	echo "      <namespace> is the db namespace (schema) where the function will be created"
	echo "      <s3 bucket> (optional) is the bucket in S3 to upload the artifact to."
	echo "      <s3 key> (optional) is the key in S3 to upload the artifact to."
	echo "      <redshift role> (optional) is the role which is attached to the Redshift cluster and has access to read from the s3 upload location (for python libs) and/or lambda execute permissions (for lambda fns)"
	echo "      <security group> (optional) is security the security group the lambda function will run in "
	echo "      <subnet> (optional) is the subnet the lambda function will run in"
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
checkDep "jq"

# look up runtime arguments of the module name and the destination S3 Prefix
while getopts "t:f:s:k:l:r:c:d:u:n:g:x:h" opt; do
  case $opt in
    t) type="$OPTARG";;
    f) function="$OPTARG";;
    s) s3Bucket="$OPTARG";;
    k) s3Key="$OPTARG";;
    r) redshiftRole="$OPTARG";;
    c) cluster="$OPTARG";;
    d) db="$OPTARG";;
    u) user="$OPTARG";;
    n) schema="$OPTARG";;
    g) securityGroup="$OPTARG";;
    x) subnet="$OPTARG";;
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

paramsBuckets=""

if test -z "$subnet"; then
	paramsVPC=""
else
	paramsVPC="SecurityGroupId=${securityGroup} SubnetId=${subnet}"
fi

if test -f "../$type/$function/package.json"; then
  notNull "$s3Bucket" "Please provide the S3 Bucket to store the library package -s"
  s3Loc="s3://$s3Bucket/$s3Key"
  cd ../$type/$function
  npm install
  zip -r $function.zip index.js node_modules
  aws s3 cp $function.zip $s3Loc
  rm $function.zip
  rm package-lock.json
  rm -rf node_modules
  cd ../../bin
  paramsBuckets="S3Bucket=$s3Bucket S3Key=$s3Key$function.zip"
fi

if test -f "../$type/$function/requirements.txt"; then
  # check that the s3 prefix is in the right format
  # starts with 's3://'
  notNull "$s3Bucket" "Please provide the S3 Bucket to store the library package -s"
  notNull "$redshiftRole" "Please provide the Redshift role which is attached to the Redshift cluster and has access to read from the s3 upload location -r"

	if [ -z "$s3Key" ]; then
		s3Loc="s3://$s3Bucket"
	else
		s3Loc="s3://$s3Bucket/$s3Key"
	fi

  if [ "${type}" == "lambda-udfs" ]; then 
    echo "Building layer"
    cat ../$type/$function/requirements.txt | while read dep; do
      ./layerInstaller.sh -s "${s3Loc}" -r "${dep}" -f "${function}"
    done
    paramsBuckets="S3Bucket=$s3Bucket S3Key=$s3Key"
  else
    checkDep "pip3"
    while read dep; do
      echo Installing: $dep
      ./libraryInstaller.sh -m $dep -s $s3Loc -r $redshiftRole -c $cluster -d $db -u $user
    done < ../$type/$function/requirements.txt
    paramsBuckets="S3Bucket=$s3Bucket S3Key=$s3Key$function.zip"
  fi
fi

if test -f "../$type/$function/pom.xml"; then
  # check that the s3 prefix is in the right format
  # starts with 's3://'
  notNull "$s3Bucket" "Please provide the S3 Bucket to store the library package -s"
  notNull "$redshiftRole" "Please provide the Redshift role which is attached to the Redshift cluster and has access to read from the s3 upload location -r"
  s3Loc="s3://$s3Bucket/$s3Key"
	checkDep "mvn"
	cd ../$type/$function
  #mvn --batch-mode --update-snapshots verify
	#rm -rf target
	mvn package
	packagename=${function//(/_}
  packagename=${packagename//)/}
	aws s3 cp "target/$packagename-1.0.0.jar" "$s3Loc$packagename-1.0.0.jar"
	rm -rf target
	rm dependency-reduced-pom.xml
	cd ../../bin
	paramsBuckets="S3Bucket=$s3Bucket S3Key=$s3Key$packagename-1.0.0.jar"
fi

if test -f "../$type/$function/lambda.yaml"; then
  template=$(<"../$type/$function/lambda.yaml")
  stackname=${function//(/-}
  stackname=${stackname//)/}
  stackname=${stackname//_/-}
  stackname=${stackname//,/-}
  if ! aws cloudformation deploy --template-file ../${type}/${function}/lambda.yaml --parameter-overrides ${paramsVPC} ${paramsBuckets} --stack-name ${stackname} --no-fail-on-empty-changeset --capabilities CAPABILITY_IAM; then
    aws cloudformation delete-stack --stack-name ${stackname}
    exit 1
  fi
fi


sql=$(<"../$type/$function/function.sql")
echo execQuery "${sql//:RedshiftRole/$redshiftRole}"
execQuery "${sql//:RedshiftRole/$redshiftRole}"
