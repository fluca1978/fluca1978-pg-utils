DROP TRIGGER tr_download_path ON magazine;
DROP TRIGGER tr_i_download_path ON magazine;
DROP TRIGGER tr_u_download_path ON magazine;

DROP FUNCTION compute_download_path() RETURNS trigger;

CREATE OR REPLACE FUNCTION  compute_download_path()
RETURNS trigger 
AS
$BODY$

	use File::Copy;

  # a variable to handle the default path
  # and the copy flag
  my ($default_path, $pdf_source_dir, $web_dir);
  
  # check arguments
  if( $_TD->{argc} > 0 ){
     # array reference to the arguments
     @args = @{$_TD->{args}};
     $default_path   = $args[0];
     $pdf_source_dir = $args[1];
     $web_dir        = $args[2];
  }
  else{	
     $default_path = 'http://bsdmag.org/download-demo/';
  }		      
	
	


  # update trigger, modify this single row
  if( $_TD->{event} eq "UPDATE" ){
    if( defined( $_TD->{new}->{issuedon} ) ){
        elog( INFO, "Applying a new download path" );
	my $pdf_name = "BSD_" . $_TD->{new}->{id} . ".pdf";
	my $pdf_path = "'" . $default_path . $pdf_name . "'";
        $_TD->{new}->{download_path} = $pdf_path;  
	elog( INFO, "New path is " . $_TD->{new}->{download_path} );

	# do I have to copy the file?
	if( defined($pdf_source_dir) ){
	  my $pdf_dest = $web_dir . "/" . $pdf_name;
	  if( ! -f $pdf_name ){
	    my $pdf_source = $pdf_source_dir . "/" . $pdf_name ;
	    elog( INFO, "Copying file $pdf_source into $pdf_dest ");
	    
	    copy( $pdf_source , $pdf_dest );
	  }
	}

    }
    else{
      elog( INFO, "Deleting the download path");
      undef( $_TD->{new}->{download_path} );
    }

    # apply changes
    return "MODIFY";
  }


  # insert level?
  if( $_TD->{event} eq "INSERT" &&  $_TD->{level} eq "STATEMENT" ){
     # here change all the rows calculating the download path
     $query  = "UPDATE magazine SET download_path = '$default_path' ";
     $query .= " || 'BSD_' || id || '.pdf'";
     $query .= " WHERE download_path IS NULL AND issuedon IS NOT NULL";
     elog( INFO, "Perl query : $query " );
     spi_exec_query( $query );

      return;
  }



$BODY$
LANGUAGE plperlu;


CREATE TRIGGER tr_u_download_path
BEFORE UPDATE OF issuedon
ON magazine 
FOR EACH ROW
EXECUTE PROCEDURE compute_download_path( 'http://bsdmag.org/download-demo/', '~/pdf/', '~/www/pdf' );


CREATE TRIGGER tr_i_download_path
AFTER INSERT
ON magazine 
FOR EACH STATEMENT
EXECUTE PROCEDURE compute_download_path( 'http://bsdmag.org/download-demo/' , '~/pdf/', '~/www/pdf');
