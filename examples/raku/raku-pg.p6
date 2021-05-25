#!raku

use DB::Pg;



sub MAIN( Str :$host = 'miguel',
          Str :$username = 'luca',
          Str :$password = 'secet',
          Str :$database = 'testdb' ) {

    "Connecting $username @ $host/$database".say;

    my $connection = DB::Pg.new: conninfo => "host=$host user=$username password=$password dbname=$database";

    my $query = 'SELECT current_role, current_time';
    my $results = $connection.query: $query;

    say "The query { $query } returned { $results.rows } rows with columns: { $results.columns.join( ', ' ) }";
    for $results.hashes -> $row {
        for $row.kv -> $column, $value {
            say "Column $column = $value";
        }
    }



#    $connection.execute: q< insert into raku( t ) values( 'Hello World' )>;

    # get the database object to handle transactions
    my $database-handler = $connection.db;
    my $statement = $database-handler.prepare: 'insert into raku( t ) values( $1 )';
    $database-handler.begin;
#    $query = 'CREATE TABLE raku( pk int generated always as identity, t text, primary key( pk ) )';
#    $connection.execute: $query;

    $statement.execute( "This is value $_" )  for 0 .. 10;
    $database-handler.rollback;
    $database-handler.finish;


    for $connection.cursor( 'select * from raku', fetch => 2, :hash ) -> %row {
        say "====================";
        for %row.kv -> $column, $value {
            say "Column [ $column ] = $value";
        }
        say "====================";
    }


    # my $file = '/tmp/raku.csv'.IO.open: :w;
    # for $connection.query: 'COPY raku TO stdout (FORMAT CSV)'  -> $row {
    #     $file.print: $row;
    # }

    # $file.close;


    # $file = '/tmp/raku.csv'.IO.open: :r;

    # say $file.slurp.join( "\n" );

    # $database-handler = $connection.db;
    # $database-handler.query: 'COPY raku FROM STDIN (FORMAT CSV)';
    # $database-handler.copy-data:  '/tmp/raku1.csv'.IO.slurp;
    # $database-handler.copy-data:  '/tmp/raku2.csv'.IO.slurp;
    # $database-handler.copy-end;


    # ##############################################
    # # Add a converter
    # $connection.converter does role fluca-converter
    # {
    #     submethod BUILD { self.add-type( text => Str ) }
    #     multi method convert( Str:U, Str:D $value) {
    #         $value.flip.uc;
    #     }

    # }

    # .say for $connection.query( 'select * from raku' ).arrays;
    # ###########################################################


    react {
        whenever $connection.listen( 'delete_event' ) { .say; }
        whenever $connection.listen( 'insert_event' ) { .say; }
    }
}
