
CREATE SCHEMA rewind;

CREATE OR REPLACE FUNCTION
  rewind.can_pg_rewind( checking_role_name text DEFAULT CURRENT_ROLE::text,
                        hint_grants boolean DEFAULT true )
  RETURNS boolean
AS
  $CODE$
  DECLARE
  is_super                 boolean := false;
  can_ls                   boolean := false;
  can_stat_file            boolean := false;
  can_read_binary          boolean := false;
  can_read_binary_override boolean := false;

  function_ls   text                 := 'pg_catalog.pg_ls_dir(text, boolean, boolean)';
  function_stat text                 := 'pg_catalog.pg_stat_file(text, boolean)';
  function_read_binary          text := 'pg_catalog.pg_read_binary_file(text)';
  function_read_binary_override text := 'pg_catalog.pg_read_binary_file(text, bigint, bigint, boolean)';

  grant_hints text;
BEGIN

  -- if the user is a superuser
  -- she can do whatever
  SELECT
    rolsuper
    , has_function_privilege( checking_role_name, function_ls, 'EXECUTE' )
    , has_function_privilege( checking_role_name, function_stat, 'EXECUTE' )
    , has_function_privilege( checking_role_name, function_read_binary, 'EXECUTE' )
    , has_function_privilege( checking_role_name, function_read_binary_override, 'EXECUTE' )
    FROM pg_roles
    INTO is_super, can_ls, can_stat_file, can_read_binary, can_read_binary_override
   WHERE rolname = checking_role_name;

  RAISE DEBUG 'Role % is superuser %', checking_role_name, is_super;
  RAISE DEBUG 'Role % can execute pg_ls_dir ? %', checking_role_name, can_ls;
  RAISE DEBUG 'Role % can execute pg_stat_file ? %', checking_role_name, can_stat_file;
  RAISE DEBUG 'Role % can execute pg_read_binary ? % and %', checking_role_name, can_read_binary, can_read_binary_override;

  IF hint_grants AND NOT is_super THEN

    IF NOT can_ls THEN
      RAISE INFO 'GRANT EXECUTE ON FUNCTON % TO %;', function_ls, checking_role_name;
    END IF;
    IF NOT can_stat_file THEN
      RAISE INFO 'GRANT EXECUTE ON FUNCTON % TO %;', function_stat, checking_role_name;
    END IF;
    IF NOT can_read_binary THEN
      RAISE INFO 'GRANT EXECUTE ON FUNCTON % TO %;', function_read_binary, checking_role_name;
    END IF;
    IF NOT can_read_binary_override THEN
      RAISE INFO 'GRANT EXECUTE ON FUNCTON % TO %;', function_read_binary_override, checking_role_name;
    END IF;
  END IF;


  RETURN is_super OR ( can_ls AND can_stat_file AND can_read_binary );
END
  $CODE$
  LANGUAGE plpgsql;
