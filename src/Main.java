/*
Run the following before this, tailored to where they are in your filesystem:

mysql> source C:\Users\jw\Desktop\fall18\db\Twitter\sql\init_tables.sql
mysql> source C:\Users\jw\Desktop\fall18\db\Twitter\sql\init_stored_procs.sql
mysql> source C:\Users\jw\Desktop\fall18\db\Twitter\sql\add_synth_data.sql

C:\java Main <your_db_password>

Connecting to database...
help: show help
create_user <name>: create a new account
info_user <name>: show user info by name
suggest <name>: suggest people for the given user to follow
hot: show most liked tweets in the past 24 hours
info_user Alice
User Alice has 0 followers and follows 4 people:
{Iron Maiden, Judas Priest, Lesser Known Band, Metallica}
suggest Bob
Hey Bob, people who follow similar users as you also follow:
{Lesser Known Band}
info_user Bob
User Bob has 0 followers and follows 3 people:
{Iron Maiden, Judas Priest, Metallica}
hot
The most liked tweets of the past 24 hours:username, time, likes, {text}
Bob, 2018-11-10, +1, {Yes, I can Build it.}
Alice, 2018-11-10, +0, {My name is Alice.}
Alice, 2018-11-10, +0, {Good weather today.}
Alice, 2018-11-10, +0, {That last episode of that show was a real thriller}
create_user Bob
Could not create account Bob, name already taken
create_user Eve
Created account named: Eve
exit
Server closing.

Process finished with exit code 0
 */

//STEP 1. Import required packages
import java.sql.*;

import java.util.HashMap;
import java.util.Scanner;

//All sql stuff seems to be 1 indexed based

class RsUtil {
    static void printStringList(ResultSet rs) throws java.sql.SQLException{
        if (rs.next()) {
            System.out.print("{" + rs.getString(1));
            while (rs.next()) {
                System.out.print(", " + rs.getString(1));
            }
            System.out.println("}");
            rs.close();//@X:
        }
        else
            System.out.println("{}");
    }
}

//I think should have just made a switch stmt?
//showing 24 hour most liked not in java here, but is in sql file.
abstract class CommandHandler {
    abstract void handleCmd(Scanner scin, Connection conn) throws java.sql.SQLException;

    static final String[] cmdStrs = {
            "help",
            "create_user",
            "info_user",
            "suggest",
            "hot",
    };

    static final String[] descStrs = {
            ": show help",
            " <name>: create a new account",
            " <name>: show user info by name",
            " <name>: suggest people for the given user to follow",
            ": show most liked tweets in the past 24 hours",
    };

    static void printHelp() {
        for (int i=0; i!=cmdStrs.length; ++i)
            System.out.println(cmdStrs[i]+descStrs[i]);
    }
}

class HelpHandler extends CommandHandler {
    @Override
    void handleCmd(Scanner scin, Connection conn) throws java.sql.SQLException {
        printHelp();
    }
}


class CreateUserHandler extends CommandHandler {
    @Override
    void handleCmd(Scanner scin, Connection conn) throws java.sql.SQLException{
        String name = scin.next();
        CallableStatement cs = conn.prepareCall("{CALL createUser(?)}");
        cs.setString(1,name);
        // @X: not sure if doing this right, possible that the account name is already taken
        // and want to tell the user that

        // https://docs.oracle.com/javase/7/docs/api/java/sql/PreparedStatement.html#execute()
        // Returns true if the first result is a ResultSet object; false if the first result is an update count or there is no result
        try {
            cs.execute();//so how do I check if it succeeded?
            // java.sql.SQLIntegrityConstraintViolationException: Duplicate entry 'JavaTestUser0' for key 'name'
            // I guess thats how?
            System.out.println("Created account named: " + name);
        }
        catch (java.sql.SQLIntegrityConstraintViolationException exc) {
            System.out.printf("Could not create account %s, name already taken\n", name);
        }
        cs.close();//@X

    }
}

class InfoUserHandler extends CommandHandler {
    @Override
    void handleCmd(Scanner scin, Connection conn) throws java.sql.SQLException {
        String name = scin.next();
        CallableStatement cs = conn.prepareCall("{CALL showUserInfoAndFollowing(?, ?, ?)}");
        cs.setString(1,name);
        cs.registerOutParameter(2, Types.INTEGER);//nfollowers
        cs.registerOutParameter(3, Types.INTEGER);//nfollowing, should be size of result set
        if (cs.execute()) {
            System.out.printf("User %s has %d followers and follows %d people:\n",
                    name, cs.getInt(2), cs.getInt(3));
            RsUtil.printStringList(cs.getResultSet());
        }
        cs.close();//@X
    }
}

