CREATE TABLE readers(
   pk SERIAL NOT NULL,
   name  text,
   email text,
   PRIMARY KEY(pk),
   UNIQUE(email)
);


INSERT INTO readers(name, email) VALUES('Luca Ferrari', 'lf@fakemail.com');
INSERT INTO readers(name, email) VALUES('Ritchie Root', 'rr@fakemail.com');