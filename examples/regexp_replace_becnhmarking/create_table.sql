CREATE TABLE benchmark_replace
    (
      pk int generated always as identity
     , text_to_translate text
     , text_translated   text
     , ms float
     , replacement_type text default 'replace'
     , primary key( pk )
    );
