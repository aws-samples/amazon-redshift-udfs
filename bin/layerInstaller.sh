#!/bin/bash
set -e
# Install Pip Module as Redshift Library

function usage {
	echo "./layerInstaller.sh -s <s3 location> -r <requirements file path> -f <UDF name> -p <python version> "
	echo
	echo "where <s3 location> is the location on S3 to upload the artifact to. Must be in format s3://bucket/key"
	echo "      <requirements file path> is the path to the requirements.txt file"
	echo "      <UDF name> is the name of the UDF"
	echo "      <python version> is Python version to build for (defaults to 3.9)"
	exit 0;
}


function notNull {
	if [ "$1x" == "x" ]; then
		echo $2
		exit -1
	fi
}

# make sure we have Docker installed
docker images &> /dev/null
if [ $? != 0 ]; then
  echo "docker not found or not running. Please install docker to continue"
  exit -1
fi

# look up runtime arguments of the module name and the destination S3 Prefix
while getopts "r:s:f:h:p" opt; do
	case $opt in
		r) requirements="$OPTARG";;
		s) s3Path="$OPTARG";;
		f) function="$OPTARG";;
		p) python_version="$OPTARG";;
		h) usage;;
		\?) echo "Invalid option: -"$OPTARG"" >&2
			exit 1;;
		:) usage;;
	esac
done

# validate arguments
notNull "$requirements" "Please provide the path to the requirements.txt file with -r"
notNull "$s3Path" "Please provide an S3 key to store the library in using -s"
notNull "$function" "Please provide the function name using -f"
if [ -z "${python_version}" ]; then
	python_version="3.9"
fi

echo "Building Lambda layer inside Docker container..."
mkdir -p "python/lib/python${python_version}/site-packages"
cp "${requirements}" requirements.txt
docker run \
    -v "$PWD":/var/task \
    "public.ecr.aws/sam/build-python${python_version}" \
    /bin/sh \
    -c "pip install -r requirements.txt -t python/lib/python${python_version}/site-packages/; exit"

echo "Built, zipping layer contents..."
zip -r "${function}.zip" python > /dev/null

echo "Zipped, publishing to s3://${s3Path}..."
aws s3 cp "${function}.zip" "${s3Path}"

echo "Published, cleaning up..."
rm -r python/ "${function}.zip" requirements.txt

echo "Complete."