BEGIN;

--DROP TABLE magazine CASCADE;
CREATE TABLE IF NOT EXISTS magazine(pk serial NOT NULL,
id text,
month int,
issuedon date,
title text,
PRIMARY KEY(pk),
UNIQUE (id)
);

TRUNCATE TABLE magazine;
INSERT INTO magazine (pk, id, month, issuedon, title)
VALUES(1,'2012-01', 1,       '2012-01-01'::date ,     'FreeBSD: Get Up To Date');

INSERT INTO magazine (pk, id, month, issuedon, title)
VALUES(2,'2011-12', 12,       '2012-04-01'::date , 'Rolling Your Own Kernel');


INSERT INTO magazine (pk, id, month, issuedon, title)
VALUES(3,'2011-11', 11,       '2011-01-01'::date, 'Speed Daemons');


COMMIT;
