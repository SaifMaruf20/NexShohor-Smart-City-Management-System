<%-- ============================================================
     Emergency/sosStatus.jsp
     Session required (Bariwala or Varatia)
     User tracks their own SOS logs
     IS_RESOLVED status display + auto-refresh every 30s
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "";  /* any logged-in user */
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String userEmail = (String) session.getAttribute("userEmail");
String userType  = (String) session.getAttribute("userType");

/* ── Fetch this user's SOS logs ──────────────────────────── */
java.util.List<java.util.Map<String,String>> sosList = new java.util.ArrayList<>();
Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    ps  = con.prepareStatement(
        "SELECT s.SOS_ID, s.SERVICE_TYPE, s.AREA, s.DESCRIPTION, " +
        "       s.IS_RESOLVED, s.ADMIN_NOTE, s.CREATED_AT, s.RESOLVED_AT, " +
        "       es.NAME AS ASSIGNED_NAME, es.PHONE AS ASSIGNED_PHONE " +
        "FROM SOS_LOGS s " +
        "LEFT JOIN EMERGENCY_SERVICES es ON s.ASSIGNED_SERVICE_ID = es.SERVICE_ID " +
        "WHERE s.USER_EMAIL = ? " +
        "ORDER BY s.CREATED_AT DESC"
    );
    ps.setString(1, userEmail);
    rs = ps.executeQuery();
    while (rs.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("id",             rs.getString("SOS_ID"));
        row.put("serviceType",    rs.getString("SERVICE_TYPE"));
        row.put("area",           rs.getString("AREA"));
        row.put("description",    rs.getString("DESCRIPTION"));
        row.put("isResolved",     rs.getString("IS_RESOLVED"));
        row.put("adminNote",      rs.getString("ADMIN_NOTE"));
        row.put("createdAt",      rs.getString("CREATED_AT"));
        row.put("resolvedAt",     rs.getString("RESOLVED_AT"));
        row.put("assignedName",   rs.getString("ASSIGNED_NAME"));
        row.put("assignedPhone",  rs.getString("ASSIGNED_PHONE"));
        sosList.add(row);
    }
} catch(Exception e) { logError("Emergency/sosStatus.jsp", e); }
finally { closeDB(con, ps, rs); }

