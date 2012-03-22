CREATE OR REPLACE FUNCTION compute_download_path()
RETURNS trigger AS
$BODY$
DECLARE

BEGIN
  -- if the magazine has been issued 
  -- compose the download path
  IF NEW.issuedon IS NOT NULL THEN
     NEW.download_path := 'http://bsdmag.org/download-demo/BSD_' || NEW.id || '.pdf';
     RAISE INFO 'Computed download for issue % path is %', NEW.title, NEW.download_path;
  ELSE
     RAISE INFO 'Removing the download path for issue %', NEW.title;
     NEW.download_path := NULL;
  END IF;

  RETURN NEW;

END;
$BODY$
LANGUAGE plpgsql VOLATILE;

DROP TRIGGER tr_download_path ON magazine;
CREATE TRIGGER tr_download_path
AFTER INSERT OR UPDATE ON magazine
FOR EACH ROW
EXECUTE PROCEDURE compute_download_path();