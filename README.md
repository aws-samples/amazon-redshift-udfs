# Amazon Redshift UDFs
A collection of example user-defined functions (UDFs) and utilities for Amazon Redshift. The intent of this collection is to provide examples for defining python UDFs, but the UDF examples themselves may not be optimal to achieve your requirements.

## Contents

This project is divided into several areas: 

- `bin/` 

Contains utilies related to working with UDFs. This includes the PipLibraryInstaller, which prepares Pip libraries, with their associated dependencies, for installation into an Amazon Redshift database.

- `scalar-udfs/` 

Contains SQL to create example UDFs that you can either modify or directly install into your Amazon Redshift database.

- `views/` 

Contains CREATE VIEW DDL that can be queried to simplify administration of UDFs.

## Contributing

We would love to receive your pull requests for new functionality!
