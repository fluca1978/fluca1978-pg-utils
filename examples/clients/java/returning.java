/*
 * Sample Java client to demonstrate the usage of the RETURNING predicate.
 * It can be simply used as a result set.
 *
 * Assuming there is a table created as follows:

 CREATE TABLE foo( pk serial, rv float );

 launching this program provides an output similar to the following:

  The statement inserted pk = 21 and a random value rv = 0.508654
  The statement inserted pk = 22 and a random value rv = 0.036699
  The statement inserted pk = 23 and a random value rv = 0.667510
  The statement inserted pk = 24 and a random value rv = 0.376419
  The statement inserted pk = 25 and a random value rv = 0.686661
  The statement inserted pk = 26 and a random value rv = 0.076212
  The statement inserted pk = 27 and a random value rv = 0.380505
  The statement inserted pk = 28 and a random value rv = 0.299493
  The statement inserted pk = 29 and a random value rv = 0.303107
  The statement inserted pk = 30 and a random value rv = 0.512332
*/

import java.sql.*;
import java.util.*;

class returning {
    public static void main( String argv[] ) throws Exception {
        Class.forName( "org.postgresql.Driver" );
        String connectionURL = "jdbc:postgresql://localhost/testdb";
        Properties connectionProperties = new Properties();
        connectionProperties.put( "user", "luca" );
        connectionProperties.put( "password", "xyz" );
        Connection conn = DriverManager.getConnection( connectionURL, connectionProperties );

        String query = "INSERT INTO foo( rv ) "
            + " SELECT random() "
            + " FROM generate_series( 1, 10 ) "
            + " RETURNING pk, rv;";

        Statement statement = conn.createStatement();
        ResultSet resultSet = statement.executeQuery( query );
        while ( resultSet.next() )
            System.out.println( String.format( "The statement inserted pk = %d and a random value rv = %f ",
                                               resultSet.getLong( "pk" ),
                                               resultSet.getFloat( "rv" ) ) );

        resultSet.close();
        statement.close();
    }
}
