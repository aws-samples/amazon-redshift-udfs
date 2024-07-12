/*
Purpose: This function use numpy to determine the similary between two vectors. 

2021-08-08: written by rjvgupta
*/
--
CREATE OR REPLACE FUNCTION f_cosine_similarity (v1 VARCHAR(MAX), v2 VARCHAR(MAX))
RETURNS FLOAT8 IMMUTABLE AS $$
  import numpy,json
  from numpy.linalg import norm
  A = numpy.array(json.loads(v1))
  B = numpy.array(json.loads(v2))
  return numpy.dot(A,B)/(norm(A)*norm(B))
$$ LANGUAGE plpythonu;
