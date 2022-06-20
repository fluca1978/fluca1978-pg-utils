/*
 * Query to find out foreign keys that could require indexes.
 * Inspired by <https://www.cybertec-postgresql.com/en/index-your-foreign-key/>
 */
SELECT
        format( '%I.%I', n_src.nspname, c_src.relname ) AS src_table
        , format( '%I.%I', n_dst.nspname, c_dst.relname ) AS dst_table
        , fk.conname AS fk_name
        , pg_catalog.pg_size_pretty( pg_catalog.pg_table_size( c_src.oid ) ) AS src_table_size
        , pg_catalog.pg_size_pretty( pg_catalog.pg_table_size( c_dst.oid ) ) AS dst_table_size
        , string_agg( a_src.attname, ',' ORDER BY fk_from.n ) AS src_columns
        , string_agg( a_dst.attname, ',' ORDER BY fk_to.n ) AS dst_columns
        , format( '%I.%I', n_index.nspname, c_index.relname ) AS index_name
FROM
        pg_class c_src
        JOIN pg_namespace n_src ON n_src.oid = c_src.relnamespace
        JOIN pg_constraint fk ON fk.conrelid = c_src.oid
        CROSS JOIN LATERAL unnest( fk.conkey ) WITH ORDINALITY AS fk_from( attnum, n )
        JOIN pg_attribute a_src ON a_src.attnum = fk_from.attnum
                                AND a_src.attrelid = c_src.oid
        JOIN pg_class c_dst ON fk.confrelid = c_dst.oid
        JOIN pg_namespace n_dst ON n_dst.oid = c_dst.relnamespace
        CROSS JOIN LATERAL unnest( fk.confkey ) WITH ORDINALITY AS fk_to( attnum, n )
        JOIN pg_attribute a_dst ON a_dst.attnum = fk_to.attnum
                                AND a_dst.attrelid = c_dst.oid
        LEFT JOIN pg_index i_dst ON i_dst.indrelid = c_dst.oid
        LEFT JOIN pg_class c_index ON c_index.oid = i_dst.indexrelid
        LEFT JOIN pg_namespace n_index ON n_index.oid = c_index.relnamespace
WHERE
        -- skip catalogs
        n_src.nspname       NOT IN ( 'information_schema', 'pg_catalog', 'pg_toast' )
        AND n_dst.nspname   NOT IN ( 'information_schema', 'pg_catalog', 'pg_toast' )

        -- get only tables (r) and partitioned tables (p)
        AND  c_src.relkind IN ( 'r', 'p' )
        AND  c_dst.relkind IN ( 'r', 'p' )

        -- get only foreign keys
        AND fk.contype = 'f'

GROUP BY n_src.nspname, c_src.relname, fk.conname, c_src.oid, c_dst.oid, c_dst.relname, n_dst.nspname
      , n_index.nspname, c_index.relname
;
