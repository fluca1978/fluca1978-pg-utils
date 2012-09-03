CREATE SCHEMA bsdmag;

CREATE TABLE IF NOT EXISTS bsdmag.magazine(pk serial NOT NULL,
id text,
month int,
issuedon date,
title text,
PRIMARY KEY(pk),
UNIQUE (id)
);



CREATE SCHEMA pentestmag;

CREATE TABLE IF NOT EXISTS pentestmag.magazine(pk serial NOT NULL,
id text,
month int,
issuedon date,
title text,
PRIMARY KEY(pk),
UNIQUE (id)
);


CREATE SCHEMA linuxmag;

CREATE TABLE IF NOT EXISTS linuxmag.magazine(pk serial NOT NULL,
id text,
month int,
issuedon date,
title text,
PRIMARY KEY(pk),
UNIQUE (id)
);

