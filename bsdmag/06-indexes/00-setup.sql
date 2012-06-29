CREATE TABLE IF NOT EXISTS articles(
  pk serial NOT NULL,               -- primary key
  title text NOT NULL,              -- article's title
  abstract text NOT NULL,           -- article abstract text
  pages integer DEFAULT 1,          -- number of pages
  listings integer DEFAULT 0,       -- number of code listings
  difficulty char(3) DEFAULT 'AVG', -- difficulty level ('MIN','MAX','AVG')

  PRIMARY KEY(pk)

);

CREATE OR REPLACE FUNCTION populate_articles_table( numtuples integer )
RETURNS VOID
AS
$BODY$
DECLARE
        random_value    integer;
        difficulty      char(3);
        listing         integer;
BEGIN


        WHILE numtuples > 0 LOOP
              IF numtuples % 3 = 0 THEN
                difficulty := 'AVG';
                listing    := (random() * 10)::integer;
              ELSIF numtuples % 3 = 1 THEN
                difficulty := 'MAX';
                listing    := (random() * 100)::integer;
              ELSE
                difficulty := 'MIN';
                listing    := 0;
              END IF;


              INSERT INTO articles(title, abstract, pages,
                                          listings, difficulty)
              VALUES( 'Title for an ' || difficulty || ' article ',
                      'Here comes the abstract bla bla....',
                      (random() * 10)::integer + 1,
                      listing,
                      difficulty);

             numtuples := numtuples - 1;

        END LOOP;

END;
$BODY$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION populate_articles_table_avg( numtuples integer )
RETURNS VOID
AS
$BODY$
DECLARE
        random_value    integer;
        difficulty      char(3);
        listing         integer;
BEGIN


        WHILE numtuples > 0 LOOP
              IF numtuples % 200 = 0 THEN
                difficulty := 'AVG';
                listing    := (random() * 10)::integer;
              ELSIF numtuples % 3 = 1 THEN
                difficulty := 'MAX';
                listing    := (random() * 100)::integer;
              ELSE
                difficulty := 'MIN';
                listing    := 0;
              END IF;


              INSERT INTO articles(title, abstract, pages,
                                          listings, difficulty)
              VALUES( 'Title for an ' || difficulty || ' article ',
                      'Here comes the abstract bla bla....',
                      (random() * 10)::integer + 1,
                      listing,
                      difficulty);

             numtuples := numtuples - 1;

        END LOOP;

END;
$BODY$
LANGUAGE plpgsql;