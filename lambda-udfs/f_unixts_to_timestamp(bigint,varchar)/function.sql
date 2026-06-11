/*
Purpose: Converts a UNIX timestamp to a UTC datetime with up to microseconds granularity.

2015-09-10: written by chriz@
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_unixts_to_timestamp(bigint, varchar) RETURNS timestamp STABLE
LAMBDA 'f-unixts-to-timestamp-bigint-varchar' IAM_ROLE ':RedshiftRole';
