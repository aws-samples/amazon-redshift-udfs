/*
Purpose: This function use numpy to determine the similary between two vectors. 

2021-08-08: written by rjvgupta
*/
--
CREATE OR REPLACE FUNCTION f_cosine_similarity (v1 VARCHAR, v2)
RETURNS VARCHAR IMMUTABLE AS $$
  import numpy as np
  from numpy.linalg import norm
  A = np.array(json.loads(v1))
  B = np.array(json.loads(v2))
  return np.dot(A,B)/(norm(A)*norm(B))
$$ LANGUAGE plpythonu;
