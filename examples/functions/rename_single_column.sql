/**
 * A function to massively rename a column on a set of tables.
 * This helps when the generation of a column has been done automatically but with the wrong name.
 * The function performs a 'straight' rename, that is without any suffix or table related stuff.
 *
 * \param src_column the name of the column to be renamed
 * \param dst_column the name that the column will assume
 * \param schemaz the schema to work within, defaults to public
 *
 * \returns the text for the alter table to execute
 *
 * For instance:
 testdb=> SELECT * FROM f_rename_single_column( 'pl', 'pk', 'myschema' );

 DEBUG:  Table [tbl_one] has column [pl]
 DEBUG:   -> ALTER TABLE myschema.tbl_one RENAME COLUMN pl TO pk;
 DEBUG:  Table [tbl_two] has column [pl]
 DEBUG:   -> ALTER TABLE myschema.tbl_two RENAME COLUMN pl TO pk;

 ALTER TABLE myschema.tbl_one RENAME COLUMN pl TO pk;
 ALTER TABLE myschema.tbl_two RENAME COLUMN pl TO pk;

*/
CREATE OR REPLACE FUNCTION f_rename_single_column( src_column text,
                                                   dst_column text,
                                                   schemaz text DEFAULT 'public' )
RETURNS SETOF text
AS $CODE$
DECLARE
  current_class pg_class%rowtype;
  current_alter_table text;
BEGIN

  -- check arguments
  IF src_column IS NULL OR src_column = '' THEN
     RAISE EXCEPTION 'You must specify a column to rename!';
  END IF;

  IF dst_column IS NULL OR dst_column = '' THEN
     RAISE EXCEPTION 'You must specify the new name!';
  END IF;

  RAISE DEBUG 'Searching for tables with column [%] in schema [%]', src_column, schemaz;

  FOR current_class IN SELECT c.* FROM pg_class c
                       JOIN pg_namespace n ON n.oid      = c.relnamespace
                       JOIN pg_attribute a ON a.attrelid = c.oid
                       WHERE n.nspname = schemaz
                       AND   c.relkind = 'r'
                       AND   a.attname = src_column

  LOOP
    RAISE DEBUG 'Table [%] has column [%]', current_class.relname, src_column;

    current_alter_table := format( 'ALTER TABLE %I.%I RENAME COLUMN %I TO %I;',
                                   schemaz,
                                   current_class.relname,
                                   src_column,
                                   dst_column );

   RAISE DEBUG ' -> %', current_alter_table;
   RETURN NEXT current_alter_table;
  END LOOP;

  RETURN;

END
$CODE$
LANGUAGE plpgsql;


/**
 * A procedure to invoke immediatly the f_rename_single_column.
 */
CREATE OR REPLACE PROCEDURE p_rename_single_column( src_name text,
                                                    dst_name text,
                                                    schemaz text DEFAULT 'public',
                                                    commit_after int DEFAULT 10 )
AS $CODE$
DECLARE
  current_alter_table text;
  done int := 0;
BEGIN
  FOR current_alter_table IN SELECT f_rename_single_column( src_name, dst_name, schemaz )
  LOOP
    RAISE DEBUG 'Executing [%]', current_alter_table;
    EXECUTE current_alter_table;
    done := done + 1;


    IF done % commit_after = 0 THEN
       RAISE DEBUG 'Forcing a commit';
       COMMIT;
    END IF;

  END LOOP;
  RAISE DEBUG 'Altered % tables in schema %', done, schemaz;
  COMMIT;
END
$CODE$
LANGUAGE plpgsql;
