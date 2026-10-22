<%-- ============================================================
     includes/db.jsp  –  Central JDBC connection factory
     Usage: <%@ include file="../includes/db.jsp" %>
            Connection con = getConnection();
     All pages that use getConnection() must call closeDB(con,ps,rs)
     ============================================================ --%>
<%@ page import="java.sql.*" %>
<%!
    /* ── DB CONSTANTS ─────────────────────────────────────────── */
    static final String DB_URL    = "jdbc:oracle:thin:@localhost:1521:xe";
    static final String DB_USER   = "system";
    static final String DB_PASS   = "your_password";

    /* ── DRIVER LOADER (called once per JVM) ─────────────────── */
    static {
        try { Class.forName("oracle.jdbc.driver.OracleDriver"); }
        catch(ClassNotFoundException e) { throw new RuntimeException("NexShohor: Oracle JDBC driver not found", e); }
    }

    /* ── CONNECTION FACTORY ──────────────────────────────────── */
    public Connection getConnection() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }

    /* ── SAFE RESOURCE CLOSER ────────────────────────────────── */
    public void closeDB(Connection con, PreparedStatement ps, ResultSet rs) {
        try { if (rs  != null) rs.close();  } catch(Exception ignored){}
        try { if (ps  != null) ps.close();  } catch(Exception ignored){}
        try { if (con != null) con.close(); } catch(Exception ignored){}
    }

    /* ── SIMPLE LOGGER (writes to server log) ────────────────── */
    public void logError(String page, Exception e) {
        System.err.println("[NexShohor][" + page + "] " + e.getMessage());
        e.printStackTrace(System.err);
    }

    /* ── XSS SANITIZER ───────────────────────────────────────── */
    public String sanitize(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#x27;");
    }
%>
