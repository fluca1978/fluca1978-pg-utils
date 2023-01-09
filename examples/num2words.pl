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
	num2words(  numeric default 0 )
RETURNS text
STRICT
AS $CODE$
   use Lingua::EN::Numbers qw/ num2en /;

   my ( $number ) = @_;

   num2en( $number );
$CODE$
LANGUAGE plperlu;
