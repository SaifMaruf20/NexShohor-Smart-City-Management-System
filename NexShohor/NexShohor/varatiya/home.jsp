<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "Varatia";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String tenantEmail = _sessionEmail;
String tenantName  = _sessionUser;

int totalProperties  = 0;
int pendingRequests  = 0;
int approvedRequests = 0;
int rejectedRequests = 0;

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();

    ps = con.prepareStatement("SELECT COUNT(*) FROM HOUSE_POST WHERE STATUS='Available'");
    rs = ps.executeQuery(); if (rs.next()) totalProperties = rs.getInt(1);
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT COUNT(*) FROM TENANT_REQUESTS WHERE TENANT_EMAIL=? AND STATUS='Pending'");
    ps.setString(1, tenantEmail); rs = ps.executeQuery();
    if (rs.next()) pendingRequests = rs.getInt(1);
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT COUNT(*) FROM TENANT_REQUESTS WHERE TENANT_EMAIL=? AND STATUS='Approved'");
    ps.setString(1, tenantEmail); rs = ps.executeQuery();
    if (rs.next()) approvedRequests = rs.getInt(1);
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT COUNT(*) FROM TENANT_REQUESTS WHERE TENANT_EMAIL=? AND STATUS='Rejected'");
    ps.setString(1, tenantEmail); rs = ps.executeQuery();
    if (rs.next()) rejectedRequests = rs.getInt(1);
    rs.close(); ps.close();

} catch(Exception e) {
    logError("VaBody.jsp", e);
} finally {
    closeDB(con, ps, rs);
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Varatia Dashboard – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.welcome-box { padding:28px 32px; margin-bottom:26px; }
.welcome-box h3 { font-weight:800; color:#fff; font-size:1.7rem; }
.welcome-box p  { color:rgba(255,255,255,0.75); margin-top:6px; }
.action-card { padding:24px; text-decoration:none; display:block; color:inherit; transition:0.3s; }
.action-card:hover { transform:translateY(-5px); }
.action-card h5 { color:#fff; font-weight:700; margin-bottom:6px; }
.action-card p  { color:var(--text-muted); font-size:0.85rem; margin:0; }
.action-icon   { font-size:2rem; margin-bottom:10px; }
.bv-stat { transition:0.3s ease; }
.bv-stat:hover { transform:translateY(-5px) scale(1.03); }
</style>
</head>
<body>
<%@ include file="../varatiya/nav.jsp" %>

<div class="bv-container">

    <!-- WELCOME -->
    <div class="glass welcome-box">
        <div style="font-size:2rem; color:var(--accent); margin-bottom:10px;">&#128247;</div>
        <h3>Welcome, <%= sanitize(tenantName) %>!</h3>
        <p>Find your perfect home, submit rental requests, and track your applications.</p>
    </div>


    <!-- URBAN SERVICES -->
    <div class="bv-section-title">Urban Services</div>
    <div class="bv-grid bv-grid-3" style="margin-bottom:32px;">

      <div class="glass" style="padding:24px;">
        <a href="../user/transport.jsp" style="text-decoration:none;color:inherit;">
          <div style="font-size:2rem;color:var(--blue);margin-bottom:10px;">&#128652;</div>
          <h5 style="color:#fff;font-weight:700;margin-bottom:6px;">Transport &amp; Safety</h5>
          <p style="color:var(--text-muted);font-size:0.85rem;margin:0;">
            Live incidents, crowd reports and safety alerts.
          </p>
        </a>
      </div>

      <div class="glass" style="padding:24px;">
        <a href="../user/emergency.jsp" style="text-decoration:none;color:inherit;">
          <div style="font-size:2rem;color:var(--danger);margin-bottom:10px;">&#128680;</div>
          <h5 style="color:#fff;font-weight:700;margin-bottom:6px;">Emergency Services</h5>
          <p style="color:var(--text-muted);font-size:0.85rem;margin:0;">
            Find hospitals, police, fire stations and send SOS.
          </p>
        </a>
      </div>

      <div class="glass" style="padding:24px;">
        <a href="../user/alerts.jsp" style="text-decoration:none;color:inherit;">
          <div style="font-size:2rem;color:var(--warn);margin-bottom:10px;">&#128227;</div>
          <h5 style="color:#fff;font-weight:700;margin-bottom:6px;">Urban Alerts</h5>
          <p style="color:var(--text-muted);font-size:0.85rem;margin:0;">
            Water outages, roadblocks, strikes and weather alerts.
          </p>
        </a>
      </div>

    </div>

    <!-- STATS -->
    <div class="bv-section-title">Overview</div>
    <div class="bv-grid bv-grid-4" style="margin-bottom:28px;">

        <a href="browse.jsp" style="text-decoration:none;">
            <div class="glass bv-stat" style="padding:20px;text-align:center;">
                <div class="bv-stat-icon" style="color:var(--blue);">&#127963;</div>
                <div class="bv-stat-num" style="color:var(--blue);"><%= totalProperties %></div>
                <div class="bv-stat-lbl">Available Properties</div>
            </div>
        </a>

        <a href="myRequests.jsp?status=Pending" style="text-decoration:none;">
            <div class="glass bv-stat" style="padding:20px;text-align:center;">
                <div class="bv-stat-icon" style="color:var(--warn);">&#9203;</div>
                <div class="bv-stat-num" style="color:var(--warn);"><%= pendingRequests %></div>
                <div class="bv-stat-lbl">Pending Requests</div>
            </div>
        </a>

        <a href="myRequests.jsp?status=Approved" style="text-decoration:none;">
            <div class="glass bv-stat" style="padding:20px;text-align:center;">
                <div class="bv-stat-icon" style="color:var(--success);">&#10003;</div>
                <div class="bv-stat-num" style="color:var(--success);"><%= approvedRequests %></div>
                <div class="bv-stat-lbl">Approved</div>
            </div>
        </a>

        <a href="myRequests.jsp?status=Rejected" style="text-decoration:none;">
            <div class="glass bv-stat" style="padding:20px;text-align:center;">
                <div class="bv-stat-icon" style="color:var(--danger);">&#10005;</div>
                <div class="bv-stat-num" style="color:var(--danger);"><%= rejectedRequests %></div>
                <div class="bv-stat-lbl">Rejected</div>
            </div>
        </a>

    </div>

    <!-- QUICK ACTIONS -->
    <div class="bv-section-title">Quick Actions</div>
    <div class="bv-grid bv-grid-3">

        <div class="glass action-card">
            <a href="browse.jsp" style="text-decoration:none;color:inherit;">
                <div class="action-icon" style="color:var(--success);">&#128269;</div>
                <h5>Browse Properties</h5>
                <p>Explore all available houses and flats listed by landlords.</p>
            </a>
        </div>

        <div class="glass action-card">
            <a href="myRequests.jsp" style="text-decoration:none;color:inherit;">
                <div class="action-icon" style="color:var(--warn);">&#128203;</div>
                <h5>My Requests</h5>
                <p>Track the status of all your submitted rental requests.</p>
            </a>
        </div>

        <div class="glass action-card">
            <a href="vaProfile.jsp" style="text-decoration:none;color:inherit;">
                <div class="action-icon" style="color:var(--blue);">&#128100;</div>
                <h5>My Profile</h5>
                <p>View your personal account information.</p>
            </a>
        </div>

    </div>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
