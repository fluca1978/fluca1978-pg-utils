--
-- Demo event trigger
--
-- Create with
--
-- create event trigger tr_demo on ddl_command_end execute function f_event_trigger_demo();
--

CREATE OR REPLACE FUNCTION
f_event_trigger_demo()
RETURNS EVENT_TRIGGER
AS
$code$
DECLARE
event_tuple record;
BEGIN
   RAISE INFO 'Event trigger function called ';
   FOR event_tuple IN SELECT *
                      FROM pg_event_trigger_ddl_commands()  LOOP
                      RAISE INFO 'TAG [%] COMMAND [%]', event_tuple.command_tag, event_tuple.object_type;
   END LOOP;
END
$code$
LANGUAGE plpgsql;
