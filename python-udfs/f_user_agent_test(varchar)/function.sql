CREATE OR REPLACE FUNCTION f_user_agent_test (ua_string VARCHAR)
RETURNS VARCHAR
IMMUTABLE 
AS $$
from user_agents import parse
return ua_string
$$ LANGUAGE plpythonu
;
