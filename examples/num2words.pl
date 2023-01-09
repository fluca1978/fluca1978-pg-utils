/*
 * Requires Perl module Lingua::EN::Numbers
 * that can be installed on the machine for instance by

    % sudo cpanm Lingua::EN::Numbers

 * Some simple invocations:

testdb=> select num2words();
 num2words 
-----------
 zero
(1 row)

testdb=> select num2words( 19071978 );
                               num2words                                
------------------------------------------------------------------------
 nineteen million, seventy-one thousand, nine hundred and seventy-eight
(1 row)

testdb=> select num2words( 1.23 );
      num2words      
---------------------
 one point two three
(1 row)

 */

CREATE OR REPLACE FUNCTION
	num2words_simple(  numeric default 0 )
RETURNS text
STRICT
AS $CODE$
   use Lingua::EN::Numbers qw/ num2en /;

   my ( $number ) = @_;

   num2en( $number );
$CODE$
LANGUAGE plperlu;




/**
  * The function accepts the number as first argument,
  * and the language as the second language.
  * If no language is specified, the  default english language
  * is used.
  *
  * Example of invocations:

testdb=> select num2words( 1907, 'russian' );
NOTICE:  Unsupported language russian
 num2words 
-----------
 
(1 row)

testdb=> select num2words( 1907 );
              num2words              
-------------------------------------
 one thousand nine hundred and seven
(1 row)

testdb=> select num2words( 1907, 'italian' );
      num2words      
---------------------
 millenovecentosette
(1 row)

*/
CREATE OR REPLACE FUNCTION
	num2words( numeric default 0, text default 'en' )
RETURNS text
STRICT
AS $CODE$
   my ( $number, $language ) = @_;
   $language = 'en' unless( $language );

   if ( $language =~ /^en(glish)?$/i ) {
      use Lingua::EN::Numbers qw/ num2en /;
      num2en( $number );
   }
   elsif( $language =~ /^it(alian)?$/i ) {
     use Lingua::IT::Numbers qw/ number_to_it /;
     number_to_it( $number );
   }
   else {
   	elog( NOTICE, "Unsupported language $language" );
	return undef;
   }
$CODE$
LANGUAGE plperlu;
