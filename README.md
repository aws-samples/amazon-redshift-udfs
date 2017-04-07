# Amazon Redshift UDFs
A collection of example user-defined functions (UDFs) and utilities for Amazon Redshift.

## Contents

This project is divided into several areas: 

- `bin/` 

Contains utilies related to working with UDFs. This includes the PipLibraryInstaller, which prepares Pip libraries, with their associated dependencies, for installation into an Amazon Redshift database.

- `lib/` 

Contains libraries that we've provided for your use and as a starting point for new applications. Today, this includes *SubstitutionMasking* for performing simple data masking.

- `scalar-udfs/` 

Contains SQL to create example UDFs that you can either modify or directly install into your Amazon Redshift database.

- `views/` 

Contains CREATE VIEW DDL that can be queried to simplify administration of UDFs.

## Contributing

We would love to receive your pull requests for new functionality!
