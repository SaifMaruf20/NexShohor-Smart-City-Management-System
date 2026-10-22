<%-- ============================================================
     Transport/detail.jsp
     Session required — Bariwala or Varatia
     Single incident view + crowd reports list + status badge
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String userType = (String) session.getAttribute("userType");

/* ── Read and validate id param ──────────────────────────── */
int incidentId = 0;
try { incidentId = Integer.parseInt(request.getParameter("id")); } catch(Exception ignored){}
if (incidentId <= 0) {
    response.sendRedirect("feed.jsp");
    return;
}

/* ── Fetch incident ──────────────────────────────────────── */
java.util.Map<String,String> inc = null;
Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    ps  = con.prepareStatement(
        "SELECT INCIDENT_ID, TITLE, AREA, SEVERITY, STATUS, CROWD_LEVEL, " +
        "DESCRIPTION, REPORTED_BY, CREATED_AT, UPDATED_AT FROM INCIDENTS WHERE INCIDENT_ID = ?"
    );
    ps.setInt(1, incidentId);
    rs = ps.executeQuery();
    if (rs.next()) {
        inc = new java.util.LinkedHashMap<>();
        inc.put("id",          rs.getString("INCIDENT_ID"));
        inc.put("title",       rs.getString("TITLE"));
        inc.put("area",        rs.getString("AREA"));
        inc.put("severity",    rs.getString("SEVERITY"));
        inc.put("status",      rs.getString("STATUS"));
        inc.put("crowdLevel",  rs.getString("CROWD_LEVEL"));
        inc.put("description", rs.getString("DESCRIPTION"));
        inc.put("reportedBy",  rs.getString("REPORTED_BY"));
        inc.put("createdAt",   rs.getString("CREATED_AT"));
        inc.put("updatedAt",   rs.getString("UPDATED_AT"));
    }
} catch(Exception e) { logError("Transport/detail.jsp", e); }
finally { closeDB(con, ps, rs); }

if (inc == null) {
    response.sendRedirect("feed.jsp");
    return;
}

/* ── Fetch crowd reports ─────────────────────────────────── */
java.util.List<java.util.Map<String,String>> crowdReports = new java.util.ArrayList<>();
Connection con2 = null; PreparedStatement ps2 = null; ResultSet rs2 = null;
try {
    con2 = getConnection();
    ps2  = con2.prepareStatement(
        "SELECT CROWD_LEVEL, NOTE, REPORTED_BY, REPORTED_AT FROM CROWD_REPORTS " +
        "WHERE INCIDENT_ID = ? ORDER BY REPORTED_AT DESC"
    );
    ps2.setInt(1, incidentId);
    rs2 = ps2.executeQuery();
    while (rs2.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("crowdLevel",  rs2.getString("CROWD_LEVEL"));
        row.put("note",        rs2.getString("NOTE"));
        row.put("reportedBy",  rs2.getString("REPORTED_BY"));
        row.put("reportedAt",  rs2.getString("REPORTED_AT"));
        crowdReports.add(row);
    }
} catch(Exception e) {}
finally { closeDB(con2, ps2, rs2); }

/* ── Badge helpers ───────────────────────────────────────── */
String sev   = inc.get("severity")  != null ? inc.get("severity")  : "";
String stat  = inc.get("status")    != null ? inc.get("status")    : "";
String crowd = inc.get("crowdLevel")!= null ? inc.get("crowdLevel"): "";

