# Set up PostgreSQL environment variables.
# Source this file into your shell.

# If you installed via the EDB interactive installer
# you should need to change only this line.
PG_INSTALLATION_DIR=/opt/PostgreSQL/10

PG_BIN=${PG_INSTALLATION_DIR}/bin
export PATH=${PG_BIN}:${PATH}

PGDATA=${PG_INSTALLATION_DIR}/data
export PGDATA
