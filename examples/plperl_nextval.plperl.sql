/*
 Example session

> select plperl_add_sequence_handler( 'persona_pk_seq' );
> do language plperl $$
   elog( INFO, $_SHARED{ persona_pk_seq }->() );
$$;


*/
CREATE OR REPLACE FUNCTION plperl_add_sequence_handler( s text )
RETURNS VOID
AS $PERL$

   my ( $sequence ) = @_;
   return 0 if ( ! $sequence );
   my $query = sprintf "SELECT nextval( '%s' )", $sequence;

   elog( DEBUG, "Query [$query]" );
   $_SHARED{ $sequence } = sub {
      return spi_exec_query( $query )->{ rows }[ 0 ]->{ nextval };
   };

$PERL$
LANGUAGE plperl;
