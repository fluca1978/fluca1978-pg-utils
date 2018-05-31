# Perl example to use the RETURNING feature
# from PostgreSQL statements. The result set is used
# as a regular result set from a read only query.
#
# Assuming the 'foo' table has been defined as follows:
# CREATE TABLE foo( pk serial, rv float );
#
# this cript generates an ouput similar to the following:
#
#
# The statement inserted pk = 11 and a random value rv = 0.258626
# The statement inserted pk = 12 and a random value rv = 0.877215
# The statement inserted pk = 13 and a random value rv = 0.900430
# The statement inserted pk = 14 and a random value rv = 0.312273
# The statement inserted pk = 15 and a random value rv = 0.300636
# The statement inserted pk = 16 and a random value rv = 0.401800
# The statement inserted pk = 17 and a random value rv = 0.446666
# The statement inserted pk = 18 and a random value rv = 0.352235
# The statement inserted pk = 19 and a random value rv = 0.390648
# The statement inserted pk = 20 and a random value rv = 0.790937

use DBI;
use v5.20;

my $dbh = DBI->connect("dbi:Pg:dbname=testdb;host=localhost;port=5432",
                       'luca',
                       '',
                       {AutoCommit => 0} );
my $query = <<'END_QUERY';
INSERT INTO foo( rv )
SELECT random()
FROM generate_series( 1, 10 )
RETURNING pk, rv;
END_QUERY

my $statement = $dbh->prepare( $query );
$statement->execute();
while ( my $result = $statement->fetchrow_hashref ) {
    say sprintf 'The statement inserted pk = %d and a random value rv = %f',
        $result->{ pk },
        $result->{ rv };
}


$dbh->disconnect();
