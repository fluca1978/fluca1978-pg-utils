BEGIN;

CREATE SCHEMA IF NOT EXISTS url_stat;

/*
 * A table that holds urls and the counter of each visit to such URL.
 */
CREATE TABLE IF NOT EXISTS url_stat.url (
       pk int GENERATED ALWAYS AS IDENTITY,
       protocol  text DEFAULT 'http',
       site      text NOT NULL,
       url       text NOT NULL,
       params    text[],
       visited   int  DEFAULT 0,
       published bool DEFAULT true,

       PRIMARY KEY( pk ),
       CHECK ( visited >= 0 ),
       UNIQUE( site, url, params ) -- allow  different protocols for the same site
);


TRUNCATE TABLE url_stat.url;

ALTER TABLE url_stat.url ALTER COLUMN pk RESTART;

/**
 * Internal function to allow splitting an URL into
 * parts.
 *
 * @returns an array with the following indexing:
 * 1 => protocol
 * 2 => site (base url)
 * 3 => path (action url)
 * 4 => parameters (or an empty array)
 *
 * Example of invocation:

SELECT url_stat.split_url( 'https://www.google.com/search?q=postgresql&lang=it' );
> SELECT url_stat.split_url( 'https://www.google.com/search?q=postgresql&lang=it' );
DEBUG:  split_url: [https] + [www.google.com] + [search/] + [q=postgresql&lang=it]
split_url
-----------------------------------------------------
{https,www.google.com,search/,q=postgresql,lang=it}

 *
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
  parts := string_to_array( url, '://' );
  /*
     string_to_array( 'http://www.google.com/hello', '/' );
        =>   {http:,www.google.com,hello}
  */


  protocol := parts[ 1 ];
  -- split the remaining by '/'
  parts    := string_to_array( parts[ 2 ], '/' );
  site     := parts[ 1 ];
  -- do slicing for any remaining part (2: -> 2 to the end)
  -- and reassemble the string with the '/' separator
  url      := array_to_string( parts[ 2: ], '/' );

  -- do I have any param?
  IF url LIKE '%?%' THEN
     -- if I have parameters split the 'url' part
     -- into two dimension array:
     -- 'url' = 'search?q=foo&b=bar' => { 'search', 'q=foo&b=bar' }
     -- then get back the 'url' part and build an array
     -- from the remaining string
     parts := string_to_array( url, '?' );
     url   := parts[ 1 ] || '/';
     parts := string_to_array( array_to_string( parts[ 2: ], '' ), '&' );

  ELSE
    -- no parameters, avoid inserting...
    parts := NULL;
  END IF;

  RAISE DEBUG 'split_url: [%] + [%] + [%] + [%]', protocol, site, url, array_to_string( parts, '&' );
  RETURN array_cat( ARRAY[ protocol, site, url ]::text[], parts[ 1: ] );
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

    , 'https://www.google.com/search?q=hello+world'
    , 'https://www.google.com/search?q=postgresql&lang=it'

    , 'jdbc:postgresql://localhost/testdb?username=luca'
    ]
    ) url
)
INSERT INTO url_stat.url( protocol, site, url, params, visited )
SELECT url_array[ 1 ], url_array[ 2 ], url_array[ 3 ], url_array[ 4: ], random() * 1000
FROM urls_array;


/*
 * Each time a tuple is deleted set the page as unpusblished instead.
 */
CREATE OR REPLACE RULE rule_delete_unpublish
AS ON DELETE
TO url_stat.url
DO INSTEAD UPDATE url_stat.url SET published = false WHERE pk = OLD.pk;



/*
 + Delete trigger, similar to the above rule but using ctid
 */
-- CREATE OR REPLACE FUNCTION url_stat.tr_f_delete_unpublish()
-- RETURNS TRIGGER
-- AS $CODE$
-- DECLARE
-- BEGIN
--   IF TG_OP <> 'DELETE' THEN
--      RETURN NULL;
--   END IF;

