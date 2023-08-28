#!/bin/bash
set -eu

category=$1
function=$2
cluster=$3
db=$4
user=$5
schema=$6

function usage {
	echo "./deployFunction.sh -t <type> -f <function> -c <cluster> -d <database> -u <db user> "
	echo
	echo "where <type> is the type of function to be installed. e.g. python-udfs, lambda-udfs, sql-udfs"
	echo "      <function> is the name of the function, including the parameters and enclosed in quotes e.g. \"f_bitwise_to_string(bigint,int)\""
	echo "      <cluster> is the Redshift cluster you will deploy the function to"
	echo "      <database> is the database you will deploy the function to"
	echo "      <db user> is the db user who will create the function"
	echo "      <schema> is the db schema where the function will be created"

	exit 0;
}

execQuery() {
  output=`aws redshift-data batch-execute-statement --cluster-identifier $1 --database $2 --db-user $3 --sql "set search_path to $4; $5" "$6"`
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
    aws redshift-data get-statement-result --id $id:2
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


if test -f "../$type/$function/resources.yaml"; then
  template=$(<"../$type/$function/resources.yaml")
  stackname=${function//(/-}
  stackname=${stackname//)/}
  stackname=${stackname//_/-}
  stackname=${stackname//,/-}
  if ! aws cloudformation deploy --template-file ../${type}/${function}/resources.yaml --stack-name ${stackname}-resources --no-fail-on-empty-changeset --capabilities CAPABILITY_IAM; then
		aws cloudformation delete-stack --stack-name ${stackname}-resources
		exit 1
	fi
fi

arrIN=(${function//(/ })
name=${arrIN[0]}
args=${arrIN[1]}
args=${args%?}
i=0
fields=
params=
OIFS=$IFS
IFS=','
for arg in $args
do
  fields="$fields,p$i $arg"
  params="$params,p$i"
  ((i=i+1))
done
IFS=$OIFS

sql="drop table if exists #$name"
sql="$sql;create table #$name (seq int$fields)";

rows=""
sql="$sql;insert into #$name values "

i=0
while read row; do
  rows="$rows ($i,$row),"
  ((i=i+1))
done <"../$type/$function/input.csv"

sql="$sql${rows%?}"
sql1="select $name(${params:1})::varchar from #$name order by seq;"
echo "$sql;$sql1"
output=`execQuery $cluster $db $user $schema "$sql" "$sql1"`
echo $output | jq -r '.Records | .[] | [.[0].stringValue] | .[]' > output.csv
diff output.csv "../$type/$function/output.csv"
echo "Test passed. Result from Redshift: "
cat output.csv
rm output.csv