/* ── Icon map ────────────────────────────────────────────── */
java.util.Map<String,String> icons = new java.util.HashMap<>();
icons.put("hospital",  "🏥");
icons.put("police",    "🚔");
icons.put("fire",      "🚒");
icons.put("ambulance", "🚑");
icons.put("pharmacy",  "💊");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>My SOS Status — NexShohor</title>
<%-- Auto refresh every 30 seconds --%>
<meta http-equiv="refresh" content="30">
<%@ include file="../includes/styles.jsp" %>
<style>
.sos-card {
    padding:22px 24px; border-radius:var(--radius);
    border:1px solid var(--glass-bdr); background:var(--glass-bg);
    margin-bottom:16px; position:relative; overflow:hidden;
}
.sos-card.resolved {
    border-color:rgba(52,211,153,0.35);
    background:rgba(52,211,153,0.05);
}
.sos-card.pending {
    border-color:rgba(251,191,36,0.35);
    background:rgba(251,191,36,0.05);
}
.sos-card-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:14px; flex-wrap:wrap; gap:8px; }
.sos-card-title  { display:flex; align-items:center; gap:10px; }
.sos-card-icon   { font-size:2rem; }
.sos-card-type   { font-weight:800; color:#fff; font-size:1rem; text-transform:capitalize; }
.sos-card-id     { font-size:0.78rem; color:var(--text-muted); }
.sos-status-badge {
    padding:6px 16px; border-radius:20px; font-weight:700; font-size:0.82rem;
    display:flex; align-items:center; gap:6px;
}
.sos-status-pending  { background:rgba(251,191,36,0.18); color:#fcd34d; border:1px solid var(--warn); }
.sos-status-resolved { background:rgba(52,211,153,0.18); color:#6ee7b7; border:1px solid var(--success); }
.sos-detail-row { display:flex; gap:8px; align-items:baseline; margin-bottom:6px; font-size:0.88rem; }
.sos-detail-lbl { color:var(--text-muted); min-width:110px; font-size:0.82rem; }
.sos-detail-val { color:var(--text-light); }
.sos-assigned-box {
    margin-top:14px; padding:12px 16px; border-radius:10px;
    background:rgba(96,165,250,0.10); border:1px solid rgba(96,165,250,0.25);
}
.sos-assigned-box p { font-size:0.88rem; color:var(--blue); font-weight:600; margin-bottom:4px; }
.sos-assigned-phone {
    display:inline-flex; align-items:center; gap:6px; margin-top:6px;
    background:rgba(248,113,113,0.15); border:1px solid var(--danger);
    color:var(--danger); padding:5px 14px; border-radius:20px;
    font-weight:700; font-size:0.85rem; text-decoration:none;
}
.sos-assigned-phone:hover { background:var(--danger); color:#fff; }
.sos-admin-note {
    margin-top:12px; padding:10px 14px; border-radius:8px;
    background:rgba(255,255,255,0.06); border-left:3px solid var(--accent);
    font-size:0.85rem; color:var(--text-light);
}
.sos-admin-note strong { color:var(--accent); display:block; margin-bottom:2px; font-size:0.78rem; }
.sos-refresh-note {
    text-align:center; padding:10px;
    color:var(--text-muted); font-size:0.8rem;
}
.sos-pulse-dot {
    width:10px; height:10px; border-radius:50%;
    background:var(--warn); display:inline-block;
    animation:pulseDot 1.2s ease-in-out infinite;
}
@keyframes pulseDot {
    0%,100% { transform:scale(1); opacity:1; }
    50%      { transform:scale(1.5); opacity:0.5; }
}
</style>
</head>
<body>

<%-- Nav based on user type --%>
<% if ("Varatia".equalsIgnoreCase(userType)) { %>
    <%@ include file="../varatiya/nav.jsp" %>
<% } else { %>
    <%@ include file="../bariwala/nav.jsp" %>
<% } %>

<div class="bv-container" style="max-width:780px;">

    <div class="glass bv-page-header" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
        <div>
            <h4>&#128203; My SOS Status</h4>
            <p>Track all your emergency requests — auto-refreshes every 30 seconds</p>
        </div>
        <a href="../user/sos.jsp" class="bv-btn bv-btn-danger">&#128721; New SOS</a>
    </div>

    <div class="sos-refresh-note">
        &#128337; Page auto-refreshes every 30s &nbsp;|&nbsp;
        <a href="sosStatus.jsp" style="color:var(--accent);">Refresh Now</a>
    </div>

    <% if (sosList.isEmpty()) { %>
    <div class="bv-empty glass">
        <span class="bv-empty-icon">&#128203;</span>
        <p style="color:var(--text-muted);">You have not sent any SOS requests yet.</p>
        <a href="../user/sos.jsp" class="bv-btn bv-btn-danger" style="margin-top:16px;">
            &#128721; Send SOS Now
        </a>
        <br><br>
        <a href="../user/emergency.jsp" class="bv-btn bv-btn-outline">
            &#128657; Browse Emergency Directory
        </a>
    </div>
    <% } else {
        for (java.util.Map<String,String> s : sosList) {
            boolean resolved = "1".equals(s.get("isResolved"));
            String  icon     = icons.getOrDefault(s.get("serviceType"), "🆘");
    %>
    <div class="sos-card <%=resolved?"resolved":"pending"%>">

        <div class="sos-card-header">
            <div class="sos-card-title">
                <span class="sos-card-icon"><%=icon%></span>
                <div>
                    <div class="sos-card-type"><%=sanitize(s.get("serviceType"))%></div>
                    <div class="sos-card-id">SOS #<%=sanitize(s.get("id"))%></div>
                </div>
            </div>
            <% if (resolved) { %>
            <span class="sos-status-badge sos-status-resolved">&#9989; Resolved</span>
            <% } else { %>
            <span class="sos-status-badge sos-status-pending">
                <span class="sos-pulse-dot"></span> Pending
            </span>
            <% } %>
        </div>

        <div class="sos-detail-row">
            <span class="sos-detail-lbl">&#128205; Area</span>
            <span class="sos-detail-val"><%=sanitize(s.get("area"))%></span>
        </div>
        <% if (s.get("description") != null && !s.get("description").isEmpty()) { %>
        <div class="sos-detail-row">
            <span class="sos-detail-lbl">&#128221; Description</span>
            <span class="sos-detail-val"><%=sanitize(s.get("description"))%></span>
        </div>
        <% } %>
        <div class="sos-detail-row">
            <span class="sos-detail-lbl">&#128337; Sent At</span>
            <span class="sos-detail-val"><%=sanitize(s.get("createdAt") != null ? s.get("createdAt").substring(0,16) : "")%></span>
        </div>
        <% if (resolved && s.get("resolvedAt") != null) { %>
        <div class="sos-detail-row">
            <span class="sos-detail-lbl">&#9989; Resolved At</span>
            <span class="sos-detail-val"><%=sanitize(s.get("resolvedAt").substring(0,16))%></span>
        </div>
        <% } %>

        <%-- Assigned service --%>
        <% if (s.get("assignedName") != null && !s.get("assignedName").isEmpty()) { %>
        <div class="sos-assigned-box">
            <p>&#128657; Assigned Service</p>
            <strong style="color:#fff;"><%=sanitize(s.get("assignedName"))%></strong>
            <% if (s.get("assignedPhone") != null && !s.get("assignedPhone").isEmpty()) { %>
            <br>
            <a href="tel:<%=sanitize(s.get("assignedPhone"))%>" class="sos-assigned-phone">
                &#128222; <%=sanitize(s.get("assignedPhone"))%>
            </a>
            <% } %>
        </div>
        <% } %>

        <%-- Admin note --%>
        <% if (s.get("adminNote") != null && !s.get("adminNote").isEmpty()) { %>
        <div class="sos-admin-note">
            <strong>&#128100; Admin Note</strong>
            <%=sanitize(s.get("adminNote"))%>
        </div>
        <% } %>

    </div>
    <% } } %>

    <div style="text-align:center;margin-top:20px;">
        <a href="../user/emergency.jsp" class="bv-btn bv-btn-outline">&#128657; Browse Emergency Directory</a>
    </div>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
