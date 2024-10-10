CREATE OR REPLACE FUNCTION
py_check_codice_fiscale( cf text )
RETURNS bool
AS $CODE$
   import re
   pattern = re.compile( r'[A-Z]{6}\d{2}[A-Z]\d{2}[A-Z]\d{3}[A-Z]$' )
   # `match` anchors at the beginning of the string!
   if pattern.match( cf ) is not None:
      return True
   else:
      return False
$CODE$
LANGUAGE plpython3u;
