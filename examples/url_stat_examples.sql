BEGIN;

CREATE SCHEMA IF NOT EXISTS url_stat;

/*
 * A table that holds urls and the counter of each visit to such URL.
 */
CREATE TABLE url_stat.url (
       pk int GENERATED ALWAYS AS IDENTITY,
       protocol  varchar(10) DEFAULT 'http',
       site      text NOT NULL,
       url       text NOT NULL,
       visited   int  DEFAULT 0,
       published bool DEFAULT true,

       PRIMARY KEY( pk ),
       CHECK ( visited >= 0 ),
       UNIQUE( site, url ) -- allow  different protocols for the same site
);


/**
 * Internal function to allow splitting an URL into
 * parts.
 */
CREATE OR REPLACE FUNCTION url_stat.split_url( url text )
RETURNS text[]
AS  $CODE$
DECLARE
  protocol text;
  site     text;
  path     text;
  parts    text[];
BEGIN
  -- split depending on the slash
  parts := string_to_array( url, '/' );
  /*
     string_to_array( 'http://www.google.com/hello', '/' );
        =>   {http:,"",www.google.com,hello}
  */

  -- remove the trail ':' from the protocol
  protocol := translate( parts[ 1 ], ':', '' );
  site     := parts[ 3 ];
  -- do slicing for any remaining part (4: -> 4 to the end)
  -- and reassemble the string with the '/' separator
  url      := array_to_string( parts[ 4: ], '/' );

  RAISE DEBUG 'split_url: [%] + [%] + [%]', protocol, site, url;
  RETURN ARRAY[ protocol, site, url ]::text[];
END
$CODE$
LANGUAGE plpgsql;



--
-- POPULATE THE TABLE
--
WITH urls_array AS (
    SELECT url_stat.split_url( url ) AS url_array
    FROM unnest( ARRAY[
    'https://conoscerelinux.org/courses/postgresql/'
    , 'https://conoscerelinux.org/il-consiglio/'
    , 'https://conoscerelinux.org/courses/conoscere-wordpress-maggio-2018/'
    , 'https://conoscerelinux.org/hack-team-t2h/'

    , 'https://fluca1978.github.io/2018/04/20/SQLiteRenamingTable.html'
    , 'https://fluca1978.github.io/2018/04/12/PostgreSQL-plpython.html'
    , 'https://fluca1978.github.io/about/'
    , 'https://fluca1978.github.io/papers/'
    ]
    ) url
)
INSERT INTO url_stat.url( protocol, site, url )
SELECT url_array[ 1 ], url_array[ 2 ], url_array[ 3 ]
FROM urls_array;


/*
 * Each time a tuple is deleted set the page as unpusblished instead.
 */
CREATE OR REPLACE RULE rule_delete_unpublish
AS ON DELETE
TO url_stat.url
DO INSTEAD UPDATE url_stat.url SET published = false WHERE pk = OLD.pk;





/*
 * Rules are as follows:
 * 1) the 'visited' counter must be always at least 0;
 * 2) when the page is turned online from offline its counter has to be reset to zero;
 * 3) if a page is unpublished the counter cannot change
 * 4) if the page is published the counter cannot decrease
 */
CREATE OR REPLACE FUNCTION url_stat.f_tr_url_manage_publishing()
RETURNS TRIGGER
AS $BODY$
DECLARE
BEGIN
  RAISE DEBUG 'f_tr_url_manage_publishin: [%] published % -> %, visited % -> %',
                                            NEW.url,
                                            OLD.published,
                                            NEW.published,
                                            OLD.visited,
                                            NEW.visited;

   -- nothing to do if not update!
  IF TG_OP <> 'UPDATE' THEN
     RETURN NULL;
  END IF;

  -- the counter must be there!
  IF NEW.visited IS NULL OR NEW.visit < 0 THEN
     NEW.visited := 0;
  END IF;


  IF NEW.published <> OLD.published THEN
     RAISE DEBUG 'published % -> % for [%]', OLD.published, NEW.published, NEW.url;

    IF NEW.published AND NOT OLD.published THEN
         -- page turned on line, set the right counter
         IF NEW.visited = OLD.visited  THEN
            RAISE DEBUG 'reset counter for re-publishing [%]', NEW.url;
            NEW.visited := 0;
         END IF;
    ELSIF NOT NEW.published THEN
      -- page turned off line
      IF NEW.visited <> OLD.visited THEN
            -- avoid changing the counter on an off line page
            RAISE DEBUG 'prevent changes from % to % for unpublished [%]',
                              OLD.visited,
                              NEW.visited,
                              NEW.url;
            NEW.visited := OLD.visited;
      END IF;
    END IF;
  ELSE
    -- publishing not change
    IF NOT NEW.published THEN
       RAISE DEBUG 'cannot update anything on unpublished [%]', NEW.published;
       RETURN NULL;
   END IF;
  END IF;

  IF NEW.published AND OLD.published
       AND NEW.visited < OLD.visited THEN
     RAISE DEBUG 'cannot decrease visited from % to % for [%]',
                         OLD.visited,
                         NEW.visited,
                         NEW.url;
    NEW.visited := OLD.visited;
  END IF;

RETURN NEW;
END
$BODY$
LANGUAGE create;



CREATE TRIGGER tr_url_check
BEFORE UPDATE OF published, visited
ON url_stat.url
FOR EACH ROW EXECUTE PROCEDURE
url_stat.f_tr_url_manage_publishing();

/*
 * example queries:

 update url_stat.url set published = true, visited = random() * 2000;
 delete from url_stat.url;
 update url_stat.url set published = true;
 update url_stat.url set visited = visited - 1;


select site, url, visited, row_number() over (), rank() over ( partition by site order by visited desc) from url_stat.url;

 */
