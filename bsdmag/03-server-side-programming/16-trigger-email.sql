CREATE OR REPLACE FUNCTION compute_download_path()
RETURNS trigger AS
$BODY$
DECLARE
        default_path   text;
BEGIN

  -- check if the trigger has a path as argument,
  -- otherwise use a default path
  IF TG_NARGS > 0 THEN
     -- first argument is the path
     default_path := TG_ARGV[ 0 ];
     RAISE LOG 'Using a trigger-level path %', default_path;
  ELSE
    -- a default hard coded path
    default_path :=  'http://bsdmag.org/download-demo/';
  END IF;

  -- print an info message
  RAISE LOG 'Trigger % executing for % event', TG_NAME, TG_OP;


  -- if executing for a single column then compute the path
  IF ( TG_OP = 'UPDATE' OR TG_OP = 'INSERT' )  THEN
     IF NEW.issuedon IS NOT NULL THEN
        NEW.download_path := default_path || 'BSD_' || NEW.id || '.pdf';
        RAISE LOG 'Computed download for issue % path is %', NEW.title, NEW.download_path;
     ELSE
        RAISE LOG 'Removing the download path for issue %', NEW.title;
        NEW.download_path    := NULL;
        NEW.notified_readers := 0;
     END IF;


     -- if here and the download path has been computed
     -- then notify readers
     IF NEW.download_path IS NOT NULL THEN
     	SELECT notify_readers( NEW.pk )
     	INTO   NEW.notified_readers;
     	RAISE  LOG 'Notified readers %', NEW.notified_readers;
     END IF;



     -- suppose this is a row trigger
     RETURN NEW;

  END IF;


END;
$BODY$
LANGUAGE plpgsql VOLATILE;





DROP TRIGGER tr_download_path ON magazine;
DROP TRIGGER tr_u_download_path ON magazine;
DROP TRIGGER tr_i_download_path ON magazine;
DROP TRIGGER tr_download_path ON magazine;

CREATE TRIGGER tr_download_path
AFTER INSERT OR UPDATE OF issuedon
ON magazine 
FOR EACH ROW
EXECUTE PROCEDURE compute_download_path( 'http://bsdmag.org/download-demo/' );

