WITH acl AS (
  SELECT unnest( relacl::text[] ) AS acl
  FROM pg_class
  WHERE relname = 'products'
)
, split_acl AS (
   SELECT acl, position( '=' in acl ) AS equal_at,
          substring( acl from 1 for position( '=' in acl ) - 1 ) AS granted_to,
          substring( acl from position( '=' in acl ) + 1 for position( '/' in acl )
                  - position( '=' in acl ) - 1 ) AS granted_what,
          substring( acl from position( '/' in acl ) + 1 ) AS grantee
   FROM acl
)
, decode_acl AS (
  SELECT
     ''
     ||
     CASE WHEN position( 'r' in granted_what ) > 0 THEN ' SELECT ' END
     ||
     CASE WHEN position( 'd' in granted_what ) > 0 THEN ' DELETE ' END
     ||
     CASE WHEN position( 'D' in granted_what ) > 0 THEN ' TRUNCATE ' END
     AS granted_statements
   , *
 FROM split_acl
)

SELECT *
FROM decode_acl;
