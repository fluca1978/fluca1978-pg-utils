#!/usr/bin/env perl

#use strict;
#use warnings;
#use lib '/usr/local/lib/perl5/site_perl/5.10.1/DBD';
use DBI;
#use PgPP;
use Data::Dumper;
use IO::Select;

my $database = "dbi:PgPP:dbname=bsdmagdb";
my $username = 'bsdmag';

my $connection =  DBI->connect( $database, $username, '' ) || undef();

my $channel = "delete_channel";
print "\nListening on channel $channel\n";
$connection->do( "LISTEN $channel" );

open( $LOG_FILE, ">>", "/tmp/deletion.log" ) || croack("Cannot create log file\n$!\n");


#my $fd = $connection->func("getfd");
#my $sel = IO::Select->new($fd);

while( 1 ){
    sleep 10;

    # get the event back
    while( my $event = $connection->func("pg_notifies") ){
    if( defined($event) ) {
        my ($eventName, $pid, $payload) = @$event;
	if( defined( $payload ) && $payload =~ /(.*)\#(.*)\#/ ){

	    # get the username and client ip address of the notifier process
	    $sql  = "SELECT usename, client_addr, client_hostname";
	    $sql .= " FROM pg_stat_activity ";
	    $sql .= " WHERE procpid = $pid; ";
	    $resultset_arrayref = $connection->selectall_arrayref( $sql );
	    my $username = $resultset_arrayref->[0][0];
	    my $ip       = $resultset_arrayref->[0][1];
	    my $hostname = $resultset_arrayref->[0][2];

	    print $LOG_FILE "#### DELETION EVENT ####\n";
	    print $LOG_FILE "Backend process $pid deleted the magazine issue titled $2\n";
	    print $LOG_FILE "\tUsername $username from client $ip ($hostname)\n";
	} 

    }
    }
}

close( $LOG_FILE );