class SuggestUsersToFollowHandler extends CommandHandler {
    @Override
    void handleCmd(Scanner scin, Connection conn) throws java.sql.SQLException{
        String name = scin.next();
        CallableStatement cs = conn.prepareCall("{CALL newFollowSuggestionsForName(?)}");
        cs.setString(1,name);
        if (cs.execute()) {
            System.out.printf("Hey %s, people who follow similar users as you also follow:\n", name);
            RsUtil.printStringList(cs.getResultSet());
        }
        cs.close();//@X
    }
}

/*
  select name, timeMade, nLikes, bodyText
  from (select uID, timeMade, nLikes, bodyText from Tweet where TIMESTAMPDIFF(SECOND, now(), timeMade)<86400) as T, User
  where User.uID = T.uID
  order by nLikes;
 */
class PastDayMostLikedTweetsHandler extends CommandHandler {
    @Override
    void handleCmd(Scanner scin, Connection conn) throws java.sql.SQLException{
        CallableStatement cs = conn.prepareCall("{CALL show24HourMostLiked()}");
        if (cs.execute()) {
            System.out.println("The most liked tweets of the past 24 hours:"
            +"username, time, likes, {text}");
            ResultSet rs= cs.getResultSet();
            while (rs.next()) {
                System.out.printf("%s, %s, +%d, {%s}\n",
                        rs.getString(1),
                        rs.getDate(2).toString(),
                        rs.getInt(3),
                        rs.getString(4));
            }
        }
        cs.close();//@X
    }
}

public class Main {
    // JDBC driver name and database URL
    static final String DB_URL = "jdbc:mysql://localhost/Twitter";
    // Database credentials
    static final String USER = "root";
    // Until we agree on a password, I have it passed in as first cmdline arg[0]

    public static final HashMap<String, CommandHandler> cmdmap = initCmdMap();

    private static HashMap<String, CommandHandler> initCmdMap()
    {
        HashMap<String, CommandHandler> m = new HashMap<>();
        m.put(CommandHandler.cmdStrs[0], new HelpHandler());
        m.put(CommandHandler.cmdStrs[1], new CreateUserHandler());
        m.put(CommandHandler.cmdStrs[2], new InfoUserHandler());
        m.put(CommandHandler.cmdStrs[3], new SuggestUsersToFollowHandler());
        m.put(CommandHandler.cmdStrs[4], new PastDayMostLikedTweetsHandler());
        return m;
    }

    static
    void commandLoop(Connection conn) throws java.sql.SQLException {

        Statement stmt = null;
        boolean bQuit = false;
        Scanner scin = new Scanner(System.in);

        while (scin.hasNext()) {
            String cmd = scin.next();

            if ("exit".equalsIgnoreCase(cmd) || "Q".equalsIgnoreCase(cmd))
                break;

            CommandHandler fn= cmdmap.get(cmd);
            if (fn!=null) {
                fn.handleCmd(scin, conn);
            }
            else {
                System.out.println("Invalid command: "+cmd);
            }
        }
    }

    public static void main(String[] args) {

        String passwd;//until maybe we agree on a password, could use different user too.
        if (args.length != 1) {
            System.out.println("Please supply a password for DB user: " + USER);
            System.exit(-1);
        }
        passwd = args[0];

        Connection conn = null;
        System.out.println("Connecting to database...");

        try {
            //STEP 3: Open a connectio
            conn = DriverManager.getConnection(DB_URL, USER, passwd);
        } catch (Exception e) {//SQLException or SQLTimeoutException
            System.out.println("Failed to connect to: "+DB_URL+"\nException: "+e.getMessage());
            e.printStackTrace();
            System.exit(-1);
        }

        CommandHandler.printHelp();

        try {
            commandLoop(conn);
        }catch(SQLException se){
            se.printStackTrace();
        }finally{
            //finally block used to close resources{
            try{
                if(conn!=null)
                    conn.close();
            }catch(SQLException se){
                se.printStackTrace();
            }//end finally try
        }//end try

        System.out.println("Server closing.");
    }//end main
}//end JDBCExample
