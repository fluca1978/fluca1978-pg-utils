set -e
psql -U postgres -c "create role pgbench with login password 'PgGench!';" postgres
psql -U postgres -c "create database pgbench with owner pgbench;" postgres

pgbench -i -U pgbench pgbench
