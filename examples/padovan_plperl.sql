-- Pl/Perl implementation using %_SHARED

CREATE OR REPLACE FUNCTION
plperl_padovan_init()
RETURNS VOID
AS $CODE$
  my $padovan;
  $padovan = sub {
    return 1 if $_[0] <= 2;
    return $padovan->( $_[0] - 3 ) + $padovan->( $_[0] - 2 );
  };

  $_SHARED{ padovan } = $padovan;
$CODE$
LANGUAGE plperl;


SELECT plperl_padovan_init();

CREATE OR REPLACE FUNCTION
plperl_padovan_shared( int )
RETURNS int
AS $CODE$
  my $padovan = $_SHARED{ padovan };
  return $padovan->( $_[0] );
$CODE$
LANGUAGE plperl;


---------------------------------------------------
-- Using Sub::Recursive (requires the module and plperlu)

CREATE OR REPLACE FUNCTION
plperl_padovan( int )
RETURNS int
AS $CODE$
use Sub::Recursive;
my $padovan = recursive {
    return 1 if $_[0] <= 2;
    return $REC->( $_[0] - 3 ) + $REC->( $_[0] - 2 );
};

  return &$padovan( $_[0] );
$CODE$
LANGUAGE plperlu;


-----------------------------------------------------
-- Using old plain recursion

CREATE OR REPLACE FUNCTION
plperl_padovan_recursive( int )
RETURNS int
AS $CODE$
  my $padovan;
  $padovan = sub {
    return 1 if $_[0] <= 2;
    return $padovan->( $_[0] - 3 ) + $padovan->( $_[0] - 2 );
  };

  return $padovan->( $_[0] );
$CODE$
LANGUAGE plperl;
