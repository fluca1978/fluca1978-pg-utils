CREATE TABLE test( pk serial not null, description text, primary key(pk));

INSERT INTO test(pk) VALUES(generate_series(1,1000000 ) );

VACUUM FULL ANALYZE test;

EXPLAIN SELECT * FROM test WHERE pk = 1;

