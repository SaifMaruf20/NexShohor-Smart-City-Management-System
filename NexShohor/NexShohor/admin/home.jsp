<%-- ============================================================
     admin/home.jsp — upgraded with new KPI tiles
     FIXES: removed Bootstrap, removed hardcoded CSS vars,
            fixed session attr "adminName" → "user",
            used proper getConnection()/closeDB() pattern,
            used bv- CSS classes throughout
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache"); response.setDateHeader("Expires", 0);
if (!"admin".equalsIgnoreCase((String) session.getAttribute("userType"))) {
    response.sendRedirect(request.getContextPath() + "/admin/login.jsp?msg=noaccess"); return;
}
String adminName = (String) session.getAttribute("user");

/* ── KPI queries — each with own connection ──────────────── */
int bariWalaCount=0, varatiaCount=0, availableCount=0, pendingRequests=0;
int openIncidents=0, pendingSOS=0, activeAlerts=0;

String[][] queries = {
    {"SELECT COUNT(*) FROM nexshohor_users WHERE LOWER(userType)='bariwala'", "bw"},
    {"SELECT COUNT(*) FROM nexshohor_users WHERE LOWER(userType)='varatia'",  "va"},
    {"SELECT COUNT(*) FROM HOUSE_POST WHERE STATUS='Available'",             "av"},
    {"SELECT COUNT(*) FROM TENANT_REQUESTS WHERE STATUS='Pending'",          "pr"},
    {"SELECT COUNT(*) FROM INCIDENTS WHERE STATUS='Open'",                   "oi"},
    {"SELECT COUNT(*) FROM SOS_LOGS WHERE IS_RESOLVED=0",                    "ps"},
    {"SELECT COUNT(*) FROM URBAN_ALERTS WHERE IS_ACTIVE=1",                  "aa"}
};

for (String[] q : queries) {
    Connection c=null; PreparedStatement p=null; ResultSet r=null;
    try {
        c=getConnection(); p=c.prepareStatement(q[0]); r=p.executeQuery();
        if (r.next()) {
            int val = r.getInt(1);
            switch(q[1]) {
                case "bw": bariWalaCount   = val; break;
                case "va": varatiaCount    = val; break;
                case "av": availableCount  = val; break;
                case "pr": pendingRequests = val; break;
                case "oi": openIncidents   = val; break;
                case "ps": pendingSOS      = val; break;
                case "aa": activeAlerts    = val; break;
            }
        }
    } catch(Exception e) { logError("admin/home.jsp", e); }
    finally { closeDB(c, p, r); }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Admin Dashboard — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head>
<body>
<%@ include file="../admin/nav.jsp" %>

<div class="bv-container">

    <div class="glass bv-page-header" style="margin-bottom:28px;">
        <div>
            <h4>&#9881; Admin Dashboard</h4>
            <p>Welcome back, <strong style="color:var(--accent);"><%=sanitize(adminName)%></strong> — here's your platform overview</p>
        </div>
    </div>

    <%-- KPI Grid --%>
    <div class="bv-grid bv-grid-4" style="margin-bottom:32px;">

        <div class="glass bv-stat">
            <div class="bv-stat-icon" style="color:var(--blue);">&#127968;</div>
            <div class="bv-stat-num" style="color:var(--blue);"><%=bariWalaCount%></div>
            <div class="bv-stat-lbl">BariWala Users</div>
        </div>

        <div class="glass bv-stat">
            <div class="bv-stat-icon" style="color:var(--success);">&#128101;</div>
            <div class="bv-stat-num" style="color:var(--success);"><%=varatiaCount%></div>
            <div class="bv-stat-lbl">Varatia Users</div>
        </div>

        <div class="glass bv-stat">
            <div class="bv-stat-icon" style="color:var(--accent);">&#127968;</div>
            <div class="bv-stat-num" style="color:var(--accent);"><%=availableCount%></div>
            <div class="bv-stat-lbl">Available Properties</div>
        </div>

        <div class="glass bv-stat">
            <div class="bv-stat-icon" style="color:var(--warn);">&#128203;</div>
            <div class="bv-stat-num" style="color:var(--warn);"><%=pendingRequests%></div>
            <div class="bv-stat-lbl">Pending Requests</div>
        </div>

        <div class="glass bv-stat">
            <div class="bv-stat-icon" style="color:#fb923c;">&#128652;</div>
            <div class="bv-stat-num" style="color:#fb923c;"><%=openIncidents%></div>
            <div class="bv-stat-lbl">Open Incidents</div>
        </div>

        <div class="glass bv-stat">
            <div class="bv-stat-icon" style="color:var(--danger);">&#128721;</div>
            <div class="bv-stat-num" style="color:var(--danger);"><%=pendingSOS%></div>
            <div class="bv-stat-lbl">Pending SOS</div>
        </div>

        <div class="glass bv-stat">
            <div class="bv-stat-icon" style="color:#c4b5fd;">&#127758;</div>
            <div class="bv-stat-num" style="color:#c4b5fd;"><%=activeAlerts%></div>
            <div class="bv-stat-lbl">Active Alerts</div>
        </div>

    </div>

    <%-- Quick Links --%>
    <div class="glass" style="padding:24px 28px;">
        <div style="font-weight:700;color:#fff;margin-bottom:16px;font-size:0.95rem;">&#9889; Quick Actions — New Modules</div>
        <div style="display:flex;gap:10px;flex-wrap:wrap;">
            <a href="../admin/transport.jsp"  class="bv-btn bv-btn-outline">&#128652; Transport Admin</a>
            <a href="../admin/emergency.jsp"  class="bv-btn bv-btn-outline">&#128657; Emergency Admin</a>
            <a href="../admin/sos.jsp"        class="bv-btn bv-btn-danger" >&#128721; SOS Admin</a>
            <a href="../admin/alerts.jsp"     class="bv-btn bv-btn-outline">&#127758; Alerts Admin</a>
            <a href="../admin/settings.jsp"  class="bv-btn bv-btn-outline">&#9881; System Settings</a>
        </div>
    </div>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
