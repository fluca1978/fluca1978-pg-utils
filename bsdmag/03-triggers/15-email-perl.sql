CREATE OR REPLACE FUNCTION notify_readers( integer ) RETURNS integer                
    LANGUAGE plperlu                                                                       
    AS $_$ 
    
    my ($issuepk)   = @_;
    my $sent_emails = 0;
    my $query       = "SELECT title, download_path FROM magazine WHERE pk = $issuepk";
    my $boundary    = "===BSDMAG===";
    my $sent        = 0;
    my ($result_set, $email_text, $name, $current_row, $email, %mail);
    my ($download_path, $title);

    elog( INFO, "Extracting the issue data via the query $query\n");
    $result_set    = spi_exec_query( $query );     
    $current_row   = $result_set->{rows}[ 0 ];	                                         
    $title         = $current_row{"title"};
    $download_path = $current_row{"download_path"};
    elog( INFO, "Magazine Issue: $title at $download_path \n" );
    
    $query       = "SELECT email, name FROM readers";
    elog( INFO, "Extracting all readers via the query $query\n");
    $result_set = spi_exec_query( $query );                                              
    $num_rows   = $result_set->{processed};
    elog( INFO, "Found $num_rows readers\n" );
                                                
    # iterate on each reader
    for( $i = 0; $i <= $num_rows; $i++ ){
       $current_row = $result_set->{rows}[ $i ];
       $name        = $current_row->{"name"};
       $email       = $current_row->{"email"};


       # build the e-mail
       %mail = ( From     => 'postgres@bsdmag.org',
                 To       => $email,                                  
                 Subject  => 'New BSD Magazine Issue!'
               );   
       $mail{smtp} = 'yoursmtp.bsdmag.org';
       $mail{body} = << "END_OF_BODY";
$boundary--
Content-Type: text/plain; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable  
Dear $name,
there is a new issue of BSD Magazine available for
download at the URL $download_path
so please check it out!
$boundary----
END_OF_BODY

       elog( INFO, "Notifying reader $name at email $email\n" . $mail{body} . "\n" );
	
         #sendmail( %mail ) or warn( $Mail::Sendmail::error) ;
	 $sent++;
    }


    return $sent;       

    $_$;
    