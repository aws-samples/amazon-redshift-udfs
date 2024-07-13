#!/bin/bash
set -e
# Install Pip Module as Redshift Library

function usage {
	echo "./layerInstaller.sh -s <s3 location> -r <requirement> -f <UDF name> -p <python version> "
	echo
	echo "where <s3 location> is the prefix of the location on S3 to upload the artifact to. Must be in format s3://bucket/prefix"
	echo "      <requirement> is the dependency requirement (e.g. boto3>=1.29.0)"
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
		r) requirement="$OPTARG";;
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
notNull "$requirement" "Please provide the dependency requirement (e.g. boto3>=1.29.0) with -r"
notNull "$s3Path" "Please provide an S3 key to store the library in using -s"
notNull "$function" "Please provide the function name using -f"

echo $requirement
echo $s3Path
echo $function
echo $python_version

if [ -z "${python_version}" ]; then
	python_version="3.9"
fi
dependencyName=$(echo "${requirement}" | sed 's/[<=>]/ /g' | awk '{print $1}')
dependencyVersion=$(echo "${requirement}" | sed 's/[<=>]/ /g' | awk '{print $2}')
notNull "${dependencyName}" "Invalid requirement: ${requirement}. Expected format: 'NAME[>=<]*[0-9\.]*'"
archiveName="${s3Path}/${dependencyName}.zip"
if [ ! -z "${dependencyVersion}" ]; then 
	archiveName="${s3Path}/${dependencyName}_${dependencyVersion}.zip"
fi

TMPDIR=.tmp
if [ ! -d "$TMPDIR" ]; then
  mkdir $TMPDIR
  chmod 2755 $TMPDIR
fi
cd "${TMPDIR}"

echo "Building Lambda layer inside Docker container..."
mkdir -p "python/lib/python${python_version}/site-packages"
echo "${requirement}" > requirements.txt
export UID
docker run \
    -v "$PWD":/var/task \
	--user $UID:$UID \
    "public.ecr.aws/sam/build-python${python_version}" \
    /bin/sh \
	-c "pip install --upgrade pip" \
    -c "pip install -r requirements.txt -t python/lib/python${python_version}/site-packages/; exit"

echo "Built, zipping layer contents..."
zip -r "${function}.zip" python > /dev/null
cd -

echo "Zipped, publishing to ${archiveName}..."
aws s3 cp "${TMPDIR}/${function}.zip" "${archiveName}"

echo "Published, cleaning up..."
rm -rf "${TMPDIR}"

echo "Complete."