/*
 + An example to compute an italian codice fiscale
 * using plpgsql and plperl functions.
 *
 * All functions and data is placed into a specific schema to not pollute
 * ordinary data.
 *
 * In order to see debug messages:
 *
 * set client_min_messages to debug;
 *
 * To check the whole generator invoke cf.cf() function.
 * See <https://it.wikipedia.org/wiki/Codice_fiscale>
 */


BEGIN;

CREATE SCHEMA IF NOT EXISTS cf;

 /**
  * Computes the date string for a specific birth date and
  * gender.
  * Example of invocation:
  * SELECT cf.cf_date( '1978-7-19', true );
  * which produces:
  * 78L19
  */
CREATE OR REPLACE FUNCTION cf.cf_date( date,
                                       boolean DEFAULT false )
RETURNS char(5)
AS $CODE$
  my ( $birth_date, $female ) = @_;
  undef( $female ) if ( $female == 'f' );
  my ( $year, $month, $day ) = split /-/, $birth_date;
  $year =~ s/^(19|20)(\d{2})$/$2/;
  return sprintf '%02d%1s%02d',
  $year,
  ( 'A', 'B', 'C', 'D', 'E', 'H', 'L', 'M', 'P', 'Q', 'R', 'S', 'T' )[ $month - 1 ],
  $day + ( $female ? 40 : 0 );
$CODE$
LANGUAGE plperl;


/**
 * Computes the sequence of three chars for a name and/or surname.
 */
CREATE OR REPLACE FUNCTION cf.cf_letters( text,  bool DEFAULT false )
RETURNS char(3)
AS $BODY$
  my ($subject, $is_name) = ( lc( $_[ 0 ] ), $_[ 1 ] );

  # split the word into letters
  my @letters = split //, $subject;
  # grep out vowels and consonants
  my @consonants = grep { $_ !~ /[aeiou]/ } @letters;
  my @vowels     = grep { $_ =~ /[aeiou]/ } @letters;

  return join( '', $consonants[0], $consonants[2], $consonants[3] )  if ( $is_name && @consonants >= 4 );
  return join( '', @consonants[0..2] )  if ( @consonants >= 3 );
  return join( '', @consonants, @vowels[0 .. 3 - @consonants - 1] );
$BODY$
LANGUAGE plperl;


/**
 * Each birth-place has a specific code that has to be inserted into
 * the resulting string. In order to look up codes by place names,
 * use a simple table.
 */
CREATE TABLE IF NOT EXISTS cf.places( code char(4) PRIMARY KEY,
                                      description text NOT NULL,
                                      UNIQUE( description ),
                                      EXCLUDE( lower( trim( description ) ) WITH = ) );


TRUNCATE cf.places;

INSERT INTO cf.places( code, description )
VALUES
( 'F257', 'Modena' ),
( 'D711', 'Formigine' ),
( 'A944', 'Bologna' ),
( 'F357', 'Serramazzoni' );



/**
 * Translate a place name, case-insensitively, into
 * a code string. This is not a very strong alghoritm, since
 * it is based on text comparison...
 */
CREATE OR REPLACE FUNCTION cf.cf_place( text )
RETURNS char(4)
AS $CODE$
   my ($birth_place) = @_;

   my $query = "SELECT code FROM cf.places WHERE lower( '$birth_place' ) = lower( description ) ";
   my $result_set = spi_exec_query( $query , 1);
   return $result_set->{rows}[0]->{ code } if ( $result_set->{ rows } );
   return 'XXXX';

$CODE$
LANGUAGE plperl;


/**
 + In order to compute the checksum character
 * it is required to compute a sum based on the value of each
 * character and its position, odd or even.
 * This table contains all the values required to compute the sum.
 */
CREATE TABLE IF NOT EXISTS cf.check_chars( c char PRIMARY KEY,
                                           odd_value int NOT NULL,
                                           even_value int NOT NULL );
TRUNCATE TABLE cf.check_chars;

INSERT INTO cf.check_chars( c, odd_value, even_value )
VALUES
( '0', 1, 0 )
,( '1', 0, 1 )
,( '2', 5, 2 )
,( '3', 7, 3 )
,( '4', 9, 4 )
,( '5', 13, 5 )
,( '6', 15, 6 )
,( '7', 17, 7 )
,( '8', 19, 8 )
,( '9', 21, 9 )
,( 'A', 1, 0 )
,( 'B', 0, 1 )
,( 'C', 5, 2 )
,( 'D', 7, 3 )
,( 'E', 9, 4 )
,( 'F', 13, 5 )
,( 'G', 15, 6 )
,( 'H', 17, 7 )
,( 'I', 19, 8 )
,( 'J', 21, 9 )
,( 'K', 2, 10 )
,( 'L', 4 , 11 )
,( 'M', 18, 12 )
,( 'N', 20, 13 )
,( 'O', 11, 14 )
,( 'P', 3, 15 )
,( 'Q', 6, 16 )
,( 'R', 8, 17 )
,( 'S', 12, 18 )
,( 'T', 14, 19 )
,( 'U', 16, 20 )
,( 'V', 10, 21 )
,( 'W', 22, 22 )
,( 'X', 25, 23 )
,( 'Y', 24, 24 )
,( 'Z', 23, 25 );




/**
 + Compute the checksum character.
 */
CREATE OR REPLACE FUNCTION cf.cf_check( subject char(15) )
RETURNS char
AS $BODY$
  my ($subject) = @_;
  my ($odd_sum, $even_sum) = (0,0);
  my $index = 0;
  my $query;
  my $final_value;


  for ( split //, $subject ) {
    $index++;
    $query = sprintf( "SELECT odd_value, even_value FROM cf.check_chars WHERE c = '%s'", uc( $_ ) );
    $odd_sum  += spi_exec_query( $query, 1 )->{ rows }[ 0 ]->{ odd_value }  if ( $index % 2 != 0 );
    $even_sum += spi_exec_query( $query, 1 )->{ rows }[ 0 ]->{ even_value } if ( $index % 2 == 0 );
  }


  $final_value = ( $odd_sum + $even_sum ) % 26;
  elog( DEBUG, "cf_check: $subject -> $odd_sum + $even_sum % 26 = $final_value" );

  $query = sprintf( "SELECT c FROM cf.check_chars WHERE even_value = %d AND c NOT IN ( %s ) ",
                    $final_value,
                    join( ',', ( map { sprintf( "'%1s'", $_ ) } (0..9) ) ) );
                    elog( DEBUG, $query );
  return spi_exec_query( $query, 1 )->{ rows }[ 0 ]->{ c };

END
$BODY$
LANGUAGE plperl;


CREATE OR REPLACE FUNCTION cf.cf( surname text,
                         name text,
                         birth_date date,
                         birth_place text,
                         gender bool DEFAULT true )
RETURNS char(16)
AS $CODE$
DECLARE
  cf_string char(15);
  cf_check  char(1);
BEGIN
  cf_string := cf.cf_letters( surname )
               || cf.cf_letters( name, true )
               || cf.cf_date( birth_date, NOT gender )
               || cf.cf_place( birth_place );

   cf_check := cf.cf_check( cf_string );
   RAISE DEBUG 'cf: % + %', cf_string, cf_check;

  RETURN upper( cf_string || cf_check );
END
$CODE$
LANGUAGE plpgsql;

COMMIT;
