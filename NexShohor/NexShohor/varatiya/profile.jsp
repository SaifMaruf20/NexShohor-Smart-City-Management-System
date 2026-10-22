<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
String _requiredRole = "Varatia";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String tenantEmail = _sessionEmail;
String profileName="", profilePhone="", profileBirth="", profileType="";

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    ps  = con.prepareStatement(
        "SELECT name,phone,TO_CHAR(birthdate,'DD Mon YYYY') AS bdate,userType " +
        "FROM nexshohor_users WHERE email=?");
    ps.setString(1, tenantEmail); rs = ps.executeQuery();
    if (rs.next()) {
        profileName  = rs.getString("name")     != null ? rs.getString("name")     : "";
        profilePhone = rs.getString("phone")    != null ? rs.getString("phone")    : "";
        profileBirth = rs.getString("bdate")    != null ? rs.getString("bdate")    : "";
        profileType  = rs.getString("userType") != null ? rs.getString("userType") : "Varatia";
    }
} catch(Exception e) {
    logError("vaProfile.jsp", e);
    profileName = _sessionUser;
} finally { closeDB(con, ps, rs); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Profile – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.profile-card { max-width:480px; margin:32px auto; overflow:hidden; }
.profile-hdr  {
    background:linear-gradient(135deg,var(--accent-dark),var(--accent));
    padding:32px 24px; text-align:center; color:#000;
}
.profile-avatar {
    width:84px; height:84px; border-radius:50%;
    background:rgba(0,0,0,0.18); display:flex;
    align-items:center; justify-content:center;
    font-size:2.6rem; margin:0 auto 12px;
    border:3px solid rgba(0,0,0,0.2);
}
.profile-hdr h5 { font-weight:800; font-size:1.2rem; margin-bottom:4px; }
.profile-hdr span { font-size:0.88rem; opacity:0.75; }
.profile-body { padding:26px; }
.info-row {
    display:flex; align-items:center; padding:12px 0;
    border-bottom:1px solid rgba(255,255,255,0.07);
}
.info-row:last-child { border-bottom:none; }
.info-icon {
    width:36px; height:36px; border-radius:8px;
    background:rgba(32,201,151,0.15); display:flex;
    align-items:center; justify-content:center;
    font-size:1.1rem; margin-right:14px; flex-shrink:0; color:var(--accent);
}
.info-label { font-size:0.75rem; color:var(--text-muted); font-weight:600;
              text-transform:uppercase; letter-spacing:0.4px; }
.info-value { font-weight:500; color:#fff; font-size:0.92rem; }
</style>
</head>
<body>
<%@ include file="../varatiya/nav.jsp" %>

<div class="bv-container">
<div class="glass profile-card">

    <div class="profile-hdr">
        <div class="profile-avatar">&#128100;</div>
        <h5><%= sanitize(profileName) %></h5>
        <span>&#10004; Varatia (Tenant)</span>
    </div>

    <div class="profile-body">

        <div class="info-row">
            <div class="info-icon">&#128100;</div>
            <div>
                <div class="info-label">Full Name</div>
                <div class="info-value"><%= sanitize(profileName) %></div>
            </div>
        </div>

        <div class="info-row">
            <div class="info-icon">&#9993;</div>
            <div>
                <div class="info-label">Email Address</div>
                <div class="info-value"><%= sanitize(tenantEmail) %></div>
            </div>
        </div>

        <div class="info-row">
            <div class="info-icon">&#128222;</div>
            <div>
                <div class="info-label">Phone Number</div>
                <div class="info-value"><%= !profilePhone.isEmpty() ? sanitize(profilePhone) : "—" %></div>
            </div>
        </div>

        <div class="info-row">
            <div class="info-icon">&#128197;</div>
            <div>
                <div class="info-label">Date of Birth</div>
                <div class="info-value"><%= !profileBirth.isEmpty() ? sanitize(profileBirth) : "—" %></div>
            </div>
        </div>

        <div class="info-row">
            <div class="info-icon">&#128737;</div>
            <div>
                <div class="info-label">Account Type</div>
                <div class="info-value"><%= sanitize(profileType) %></div>
            </div>
        </div>

        <div style="display:flex;gap:10px;margin-top:22px;">
            <a href="VaBody.jsp"           class="bv-btn bv-btn-outline" style="flex:1;text-align:center;">&#8592; Dashboard</a>
            <a href="../user/logout.jsp"   class="bv-btn bv-btn-danger"  style="flex:1;text-align:center;">&#128682; Logout</a>
        </div>

    </div>
</div>
</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
