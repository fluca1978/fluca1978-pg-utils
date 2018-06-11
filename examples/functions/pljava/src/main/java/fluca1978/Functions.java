package fluca1978;

import org.postgresql.pljava.annotation.Function;
import org.postgresql.pljava.*;
import java.sql.*;
import java.util.logging.Logger;

//import org.postgresql.pljava.annotation.Function.Effects.STABLE;
//import org.postgresql.pljava.annotation.Function.OnNullInput.RETURNS_NULL;

public class Functions {


    @Function(
	      comment = "Concatenates two strings with an optional delimiter. Accepts null values"
	      , name  = "fluca1978_concat" // or defaults to function name
	      , effects = Function.Effects.STABLE
	      , onNullInput = Function.OnNullInput.RETURNS_NULL
	      )
    public static String concat( String s1, String s2, String separator ){
	if ( s1 == null )
	    s1 = "<NULL>";

	if ( s2 == null )
	    s2 = "<NULL>";

	if ( separator == null )
	    separator = "<->";

	return s1 + separator + s2;
    }



    public static void upperText( TriggerData td ) throws SQLException {
	Logger logger = Logger.getAnonymousLogger();
	
	if ( td.isFiredBefore() && td.isFiredForEachRow() ){
	    ResultSet NEW = td.getNew();
	    logger.info( "Trigger invocato per ogni tupla, evento before!" );
	    
	    for ( String columnToUpdate : td.getArguments() ){
		logger.info( "Update colonna " + columnToUpdate );
		NEW.updateString( columnToUpdate,
				  NEW.getString( columnToUpdate ).toUpperCase() );
	    }
	}
    }
}
