/*

sqlite> .schema images
  CREATE TABLE Images
  (
     id INTEGER PRIMARY KEY,
     album INTEGER,
     name TEXT NOT NULL,
     status INTEGER NOT NULL,
     category INTEGER NOT NULL,
     modificationDate DATETIME,
     fileSize INTEGER,
     uniqueHash TEXT,
     UNIQUE (album, name)
  );

sqlite> SELECT count(*) FROM images;
55365


On the PostgreSQL machine:

% sudo pkg install sqlite3-3.22.0_2
% git clone https://github.com/gleu/sqlite_fdw.git
% cd sqlite_fdw
% gmake
% sudo gmake install


# CREATE EXTENSION sqlite_fdw;
# CREATE SERVER digikam_sqlite_server
FOREIGN DATA WRAPPER sqlite_fdw
OPTIONS( database '/home/luca/digikam4.db' );


# CREATE FOREIGN TABLE digikam_images(
  id bigint NOT NULL,
  album INTEGER,
  name TEXT NOT NULL,
  status bigint NOT NULL,
  category bigint NOT NULL,
  modificationDate date,
  fileSize bigint,
  uniqueHash TEXT
)
SERVER digikam_sqlite_server
OPTIONS( table 'Images' );

# select count(*) from digikam_images ;
count
-------
55365

# GRANT ALL ON digikam_images TO PUBLIC;
CREATE SCHEMA digikam;
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS digikam;

CREATE TABLE digikam.images_root( LIKE digikam_images )
PARTITION BY RANGE ( modificationdate );


--
-- 2017 table with subpartitions
--
CREATE TABLE digikam.images_2017
       PARTITION OF digikam.images_root
       FOR VALUES FROM ( '2017-01-01' )
                    TO ( '2018-01-01' )
      PARTITION BY LIST ( extract( month from modificationdate ) );

--
-- first semester of 2017
--
CREATE TABLE digikam.images_2017_1_6
       PARTITION OF digikam.images_2017
       FOR VALUES IN (1, 2, 3, 4, 5, 6);

--
-- second semester of 2017
--
CREATE TABLE digikam.images_2017_7_12
       PARTITION OF digikam.images_2017
       FOR VALUES IN (7, 8, 9, 10, 11, 12);




CREATE TABLE digikam.images_2016
PARTITION OF digikam.images_root
FOR VALUES FROM ( '2016-01-01' )
             TO ( '2017-01-01' );

CREATE TABLE digikam.images_2015
PARTITION OF digikam.images_root
FOR VALUES FROM ( '2015-01-01' )
TO ( '2016-01-01' );

CREATE TABLE digikam.images_old
PARTITION OF digikam.images_root
FOR VALUES FROM ( '1950-01-01' )
TO ( '2015-01-01' );

CREATE TABLE digikam.images_2018
PARTITION OF digikam.images_root
FOR VALUES FROM ( '2018-01-01' )
TO ( '2018-12-31' );


COMMIT;



/*
INSERT INTO digikam.images_root
SELECT * FROM digikam_images WHERE modificationdate IS NOT NULL;


> SELECT COUNT(*) FROM digikam.images_root;
count
-------
55258
(1 row)

> SELECT COUNT(*) FROM digikam.images_2017;
count
-------
8318
*/
