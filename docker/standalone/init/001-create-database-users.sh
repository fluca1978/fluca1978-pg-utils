set -e
psql -U postgres -c "alter role postgres password 'P0stgres!!'" postgres
psql -U postgres -c "create role luca with login password  'luca' connection limit 1" postgres

psql -U postgres -c "create role book_authors with nologin;" postgres
psql -U postgres -c "create role forum_admins with nologin;" postgres
psql -U postgres -c "create role forum_stats with nologin;" postgres

psql -U postgres -c "grant book_authors to luca" postgres
psql -U postgres -c "grant forum_stats to luca" postgres
psql -U postgres -c "grant forum_admins to luca" postgres
