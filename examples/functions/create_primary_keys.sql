/*
 * A function to generate a few ALTER TABLE statements in order to add
 * primary keys (surrogated, of course) to tables that do not
 * have such constraints.
 *
 * \param schemaz the schema in which look for wrong tables (default 'public')
 * \param pk_prefix the name or prefix of the column to be used as primary key (default 'pk')
 * \param use_identity true if you want to use 'GENERATED ALWAYS AS IDENTITY' or false to use 'serial'
 * \param append_table_name true if you want the column to be named pk_prefix + table-name (to avoid name clashes)
 *
 * \returns each row of alter table
 *
 *
 * Example of invocation:
 # select * from f_generate_primary_keys( 'public', 'miao', true, false );
 DEBUG:  Table [foo] without primary key
 DEBUG:   -> ALTER TABLE public.foo ADD COLUMN miao int NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY;
 DEBUG:  Table [bar] without primary key
 DEBUG:   -> ALTER TABLE public.bar ADD COLUMN miao int NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY;
                            f_generate_primary_keys
 -----------------------------------------------------------------------------------------------
 ALTER TABLE public.foo ADD COLUMN miao int NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY;
 ALTER TABLE public.bar ADD COLUMN miao int NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY;

 * To use this function to actually change the data do something like:
 % psql -U luca -h miguel -c 'SELECT * FROM f_generate_primary_keys();' -A -t -o script.sql testdb

and check the script.sql, then execute it as a normal script:

% psql -U luca -h miguel -f script.sql testdb
 */
CREATE OR REPLACE FUNCTION f_generate_primary_keys( schemaz text DEFAULT 'public',
                                                    pk_prefix text DEFAULT 'pk',
                                                    use_identity boolean DEFAULT true,
                                                    append_table_name boolean DEFAULT false )
RETURNS SETOF text
AS $CODE$
DECLARE
  current_class pg_class%rowtype;
  current_alter_table text;
  current_pk_type text;
  current_pk_generation text;
  current_pk_name text;
BEGIN

  FOR current_class IN SELECT c.* FROM pg_class c
                       JOIN pg_namespace n ON n.oid = c.relnamespace
                       WHERE n.nspname = schemaz
                       AND   c.relkind = 'r'
                       AND NOT EXISTS ( SELECT conname FROM pg_constraint
                                        WHERE contype = 'p'
                                        AND conrelid = c.oid )

  LOOP
    RAISE DEBUG 'Table [%] without primary key', current_class.relname;

    current_pk_name := pk_prefix;
    IF append_table_name THEN
       current_pk_name := current_pk_name || '_' || current_class.relname;
    END IF;

    IF NOT use_identity THEN
       current_pk_type       := 'serial';
       current_pk_generation := '';
    ELSE
      current_pk_type       := 'int';
      current_pk_generation := 'GENERATED ALWAYS AS IDENTITY';
    END IF;



    current_alter_table := format( 'ALTER TABLE %I.%I ADD COLUMN %I %s NOT NULL %s PRIMARY KEY;',
                                   schemaz,
                                   current_class.relname,
                                   current_pk_name,
                                   current_pk_type,
                                   current_pk_generation );

   RAISE DEBUG ' -> %', current_alter_table;
   RETURN NEXT current_alter_table;
  END LOOP;

  RETURN;

END
$CODE$
LANGUAGE plpgsql;


/*
 * A procedure to automatically add primary keys using dynamic alter table statements.
 * The procedure invokes the f_generate_primary_keys function and commits every change
 * on a batch processing.
 *
 *
 * \param schemaz the schema in which look for wrong tables (default 'public')
 * \param pk_prefix the name or prefix of the column to be used as primary key (default 'pk')
 * \param use_identity true if you want to use 'GENERATED ALWAYS AS IDENTITY' or false to use 'serial'
 * \param append_table_name true if you want the column to be named pk_prefix + table-name (to avoid name clashes)
 * \param commit_after the number of `ALTER TABLE` to issue before forcing a commit
 *
 *
 * Example of invocation:
testdb=# call p_generate_primary_keys( 'public', 'id', false, true );
DEBUG:  Table [foo] without primary key
DEBUG:   -> ALTER TABLE public.foo ADD COLUMN id_foo serial NOT NULL  PRIMARY KEY;
DEBUG:  Table [bar] without primary key
DEBUG:   -> ALTER TABLE public.bar ADD COLUMN id_bar serial NOT NULL  PRIMARY KEY;
DEBUG:  Executing [ALTER TABLE public.foo ADD COLUMN id_foo serial NOT NULL  PRIMARY KEY;]
DEBUG:  ALTER TABLE will create implicit sequence "foo_id_foo_seq" for serial column "foo.id_foo"
DEBUG:  ALTER TABLE / ADD PRIMARY KEY will create implicit index "foo_pkey" for table "foo"
DEBUG:  rewriting table "foo"
DEBUG:  building index "foo_pkey" on table "foo" serially
DEBUG:  Executing [ALTER TABLE public.bar ADD COLUMN id_bar serial NOT NULL  PRIMARY KEY;]
DEBUG:  ALTER TABLE will create implicit sequence "bar_id_bar_seq" for serial column "bar.id_bar"
DEBUG:  ALTER TABLE / ADD PRIMARY KEY will create implicit index "bar_pkey" for table "bar"
DEBUG:  rewriting table "bar"
DEBUG:  building index "bar_pkey" on table "bar" serially
DEBUG:  Altered 2 tables in schema public
LOG:  duration: 16.224 ms  statement: call p_generate_primary_keys( 'id', 'public', false, true );
CALL

 */
CREATE OR REPLACE PROCEDURE p_generate_primary_keys( schemaz text DEFAULT 'public',
                                                     pk_prefix text DEFAULT 'pk',
                                                     use_identity boolean DEFAULT true,
                                                     append_table_name boolean DEFAULT false,
                                                     commit_after int DEFAULT 10 )
AS $CODE$
DECLARE
  current_alter_table text;
  done int := 0;
BEGIN
  FOR current_alter_table IN SELECT f_generate_primary_keys( pk_prefix, schemaz, use_identity, append_table_name )
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
