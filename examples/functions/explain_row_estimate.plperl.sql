/*
 Example session

> select plperl_row_estimate( 'SELECT p.* FROM persona p JOIN persona k on k.pk = p.pk WHERE k.eta = 40' );
DEBUG:  Estimating from [EXPLAIN (FORMAT YAML) SELECT p.* FROM persona p JOIN persona k on k.pk = p.pk WHERE k.eta = 40]
plperl_row_estimate
---------------------
69500

*/
CREATE OR REPLACE FUNCTION plperl_row_estimate( query text )
RETURNS BIGINT
AS $PERL$

   my ( $query ) = @_;
   return 0 if ( ! $query );
   $query = sprintf "EXPLAIN (FORMAT YAML) %s", $query;

   elog( DEBUG, "Estimating from [$query]" );
   my @estimated_rows = map { s/Plan Rows:\s+(\d+)$/$1/; $_ }
                        grep { $_ =~ /Plan Rows:/ }
                        split( "\n", spi_exec_query( $query )->{ rows }[ 0 ]->{ "QUERY PLAN" } );

   return 0 if ( ! @estimated_rows );
   return $estimated_rows[ 0 ];
$PERL$
LANGUAGE plperl;
