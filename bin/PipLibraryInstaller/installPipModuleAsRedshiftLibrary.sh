#!/bin/bash
#set -x 

# Install Pip Module as Redshift Library

function usage {
	echo "./installPipModuleAsRedshiftLibrary.sh -m <module> -s <upload prefix> -r <region>"
	echo
	echo "where <module> is the name of the Pip module to be installed"
	echo "      <upload prefix> is the location on S3 to upload the artifact to. Must be in format s3://bucket/prefix/"
	echo "      <region> is the optional region where the S3 bucket was created"
	echo
	
	exit 0;
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
checkDep "pip"

# make sure we have wheel installed into pip
pip show wheel &> /dev/null
if [ $? != 0 ]; then
  echo "pip wheel not found. Please install with 'sudo pip install wheel'"
  exit -1
fi

# look up runtime arguments of the module name and the destination S3 Prefix
while getopts "m:s:r:h" opt; do
	case $opt in
		m) module="$OPTARG";;
		s) s3Prefix="$OPTARG";;
		r) region="$OPTARG";;
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

# ends with slash
if ! [[ $s3Prefix =~ .*\/$ ]]; then
	s3Prefix="$s3Prefix/"
fi

# check if this is a valid module in pip
pip search $module &> /dev/null 

if [ $? -ne 0 ]; then
	echo "Unable to find module $module in pip."
	exit -1
fi

# found the module - install to a local hidden directory
echo "Installing $module with pip and uploading to $s3Prefix"

rm -Rf "$TMPDIR/.$module" &> /dev/null

mkdir "$TMPDIR/.$module"

pip wheel $module --wheel-dir "$TMPDIR/.$module"

if [ $? != 0 ]; then
	rm -Rf "$TMPDIR/.$module"
	exit $?
fi

cd "$TMPDIR/.$module"

wheelFile=`find . -name *.whl`
zipFile=$module.zip
mv $wheelFile $zipFile

aws s3 cp $zipFile $s3Prefix$zipFile

if [ $? != 0 ]; then
	rm -Rf "$TMPDIR/.$module"
	exit $?
fi

echo "
Packaging Complete. Please run the following CREATE LIBRARY command in your Redshift database to use this module

CREATE LIBRARY $module
LANGUAGE plpythonu
from '$s3Prefix$zipFile'
WITH CREDENTIALS AS 'aws_access_key_id=<key_id>;aws_secret_access_key=<secret>'"

if [ "$region" != "" ]; then
	echo "region $region"
fi

rm -Rf "$TMPDIR/.$module"
cd - &> /dev/null

exit 0