--   UPDATE url_stat.url SET published = false
--      WHERE ctid = OLD.ctid;

--   RETURN NULL;
-- END
-- $CODE$
-- LANGUAGE plpgsql;


-- CREATE TRIGGER tr_delete_unpublish
-- BEFORE DELETE
-- ON url_stat.url
-- FOR EACH ROW
-- EXECUTE PROCEDURE url_stat.tr_f_delete_unpublish();

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
LANGUAGE plpgsql;



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




/*
 * Perl implementation of the split_url function
 */
CREATE OR REPLACE FUNCTION url_stat.split_url_pl( url text )
RETURNS text[]
AS  $CODE$
    my ( $url ) = @_;

    my ( $protocol, $site, $path, $param_string ) =
               ( $url =~ / ^ ([a-zA-Z]+)
                         : \/ \/
                         ([a-zA-Z0-9.]+\/?)
                         ([\/a-zA-Z0-9]+)\??
                         (.+)
                         /x );

    my @params;
    @params = split '&', $param_string if ( $param_string );
    return [ $protocol,
             $site,
             $path,
             @params ];
$CODE$
LANGUAGE plperl;

/*
SELECT url_stat.split_url_pl( url ) AS url_array
FROM unnest( ARRAY[
'https://conoscerelinux.org/courses/postgresql/'
, 'https://conoscerelinux.org/il-consiglio/'
, 'https://conoscerelinux.org/courses/conoscere-wordpress-maggio-2018/'
, 'https://conoscerelinux.org/hack-team-t2h/'

, 'https://fluca1978.github.io/2018/04/20/SQLiteRenamingTable.html'
, 'https://fluca1978.github.io/2018/04/12/PostgreSQL-plpython.html'
, 'https://fluca1978.github.io/about/'
, 'https://fluca1978.github.io/papers/'

, 'https://www.google.com/search?q=hello+world'
, 'https://www.google.com/search?q=postgresql&lang=it'
]
) url;
*/

/*
 * Perl trigger for managing the updates.
 * A Perl trigger must return the special
 * strings 'SKIP' or 'MODIFY'.
 * Each trigger argument is placed into the $_TD special hash.
 * Variables are passed as strings!
 */
CREATE OR REPLACE FUNCTION url_stat.f_tr_url_manage_publishing_pl()
RETURNS TRIGGER
AS $BODY$

       # do not work on not update trigger!
      return 'SKIP' if ( $_TD->{event} ne 'UPDATE' );

      # get some shorten variable
      # WANRING: value 'false' is translate to the string 'f' so
      # check it against 't' to be able to use it as a Perl false variable
      my ( $new_published, $old_published ) = ( $_TD->{new}->{published} eq 't',
                                                $_TD->{old}->{published} eq 't' );

      my ( $new_visited, $old_visited ) = ( $_TD->{new}->{visited},
                                            $_TD->{old}->{visited} );

     elog( DEBUG, "published $old_published -> $new_published " );
     elog( DEBUG, "visited $old_visited -> $new_visited" );

     if ( $old_published != $new_published ){
          # page turned published
          $_TD->{new}->{visited} = 0 if ( $new_published && ! $old_published
                                          && $new_visited == $old_visited );
          # page turned unpublished
          $_TD->{new}->{visited} = $_TD->{old}->{visited}
                                    if ( ! $new_published && $old_published );
     }
     else {
           # page still unpublished
          return 'SKIP' if ( ! $new_published );
     }

     # page was published but the counter is decreasing...
     $_TD->{new}->{visited} = $_TD->{old}->visited
             if ( $new_published && $old_published && $old_visited > $new_visited );

     return 'MODIFY';

$BODY$
LANGUAGE plperl;


COMMIT;
/*
CREATE TRIGGER tr_url_check
BEFORE UPDATE OF published, visited
ON url_stat.url
FOR EACH ROW EXECUTE PROCEDURE
url_stat.f_tr_url_manage_publishing_pl();
*/
