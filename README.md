# amazon-redshift-udfs
A collection of example User Defined Functions and Utilities for Amazon Redshift.

## Contents

This project is divided into several areas: the `bin` directory contains utilies related to working with User Defined Functions. This includes the PipLibraryInstaller, which prepares Pip libraries, with their associated dependencies, for installation into a Redshift Database.

The `lib` folder contains libraries that we've built for your use and as a starting point for new applications. Today, this includes *pyaes* for performing AES encryption, and *SubstitutionMasking* for performing simple data masking.

Finally, the `scalar-udfs` folder includes functions that you can install into your Redshift database and use right away.

## Contributing

We would love to receive your pull requests for new functionality!