/*
Purpose: This function will extract from the user_agent string. This function demos packaging of an external library. 

2021-08-08: written by rjvgupta
*/
--
CREATE OR REPLACE FUNCTION f_ua_parser_family (ua VARCHAR)
RETURNS VARCHAR IMMUTABLE AS $$
  from ua_parser import user_agent_parser
  return user_agent_parser.ParseUserAgent(ua)['family']
$$ LANGUAGE plpythonu;
