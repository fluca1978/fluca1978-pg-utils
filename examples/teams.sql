DROP TABLE  IF EXISTS score;

CREATE TABLE score(
  pk int GENERATED ALWAYS AS IDENTITY
  , nome text NOT NULL
  , anno_nascita int NOT NULL
  , eta int
  , punteggio int DEFAULT 0
  , divisione text
  , squadra text
  , PRIMARY KEY( pk )
  , CHECK( punteggio >= 0 AND punteggio <= 100 )
);

/**
 * Normalizza il punteggio fra 0 e 100 anche se viene specificato qualcosa di diverso.
 */
CREATE OR REPLACE FUNCTION f_tr_punteggio()
  RETURNS TRIGGER
AS $CODE$
BEGIN
  IF TG_OP NOT IN ( 'INSERT', 'UPDATE' ) THEN
    RAISE EXCEPTION 'Questa funzione deve essere usata per inserimento/modifica!';
  END IF;

  RAISE DEBUG 'Trigger scattato';


  IF NEW.punteggio IS NULL OR  NEW.punteggio < 0 THEN
    NEW.punteggio := 0;
  ELSIF NEW.punteggio > 100 THEN
    NEW.punteggio := 100;
  END IF;

  RETURN NEW;
END
  $CODE$
  LANGUAGE plpgsql;



CREATE TRIGGER tr_punteggio
  BEFORE
  INSERT
  OR UPDATE OF punteggio
  ON score
  FOR EACH ROW EXECUTE FUNCTION f_tr_punteggio();



/*
 * Questa funzione considera che l'anno di nascita sia sempre
 * l'informazione che conta, e quindi da quella calcola l'eta' e
 * di conseguenza la divisione.
 */
CREATE OR REPLACE FUNCTION f_tr_eta()
  RETURNS TRIGGER
AS $CODE$

BEGIN

  IF TG_OP NOT IN ( 'INSERT', 'UPDATE' ) THEN
    RAISE EXCEPTION 'Questo trigger funziona solo per INSERT e UPDATE!';
  END IF;

  NEW.eta := extract( year FROM current_date ) - NEW.anno_nascita;

  IF NEW.eta >= 18 THEN
    NEW.divisione := 'SENIOR';
  ELSIF NEW.eta >= 16 AND NEW.eta < 18 THEN
    NEW.divisione := 'JUNIOR';
  ELSIF NEW.eta < 16 AND NEW.eta >= 14 THEN
    NEW.divisione := 'RAGAZZI';
  ELSE
    NEW.divisione := 'BABY';
  END IF;

  RETURN NEW;
END
  $CODE$
  LANGUAGE plpgsql;

/*
 * Il trigger deve attivarsi ogni volta che si agisce sulle
 * colonne eta, divisione, anno_nascita perché le deve
 * mantenere sempre coerenti.
 */
CREATE TRIGGER tr_eta
  BEFORE
  INSERT OR UPDATE OF anno_nascita, eta, divisione
  ON score
  FOR EACH ROW
    EXECUTE FUNCTION f_tr_eta();








CREATE FUNCTION f_compute_eta( anno_nascita int )
  RETURNS int
AS $CODE$
BEGIN
  RETURN extract( year FROM current_date ) - anno_nascita;
END
  $CODE$
  LANGUAGE plpgsql
  IMMUTABLE;


ALTER TABLE score
  ADD COLUMN eta_generated int
  GENERATED ALWAYS AS ( f_compute_eta( anno_nascita ) ) STORED;


TRUNCATE score;
insert into score( nome, anno_nascita, punteggio, squadra )
VALUES
( 'Luca', 1978, 200, 'A' )
, ( 'Simone', 1974, 50, 'B' )
, ( 'Marcello', 1973, 78, 'B' )
, ( 'Nicola', 1972, 99, 'A' )
, ( 'Claudio', 1972, 99, 'B' )
, ( 'Antonello', 1979, 88, 'B' )
, ( 'Roberto', 2007, 88, 'B' )
, ( 'Giancarlo', 2007, 78, 'A' )
;




SELECT
  nome
  , punteggio
  , squadra
  , divisione
  , rank() OVER w_totale AS classifica_totale
  , lag( punteggio, 1, punteggio ) OVER w_totale   - punteggio AS punti_mancanti
  , punteggio - lead( punteggio, 1, punteggio ) OVER w_totale AS punti_distacco
  , rank() OVER w_squadra AS classifica_intra_squadra
  , rank() OVER w_divisione AS classifica_divisione
  FROM score
         WINDOW w_totale AS ( ORDER BY punteggio DESC )
       , w_squadra AS ( PARTITION BY squadra ORDER BY punteggio DESC )
       , w_divisione AS ( PARTITION BY divisione ORDER BY punteggio DESC );




CREATE VIEW vw_score_seniors
  AS SELECT * FROM score
  WHERE divisione = 'SENIOR'
            WITH LOCAL CHECK OPTION;

CREATE VIEW vw_score_seniors_a
  AS SELECT * FROM vw_score_seniors
      WHERE squadra = 'A'
            WITH CASCADED CHECK OPTION;


-- UPDATE vw_score_seniors_a SET squadra = 'B';
-- non funziona!






ALTER TABLE score
  ADD COLUMN ritirato boolean DEFAULT false;

CREATE RULE r_ritirati
  AS ON DELETE TO score
  DO INSTEAD
  UPDATE score SET ritirato = true, punteggio = 0 WHERE pk = OLD.pk;



CREATE TABLE score_history (like score );
ALTER TABLE score_history ADD COLUMN ts timestamp DEFAULT CURRENT_TIMESTAMP;

CREATE RULE r_update
  AS ON UPDATE TO score
  DO ALSO
  INSERT INTO score_history SELECT OLD.*;
