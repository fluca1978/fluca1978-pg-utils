#!/usr/bin/env perl

#use strict;
#use warnings;
#use lib '/usr/local/lib/perl5/site_perl/5.10.1/DBD';
use DBI;
#use PgPP;
use Data::Dumper;
use IO::Select;

my $database = "dbi:Pg:dbname=bsdmagdb";
my $username = 'bsdmag';

my $connection =  DBI->connect( $database, $username, '' ) || undef();

my $channel = "delete_channel";
print "\nListening on channel $channel\n";
$connection->do( "LISTEN $channel" );



#my $fd = $connection->func("getfd");
#my $sel = IO::Select->new($fd);

for( my $i = 60; $i > 0; $i-- ){
    print "Waiting for still $i seconds...\n";
    #$sel->can_read;
    sleep 1;

    # get the event back
    while( my $event = $connection->func("pg_notifies") ){
    if( defined($event) ) {
        my ($eventName, $pid, $payload) = @$event;
        my $row = $connection->selectrow_hashref("SELECT now()");
	print "Event <$eventName> received from process PID  <$pid> with payload <$payload>\n";

    }
    }
}





