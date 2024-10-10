CREATE OR REPLACE FUNCTION
py_generate_random_text( t_size int DEFAULT 8, t_limit int DEFAULT 10 )
RETURNS SETOF text
AS $CODE$
   import string
   import random

   for i in range( 0, t_limit ):
       current = ''.join( random.choices( string.ascii_letters + string.digits, k = t_size ) )
       yield( current )
$CODE$
LANGUAGE plpython3u;
