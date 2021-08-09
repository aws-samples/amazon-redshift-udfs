#!/bin/bash
set -eu

category=$1
function=$2
cluster=$3
db=$4
user=$5
schema=$6

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
done <"../$category/$function/input.csv"

sql="$sql${rows%?}"
sql1="select $name(${params:1})::varchar from #$name order by seq;"
echo "$sql;$sql1"
output=`execQuery $cluster $db $user $schema "$sql" "$sql1"`
echo $output | jq -r '.Records | .[] | [.[0].stringValue] | @csv' > output.csv
diff output.csv "../$category/$function/output.csv"
cat output.csv
rm output.csv
