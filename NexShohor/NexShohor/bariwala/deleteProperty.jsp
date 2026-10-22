<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
String _requiredRole = "Bariwala";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String idParam = request.getParameter("id");
if (idParam == null || idParam.trim().isEmpty()) { response.sendRedirect("manageHouse.jsp"); return; }

int postId;
try { postId = Integer.parseInt(idParam.trim()); }
catch(NumberFormatException nfe) { response.sendRedirect("manageHouse.jsp"); return; }

String ownerEmail = _sessionEmail;

Connection con = null; PreparedStatement ps = null;
try {
    con = getConnection();
    con.setAutoCommit(false);
    // Only delete if it belongs to this owner (ownership verification)
    ps = con.prepareStatement("DELETE FROM HOUSE_POST WHERE POST_ID=? AND OWNER_EMAIL=?");
    ps.setInt(1, postId);
    ps.setString(2, ownerEmail);
    ps.executeUpdate();
    con.commit();
} catch(Exception e) {
    if (con != null) try { con.rollback(); } catch(Exception ig){}
    logError("deleteHouse.jsp", e);
} finally {
    closeDB(con, ps, null);
}

response.sendRedirect("manageHouse.jsp");
%>
