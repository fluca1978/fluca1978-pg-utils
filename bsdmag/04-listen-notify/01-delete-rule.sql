DROP RULE r_delete_magazine ON magazine;

CREATE OR REPLACE RULE r_delete_magazine
AS ON DELETE TO magazine
DO ALSO
NOTIFY delete_channel, 'Deletion of a tuple';
