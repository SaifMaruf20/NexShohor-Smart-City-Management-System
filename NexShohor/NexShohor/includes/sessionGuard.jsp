<%-- ============================================================
     includes/sessionGuard.jsp  – Session + ban check
     Usage at top of any protected page:
       <%
         String _requiredRole = "Bariwala";  // or "Varatia" or ""
       %>
       <%@ include file="../includes/sessionGuard.jsp" %>
     ============================================================ --%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache");
response.setDateHeader("Expires", 0);

String _sessionUser  = (String) session.getAttribute("user");
String _sessionType  = (String) session.getAttribute("userType");
String _sessionEmail = (String) session.getAttribute("userEmail");

if (_sessionUser == null || _sessionEmail == null) {
    response.sendRedirect(request.getContextPath() + "/user/login.jsp");
    return;
}

/* ── Ban check on every request ─────────────────────────── */
Connection _sgCon=null; PreparedStatement _sgPs=null; ResultSet _sgRs=null;
try {
    _sgCon = getConnection();
    _sgPs  = _sgCon.prepareStatement("SELECT is_banned FROM nexshohor_users WHERE email=?");
    _sgPs.setString(1, _sessionEmail);
    _sgRs  = _sgPs.executeQuery();
    if (_sgRs.next() && _sgRs.getInt("is_banned") == 1) {
        session.invalidate();
        response.sendRedirect(request.getContextPath() + "/user/login.jsp?banned=1");
        return;
    }
} catch(Exception _sgEx) { /* non-critical; allow through */ }
finally { closeDB(_sgCon, _sgPs, _sgRs); }

/* ── Role-based check ────────────────────────────────────── */
try {
    if (_requiredRole != null && !_requiredRole.isEmpty()) {
        if (!_requiredRole.equalsIgnoreCase(_sessionType)) {
            session.invalidate();
            response.sendRedirect(request.getContextPath() + "/user/login.jsp");
            return;
        }
    }
} catch(Exception _roleEx) { /* _requiredRole not declared — any logged-in user allowed */ }
%>
