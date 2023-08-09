create or replace external function fn_lambda_levenshtein_distance(a varchar, b varchar) returns int 
lambda 'fn_lambda_levenshtein_distance' iam_role ':RedshiftRole' immutable retry_timeout 0 MAX_BATCH_SIZE 1024;
