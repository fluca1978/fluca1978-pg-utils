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

CREATE TABLE digikam.images_root( LIKE digikam_images );


CREATE TABLE digikam.images_2018
(
CHECK (modificationdate >= '2018-01-01'::date
AND modificationdate < '2019-01-01'::date )
) INHERITS ( digikam.images_root );


CREATE OR REPLACE RULE r_partition_insert_images_2018 AS
ON INSERT
TO digikam.images_root
WHERE (modificationdate >= '2018-01-01'::date
   AND modificationdate < '2019-01-01'::date )
DO INSTEAD
INSERT INTO digikam.images_2018 SELECT NEW.*;



CREATE TABLE digikam.images_2017
(
   CHECK (modificationdate >= '2017-01-01'::date
      AND modificationdate < '2018-01-01'::date )
) INHERITS ( digikam.images_root );


CREATE OR REPLACE RULE r_partition_insert_images_2017 AS
ON INSERT
TO digikam.images_root
WHERE (modificationdate >= '2017-01-01'::date
AND modificationdate < '2018-01-01'::date )
DO INSTEAD
INSERT INTO digikam.images_2017 SELECT NEW.*;




CREATE TABLE digikam.images_2016
(
CHECK (modificationdate >= '2016-01-01'::date
AND modificationdate < '2017-01-01'::date )
) INHERITS ( digikam.images_root );

CREATE OR REPLACE RULE r_partition_insert_images_2016 AS
ON INSERT
TO digikam.images_root
WHERE (modificationdate >= '2016-01-01'::date
AND modificationdate < '2017-01-01'::date )
DO INSTEAD
INSERT INTO digikam.images_2016 SELECT NEW.*;



CREATE TABLE digikam.images_2015
(
CHECK (modificationdate >= '2015-01-01'::date
AND modificationdate < '2016-01-01'::date )
) INHERITS ( digikam.images_root );


CREATE OR REPLACE RULE r_partition_insert_images_2015 AS
ON INSERT
TO digikam.images_root
WHERE (modificationdate >= '2015-01-01'::date
AND modificationdate < '2016-01-01'::date )
DO INSTEAD
INSERT INTO digikam.images_2015 SELECT NEW.*;



CREATE TABLE digikam.images_old
(
CHECK (modificationdate >= '1950-01-01'::date
AND modificationdate < '2015-01-01'::date )
) INHERITS ( digikam.images_root );

CREATE OR REPLACE RULE r_partition_insert_images_old AS
ON INSERT
TO digikam.images_root
WHERE (modificationdate >= '1950-01-01'::date
AND modificationdate < '2015-01-01'::date )
DO INSTEAD
INSERT INTO digikam.images_old SELECT NEW.*;




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
