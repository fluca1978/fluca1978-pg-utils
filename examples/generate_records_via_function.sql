/*
> \d persona
Table "public.persona"
Column          |            Type             |
----------------+-----------------------------+--
pk              | integer                     |
cognome         | text                        |
nome            | text                        |
codice_fiscale  | text                        |
sesso           | character(1)                |
ts              | timestamp without time zone |

*/

CREATE OR REPLACE FUNCTION generate_persona( l int DEFAULT 10 )
RETURNS SETOF persona
AS $body$
DECLARE
  i int;
  current_row persona%rowtype;
BEGIN
  FOR i in 1..l LOOP
      current_row.pk := nextval( 'persona_pk_seq' );
      current_row.cognome := 'Cognome ' || i;
      current_row.nome    := 'Nome ' || i;
      IF i % 2 = 0 THEN
         current_row.sesso := 'M';
      ELSE
        current_row.sesso := 'k';
      END IF;
      current_row.ts := CURRENT_TIMESTAMP + '1 day 3 hours';
      current_row.codice_fiscale := substring( md5( random()::text ) from 1 for 16 );
      RETURN NEXT current_row;
  END LOOP;
  RETURN;
END
$body$
LANGUAGE plpgsql;





CREATE OR REPLACE FUNCTION plperl_generate_persona( l int DEFAULT 10 )
RETURNS SETOF persona
AS $PERL$
  my ( $limit ) = @_;
  $limit = 10 if ( ! $limit || $limit <= 0 );
  my @chars = ('A'..'Z', 0..9);

  for my $index ( 1 .. $limit ){
      my $pk = spi_exec_query( q/ SELECT nextval( 'persona_pk_seq' ) / )->{ rows }[ 0 ]->{ nextval };
      my %current_row;
      $current_row{ ts } = localtime;

      $current_row{ codice_fiscale } .= $chars[ rand @chars ] for ( 0..16 );
      $current_row{ sesso }           = ( $index % 2 == 0 ? 'M' : 'F' );
      $current_row{ pk }              = $pk;
      $current_row{ cognome }         = "Cognome $index";
      $current_row{ nome }            = "Nome $index";
      return_next( \%current_row );
  }

  # ends the return_next
  return undef();


$PERL$
LANGUAGE plperl;
