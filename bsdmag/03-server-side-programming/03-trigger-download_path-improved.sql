CREATE OR REPLACE FUNCTION compute_download_path()
RETURNS trigger AS
$BODY$
DECLARE
	default_path text;
BEGIN

  -- check if the trigger has a path as argument,
  -- otherwise use a default path
  IF TG_NARGS > 0 THEN
     -- first argument is the path
     default_path := TG_ARGV[ 0 ];
     RAISE INFO 'Using a trigger-level path %', default_path;
  ELSE
    -- a default hard coded path
    default_path :=  'http://bsdmag.org/download-demo/';
  END IF;

  -- print an info message
  RAISE INFO 'Trigger % executing for % event', TG_NAME, TG_OP;


  -- if executing for a single column then compute the path
  IF TG_OP = 'UPDATE'  THEN
     IF NEW.issuedon IS NOT NULL THEN
     	NEW.download_path := default_path || 'BSD_' || NEW.id || '.pdf';	
        RAISE INFO 'Computed download for issue % path is %', NEW.title, NEW.download_path;
     ELSE
        RAISE INFO 'Removing the download path for issue %', NEW.title;
        NEW.download_path := NULL;
     END IF;

     -- suppose this is a statement trigger
     RETURN NEW;

  END IF;


  -- if the trigger is performed for an insert
  -- then update also the other tuples
  IF ( TG_OP = 'INSERT' AND TG_LEVEL = 'STATEMENT' ) THEN

     RAISE INFO 'Updating old tuples';
     UPDATE magazine
     SET    download_path = default_path || 'BSD_' || id || '.pdf'
     WHERE  download_path IS NULL
     AND    issuedon IS NOT NULL;

     RETURN NULL;

  END IF;


END;
$BODY$
LANGUAGE plpgsql VOLATILE;

DROP TRIGGER tr_download_path ON magazine;
DROP TRIGGER tr_u_download_path ON magazine;
DROP TRIGGER tr_i_download_path ON magazine;

CREATE TRIGGER tr_u_download_path
BEFORE UPDATE OF issuedon
ON magazine 
FOR EACH ROW
EXECUTE PROCEDURE compute_download_path( 'http://bsdmag.org/download-demo/' );


CREATE TRIGGER tr_i_download_path
AFTER INSERT
ON magazine 
FOR EACH STATEMENT
EXECUTE PROCEDURE compute_download_path( 'http://bsdmag.org/download-demo/' );