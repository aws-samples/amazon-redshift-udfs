#!/bin/bash
#set -x 

# Install Pip Module as Redshift Library

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
while getopts "m:s:r:e:" opt; do
	case $opt in
		m) module="$OPTARG";;
		s) s3Prefix="$OPTARG";;
		r) region="$OPTARG";;
		\?) echo "Invalid option: -"$OPTARG"" >&2
			exit 1;;
		:) echo "Option -"$OPTARG" requires an argument." >&2
			exit 1;;
	esac
done

# validate arguments
notNull "$module" "Please provide the pip module name using --m"
notNull "$s3Prefix" "Please provide an S3 Prefix to store the library in using --s"

# check if this is a valid module in pip
pip search $module &> /dev/null 

if [ $? -ne 0 ]; then
	echo "Unable to find module $module in pip."
	exit -1
fi

# check the s3 prefix exists already
aws s3 ls $s3Prefix &> /dev/null

if [ $? -ne 0 ]; then
	echo "Invalid S3 Prefix $s3Prefix"
	exit -1
fi

# found the module - install to a local hidden directory
echo "Installing $module with pip and uploading to $s3Prefix"

rm -Rf ".$module" &> /dev/null

mkdir ".$module"

pip wheel $module --wheel-dir ".$module"

cd ".$module"

wheelFile=`find . -name *.whl`
zip $module.zip $wheelFile

aws s3 cp $module.zip $s3Prefix/$module.zip

echo
echo "Packaging Complete. Please run the following CREATE LIBRARY command in your Redshift database to use this module"
echo

libStmt="CREATE LIBRARY $module\nLANGUAGE plpythonu\nfrom '$s3Prefix/$module.zip'\nWITH CREDENTIALS AS 'aws_access_key_id=<key_id>;aws_secret_access_key=<secret>'\n"

if [ "$region" != "" ]; then
	libStmt="$libStmt region $region\n"
fi

echo -e $libStmt

cd ..
rm -Rf ".$module" &> /dev/null

exit 0