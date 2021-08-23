create OR REPLACE function f_py_kafka_partitioner (s varchar, ps int) returns int
stable as $$
  import murmur2
  m2 = murmur2.murmur64a(s, len(s), 0x9747b28c)
  return m2 % ps
$$ language plpythonu;