String sevCss   = sev.equals("Low")?"sev-low":sev.equals("Medium")?"sev-medium":sev.equals("High")?"sev-high":"sev-critical";
String statCss  = stat.equals("Open")?"stat-open":stat.equals("In Progress")?"stat-prog":"stat-res";
String crowdCss = crowd.equals("Low")?"crowd-low":crowd.equals("Moderate")?"crowd-mod":crowd.equals("High")?"crowd-high":"crowd-jammed";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Incident Detail — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.sev-low      { background:rgba(52,211,153,0.18);  color:#6ee7b7; }
.sev-medium   { background:rgba(251,191,36,0.18);  color:#fcd34d; }
.sev-high     { background:rgba(251,146,60,0.18);  color:#fdba74; }
.sev-critical { background:rgba(248,113,113,0.25); color:#f87171; }
.crowd-low    { background:rgba(52,211,153,0.18);  color:#6ee7b7; }
.crowd-mod    { background:rgba(251,191,36,0.18);  color:#fcd34d; }
.crowd-high   { background:rgba(251,146,60,0.18);  color:#fdba74; }
.crowd-jammed { background:rgba(248,113,113,0.25); color:#f87171; }
.stat-open    { background:rgba(96,165,250,0.18);  color:#93c5fd; }
.stat-prog    { background:rgba(251,191,36,0.18);  color:#fcd34d; }
.stat-res     { background:rgba(52,211,153,0.18);  color:#6ee7b7; }
.detail-row   { display:flex; gap:10px; align-items:baseline; margin-bottom:12px; font-size:0.9rem; }
.detail-lbl   { color:var(--text-muted); min-width:120px; font-size:0.82rem; }
.crowd-card   { padding:14px 16px; border-radius:10px; background:var(--glass-bg); border:1px solid var(--glass-bdr); margin-bottom:10px; }
</style>
</head>
<body>

<% if ("Varatia".equalsIgnoreCase(userType)) { %>
    <%@ include file="../varatiya/nav.jsp" %>
<% } else { %>
    <%@ include file="../bariwala/nav.jsp" %>
<% } %>

<div class="bv-container" style="max-width:860px;">

    <div style="margin-bottom:18px;">
        <a href="feed.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#8592; Back to Feed</a>
    </div>

    <%-- Incident card --%>
    <div class="glass" style="padding:28px;margin-bottom:24px;">

        <div style="display:flex;align-items:flex-start;justify-content:space-between;flex-wrap:wrap;gap:12px;margin-bottom:20px;">
            <div>
                <h4 style="font-weight:800;color:#fff;margin-bottom:8px;">&#128652; <%=sanitize(inc.get("title"))%></h4>
                <span class="bv-badge <%=statCss%>"><%=sanitize(stat)%></span>
            </div>
            <span style="color:var(--text-muted);font-size:0.82rem;">#<%=sanitize(inc.get("id"))%></span>
        </div>

        <div class="detail-row">
            <span class="detail-lbl">&#128205; Area</span>
            <span class="bv-badge" style="background:rgba(96,165,250,0.15);color:#93c5fd;"><%=sanitize(inc.get("area"))%></span>
        </div>
        <div class="detail-row">
            <span class="detail-lbl">&#9888; Severity</span>
            <span class="bv-badge <%=sevCss%>"><%=sanitize(sev)%></span>
        </div>
        <div class="detail-row">
            <span class="detail-lbl">&#128101; Crowd Level</span>
            <span class="bv-badge <%=crowdCss%>"><%=sanitize(crowd)%></span>
        </div>
        <% if (inc.get("description") != null && !inc.get("description").isEmpty()) { %>
        <div class="detail-row">
            <span class="detail-lbl">&#128221; Description</span>
            <span style="color:var(--text-light);"><%=sanitize(inc.get("description"))%></span>
        </div>
        <% } %>
        <div class="detail-row">
            <span class="detail-lbl">&#128100; Reported By</span>
            <span style="color:var(--text-light);"><%=sanitize(inc.get("reportedBy"))%></span>
        </div>
        <div class="detail-row">
            <span class="detail-lbl">&#128337; Reported At</span>
            <span style="color:var(--text-muted);font-size:0.85rem;"><%=inc.get("createdAt")!=null?sanitize(inc.get("createdAt").substring(0,16)):""%></span>
        </div>

    </div>

    <%-- Crowd reports --%>
    <h5 class="bv-section-title">&#128101; Crowd Reports (<%=crowdReports.size()%>)</h5>

    <% if (crowdReports.isEmpty()) { %>
    <div class="bv-empty glass" style="padding:32px;">
        <span class="bv-empty-icon" style="font-size:2rem;">&#128101;</span>
        <p style="color:var(--text-muted);">No crowd reports yet for this incident.</p>
    </div>
    <% } else {
        for (java.util.Map<String,String> cr : crowdReports) {
            String crCrowd = cr.get("crowdLevel") != null ? cr.get("crowdLevel") : "";
            String crCss   = crCrowd.equals("Low")?"crowd-low":crCrowd.equals("Moderate")?"crowd-mod":crCrowd.equals("High")?"crowd-high":"crowd-jammed";
    %>
    <div class="crowd-card">
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;flex-wrap:wrap;gap:6px;">
            <span class="bv-badge <%=crCss%>">&#128101; <%=sanitize(crCrowd)%></span>
            <span style="color:var(--text-muted);font-size:0.78rem;">
                <%=sanitize(cr.get("reportedBy"))%> &bull;
                <%=cr.get("reportedAt")!=null?sanitize(cr.get("reportedAt").substring(0,16)):""%>
            </span>
        </div>
        <% if (cr.get("note") != null && !cr.get("note").isEmpty()) { %>
        <p style="color:var(--text-light);font-size:0.87rem;margin:0;"><%=sanitize(cr.get("note"))%></p>
        <% } %>
    </div>
    <% } } %>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
