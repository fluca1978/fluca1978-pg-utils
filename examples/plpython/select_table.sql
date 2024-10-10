CREATE OR REPLACE FUNCTION
py_select_highest_score()
RETURNS TABLE( who text, score int )
AS $CODE$
   query = "SELECT person || ' (' || team || ')' as person, score FROM scores;"
   tuples = plpy.execute( query )  # plpy automatically imported

   highest = { 'who' : None, 'score' : 0 }
   for t in tuples:
       if t[ 'score' ] > highest[ 'score' ]:
       	  highest[ 'who' ]   = t[ 'person' ]
          highest[ 'score' ] = t[ 'score' ]

   # returns a table, so use a list
   return [ highest ]
$CODE$
LANGUAGE plpython3u;



--
-- This implementation uses the tuple reference as the value to return
-- but it needs to ensure that the tuple has the right column names
-- as the output will be (so alias the column as 'who').
--
CREATE OR REPLACE FUNCTION
py_select_highest_score()
RETURNS TABLE( who text, score int )
AS $CODE$
   query = "SELECT person || ' (' || team || ')' as who, score FROM scores;"
   tuples = plpy.execute( query )  # plpy automatically imported

   highest = { 'who' : None, 'score' : 0 }
   for t in tuples:
       if t[ 'score' ] > highest[ 'score' ]:
       	  highest = t

   # returns a table, so use a list
   return [ highest ]
$CODE$
LANGUAGE plpython3u;




--
-- Given an input argument, selects the best score UNDER such value.
--
-- Note the usage of global to assign to the input variable.
CREATE OR REPLACE FUNCTION
py_select_highest_score( threshold int DEFAULT NULL )
RETURNS TABLE( who text, score int )
AS $CODE$
   query = "SELECT person || ' (' || team || ')' as who, score FROM scores WHERE score <= $1;"

   global threshold                                            # note usage of global!
   if threshold is None or threshold < 0:
      threshold = 0

   prepared_statement = plpy.prepare( query, [ 'int' ] )       # note usage of list of parameter types
   tuples = plpy.execute( prepared_statement, [ threshold ] )  # note usage of list of parameter values

   highest = None
   for t in tuples:
       if highest is None or t[ 'score' ] > highest[ 'score' ]:
       	  highest = t

   # returns a table, so use a list
   return [ highest ]
$CODE$
LANGUAGE plpython3u;
