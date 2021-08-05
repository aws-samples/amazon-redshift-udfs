-- set up a UDF for what you want extracted from the user_agent
CREATE OR REPLACE FUNCTION parse_ua_family (ua VARCHAR)
RETURNS VARCHAR IMMUTABLE AS $$
  from ua_parser import user_agent_parser
  return user_agent_parser.ParseUserAgent(ua)['family']
$$ LANGUAGE plpythonu;
