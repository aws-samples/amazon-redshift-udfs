/*
Purpose: This function will uses Levenshtein Distance to calculate the differences between sequences.

2022-08-14: written by saeedsb
*/
--
CREATE OR REPLACE FUNCTION fuzzy_test (string_a VARCHAR,string_b VARCHAR) 
RETURNS FLOAT IMMUTABLE AS $$
  from thefuzz import fuzz 
  
  return fuzz.ratio (string_a,string_b) 
$$ LANGUAGE plpythonu;