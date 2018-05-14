BEGIN;

CREATE TABLE IF NOT EXISTS rep_data (
       pk serial PRIMARY KEY,
       comment text,
       xid     bigint,
       ts      timestamp DEFAULT current_timestamp
);




COMMIT;

BEGIN;
TRUNCATE TABLE rep_data;
INSERT INTO rep_data( comment, xid ) VALUES( 'First', txid_current() );
COMMIT;

BEGIN;
INSERT INTO rep_data( comment, xid ) VALUES( 'Second', txid_current() );
COMMIT;


BEGIN;
INSERT INTO rep_data( comment, xid ) VALUES( 'Third', txid_current() );
COMMIT;
