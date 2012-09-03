INSERT INTO bsdmag.magazine (pk, id, month, issuedon, title)
VALUES(1,'2012-01', 1,       '2012-01-01'::date ,     'FreeBSD: Get Up To Date');
INSERT INTO bsdmag.magazine (pk, id, month, issuedon, title)
VALUES(2,'2011-12', 12,       '2012-04-01'::date , 'Rolling Your Own Kernel');
INSERT INTO bsdmag.magazine (pk, id, month, issuedon, title)
VALUES(3,'2011-11', 11,       '2011-01-01'::date, 'Speed Daemons');


INSERT INTO linuxmag.magazine (pk, id, month, issuedon, title)
VALUES(1,'2012-01', 1,       '2012-01-01'::date ,     'Understanding the Linux Kernel');
INSERT INTO linuxmag.magazine (pk, id, month, issuedon, title)
VALUES(2,'2011-12', 12,       '2012-04-01'::date , 'Gnome and Linux');
INSERT INTO linuxmag.magazine (pk, id, month, issuedon, title)
VALUES(3,'2011-11', 11,       '2011-01-11'::date, 'Interview with A. Seigo');
INSERT INTO linuxmag.magazine (pk, id, month, issuedon, title)
VALUES(4,'2011-10', 10,       '2011-01-10'::date, 'Compiling a kernel');
INSERT INTO linuxmag.magazine (pk, id, month, issuedon, title)
VALUES(5,'2011-09', 9,       '2011-01-09'::date, 'GNU Emacs');


INSERT INTO pentestmag.magazine (pk, id, month, issuedon, title)
VALUES(1,'2012-07', 1,       '2012-07-01'::date ,     'Special issue on mobility');


SELECT count( m.pk) AS bsdmag_issues
FROM bsdmag.magazine m;

SELECT count( m.pk) AS linuxmag_issues
FROM linuxmag.magazine m;

SELECT count( m.pk) AS pentestmag_issues
FROM pentestmag.magazine m;

