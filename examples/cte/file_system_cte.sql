BEGIN;

CREATE TABLE file_system
(
  pk serial PRIMARY KEY,
  name text NOT NULL,
  is_dir bool DEFAULT false,
  parent_of int[],

  UNIQUE (name, is_dir)
);

CREATE OR REPLACE FUNCTION insert_fs_entry( entry text DEFAULT '',
                                            is_directory BOOL DEFAULT false )
RETURNS bool
AS $CODE$
DECLARE
  path_parts text[];
  current_pk int;
  last_pk    int;
  index    int := 0;
BEGIN

  IF substring( entry FROM 1 FOR 1 ) <> '/' THEN
     entry := '/' || entry;
  END IF;

  path_parts = string_to_array( entry, '/' );
  RAISE DEBUG 'Entry is [%]', entry;
  RAISE DEBUG 'Path parts [%]', path_parts;
  RAISE DEBUG 'Pieces [%]', array_upper( path_parts, 1 );


  index := array_upper( path_parts, 1 );
   WHILE index > 0 LOOP
      current_pk := nextval( 'file_system_pk_seq' );
      RAISE DEBUG 'Entry [%] with key [%] parent of [%]',
                   path_parts[ index ],
                   current_pk,
                   last_pk;

      INSERT INTO file_system( pk, name, is_dir, parent_of )
      VALUES( current_pk, path_parts[ index ], is_directory, ARRAY[ last_pk ]::int[] )
      ON CONFLICT ( name, is_dir )
         DO UPDATE SET parent_of = EXCLUDED.parent_of || file_system.parent_of;

      IF NOT is_directory THEN
         is_directory := true;
      END IF;

      index := index - 1;
      last_pk := current_pk;

  END LOOP;
  return true;
END
$CODE$
LANGUAGE plpgsql;
