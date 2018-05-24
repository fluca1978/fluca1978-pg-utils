

-- create the group
CREATE ROLE stock_app WITH LOGIN CONNECTION LIMIT 0;
-- roles
CREATE ROLE boss   WITH LOGIN CONNECTION LIMIT 1 PASSWORD 'boss' IN ROLE stock_app;
CREATE ROLE user_a WITH LOGIN CONNECTION LIMIT 1 PASSWORD 'au'   IN ROLE stock_app;
CREATE ROLE user_b WITH LOGIN CONNECTION LIMIT 1 PASSWORD 'bu'   IN ROLE stock_app;


CREATE TABLE products (
       pk          integer     GENERATED ALWAYS AS IDENTITY,
       id          text,
       description text,
       managed_by  text,
       price       money DEFAULT 0,
       qty         int   DEFAULT 1,
       ts          timestamp DEFAULT CURRENT_TIMESTAMP,

       UNIQUE ( id, managed_by ),
       CHECK  ( qty >= 0 ),
       CHECK  ( price >= 0::money )
);


-- populate
INSERT INTO products( id, description, managed_by, qty, price )
SELECT
 pnum
, 'Article nr.' || pnum
, CASE WHEN pnum % 2 = 0 THEN 'user_a'
       ELSE 'user_b'
  END
, abs( random() * 1234 )::int
, abs( random() * 100 )::decimal::money
FROM generate_series( 1, 1000 ) AS pnum;

-- permissions
REVOKE ALL ON products FROM PUBLIC;
GRANT ALL ON products TO boss;
GRANT SELECT( id, description, qty ) ON products TO user_a;
GRANT SELECT( id, description, qty ) ON products TO user_b;
GRANT INSERT, UPDATE ON products TO user_a;
GRANT INSERT, UPDATE ON products TO user_b;

CREATE POLICY products_policy
ON products
FOR ALL
USING ( managed_by = CURRENT_USER )
WITH CHECK ( price IS NOT NULL AND managed_by = CURRENT_USER );

CREATE POLICY products_boss_policy
ON  products
FOR ALL
USING ( CURRENT_USER = 'boss' )
WITH CHECK ( CURRENT_USER = 'boss' );

ALTER TABLE products ENABLE ROW LEVEL SECURITY;



CREATE TYPE p_stats AS (
  tot_qty   int,
  tot_count int,
  tot_price money
);

CREATE OR REPLACE FUNCTION f_products_stats()
RETURNS p_stats
AS
$BODY$
  DECLARE
    tot p_stats%rowtype;
  BEGIN
    SELECT  sum( qty )      AS q
            , count(id)     AS c
            , sum( price )  AS s
    INTO STRICT tot
    FROM products;

    RETURN tot;

  END
$BODY$
LANGUAGE plpgsql
SECURITY DEFINER;
