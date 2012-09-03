CREATE SCHEMA linuxmag_user;

-- remove all privileges to all other users
REVOKE ALL PRIVILEGES ON SCHEMA linuxmag_user FROM PUBLIC;

-- grant all privileges to the running user
GRANT ALL PRIVILEGES ON SCHEMA linuxmag_user TO linuxmag_user;

-- grant usage for the schema target of the functions
GRANT USAGE ON SCHEMA linuxmag TO linuxmag_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA linuxmag TO linuxmag_user;

-- create a wrapper function
CREATE OR REPLACE FUNCTION linuxmag_user.download_url( magazine_pk integer )
RETURNS text
AS
$BODY$
DECLARE
BEGIN
	RAISE LOG 'linuxmag_user.download_url()';
	RETURN linuxmag.download_url( magazine_pk );
	

END;
$BODY$
LANGUAGE plpgsql;

-- create a wrapper view for the magazine table
CREATE OR REPLACE VIEW linuxmag_user.magazine 
AS
SELECT *
FROM linuxmag.magazine;