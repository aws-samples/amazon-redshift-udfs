# Pip Library Installer

In this directory you'll find a shell script which allows you to prepare a pip module for installation into your Redshift database. Modules that you require are installed into a separate directory (within this tool) and cleaned up after preparation. The module itself is collected as a pip wheel, which includes all of the required dependencies for that module. Once done, it is exported to the location on S3 that you specify and the `CREATE LIBRARY` statement is generated for your convenience.

## Pre-requisites

In order to run this module, you need to have python, pip, and the AWS command line interface installed. Pip also needs to have `wheel` installed.

## Running the installer

To run the installer simply execute:

```
./installPipModuleAsRedshiftLibrary.sh -m <module> -s <upload prefix> -r <region>

where <module> is the name of the Pip module to be installed
      <upload prefix> is the location on S3 to upload the artifact to. Must be in format s3://bucket/prefix/
      <region> is the optional region where the S3 bucket was created
```

## What's it doing?

Redshift requires that a Library to be installed for use in a User Defined Function be zipped, so the default pip and wheel format doesn't work. Furthermore, to successfully use a module within your Redshift database, you have to have all the dependent modules that pip uses also installed. If you tried to load modules yourself, you'd have to dig through your pip repository, follow the dependency trees manually, and then zip up the required files and install them by hand. This script uses `pip wheel` to generate a single binary file with all the required dependencies, which is not installed into your pip repository, but into a local directory within this tool. It then zips the `.whl` file up and exports it to S3, and finally generates a `CREATE LIBRARY` statement that points to the location on S3 that you've supplied.
