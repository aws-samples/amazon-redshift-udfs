#!/bin/bash
set -e
# Install Pip Module as Redshift Library

function usage {
	echo "./libraryInstaller.sh -m <module> -s <s3 location> -r <iam role> -c <cluster> -d <database> -u <db user> "
	echo
	echo "where <module> is the name of the Pip module to be installed"
	echo "      <s3 location> is the location on S3 to upload the artifact to. Must be in format s3://bucket/prefix"
	echo "      <s3 role> is the role which is attached to the Redshift cluster and has access to read from the s3 upload location"
	echo "      <cluster> is the Redshift cluster you will deploy the function to"
	echo "      <database> is the database you will deploy the function to"
	echo "      <db user> is the db user who will create the function"

	exit 0;
}


function notNull {
	if [ "$1x" == "x" ]; then
		echo $2
		exit -1
	fi
}

# make sure we have wheel installed into pip
pip3 show wheel &> /dev/null
if [ $? != 0 ]; then
  echo "pip3 wheel not found. Please install with 'sudo pip install wheel'"
  exit -1
fi

# look up runtime arguments of the module name and the destination S3 Prefix
while getopts "m:s:r:c:d:u:h" opt; do
	case $opt in
		m) module="$OPTARG";;
		s) s3Prefix="$OPTARG";;
		r) s3Role="$OPTARG";;
		c) cluster="$OPTARG";;
		d) db="$OPTARG";;
		u) user="$OPTARG";;
		h) usage;;
		\?) echo "Invalid option: -"$OPTARG"" >&2
			exit 1;;
		:) usage;;
	esac
done

# validate arguments
notNull "$module" "Please provide the pip module name using -m"
notNull "$s3Prefix" "Please provide an S3 Prefix to store the library in using -s"

# check that the s3 prefix is in the right format
# starts with 's3://'

if ! [[ $s3Prefix == s3:\/\/* ]]; then
	echo "S3 Prefix must start with 's3://'"
	echo
	usage
fi

# found the module - install to a local hidden directory
echo "Installing $module with pip and uploading to $s3Prefix"

TMPDIR=.tmp
if [ ! -d "$TMPDIR" ]; then
  mkdir $TMPDIR
fi

rm -Rf "$TMPDIR/.$module" &> /dev/null

mkdir "$TMPDIR/.$module"

pip3 wheel $module --wheel-dir "$TMPDIR/.$module"
if [ $? != 0 ]; then
	echo "Unable to find module $module in pip."
	rm -Rf "$TMPDIR/.$module"
	exit $?
fi


execQuery()
{
  echo $4
  output=`aws redshift-data execute-statement --cluster-identifier $1 --database $2 --db-user $3 --sql "$4"`
  id=`echo $output | jq -r .Id`
  notNull "$id" "Error running execute-statement"

  status="SUBMITTED"
  while [ "$status" != "FINISHED" ] && [ "$status" != "FAILED" ]
  do
    sleep 1
    status=`aws redshift-data describe-statement --id $id | jq -r .Status`
	notNull "$status" "Error running describe-statement"
  done
	if [ "$status" == "FAILED" ]; then
    aws redshift-data describe-statement --id $id
    return 1
  else
    echo $id:$status
  fi
}

files=`ls ${TMPDIR}/.${module}/*.whl`
for depname in `basename -s .whl $files`
do
	#depname=${file%.*}
 	#depname=`basename -s .whl $file`
	echo $depname
	aws s3 cp "$TMPDIR/.$module/$depname.whl" "$s3Prefix/$depname.zip"
	sql="CREATE OR REPLACE LIBRARY ${depname%%-*} LANGUAGE plpythonu FROM '$s3Prefix/$depname.zip' WITH CREDENTIALS AS 'aws_iam_role=$s3Role'; "
	execQuery $cluster $db $user "$sql"
	if [ $? != 0 ]; then
		rm -Rf "$TMPDIR/.$module"
		exit $?
	fi
done

rm -Rf "$TMPDIR/.$module"
cd - &> /dev/null

exit 0
