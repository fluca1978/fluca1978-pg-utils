set -e
psql -U postgres -c "alter role postgres password 'P0stgres!!'" postgres
psql -U postgres -c "create role luca with login password  'luca' connection limit 1" postgres

