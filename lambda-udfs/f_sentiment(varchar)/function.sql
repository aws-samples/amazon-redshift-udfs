/*
Purpose: This function will return the sentiment of a text field using the nltk library.

2023-09-29: written by rjvgupta
2025-06-30: migrated to Lambda UDF
*/
CREATE OR REPLACE EXTERNAL FUNCTION f_sentiment(varchar) RETURNS varchar IMMUTABLE
LAMBDA 'f-sentiment-varchar' IAM_ROLE ':RedshiftRole';
