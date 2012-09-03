SELECT n.nspname, -- schema name
       c.relname, -- relation name
       c.oid,     -- relation oid
       pg_catalog.pg_table_is_visible( c.oid ) -- is the schema in the search path?
FROM pg_class c 
LEFT JOIN pg_catalog.pg_namespace n 
     ON n.oid = c.relnamespace 
WHERE c.relname = 'magazine'
ORDER BY n.nspname;