<%-- ============================================================
     Transport/alerts.jsp
     Session required — Bariwala or Varatia
     Active admin-issued urban alerts, expires_at filter, area scope
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String userType = (String) session.getAttribute("userType");

/* ── Filters ─────────────────────────────────────────────── */
String filterAreaId   = request.getParameter("area_id")    != null ? request.getParameter("area_id").trim()    : "";
String filterType     = request.getParameter("alert_type") != null ? request.getParameter("alert_type").trim() : "";

/* ── Fetch areas for dropdown ─────────────────────────────── */
java.util.List<java.util.Map<String,String>> areas = new java.util.ArrayList<>();
Connection aCon = null; PreparedStatement aPs = null; ResultSet aRs = null;
try {
    aCon = getConnection();
    aPs  = aCon.prepareStatement("SELECT AREA_ID, AREA_NAME FROM UA_AREAS WHERE IS_ACTIVE=1 ORDER BY AREA_NAME");
    aRs  = aPs.executeQuery();
    while (aRs.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("id",   aRs.getString("AREA_ID"));
        row.put("name", aRs.getString("AREA_NAME"));
        areas.add(row);
    }
} catch(Exception e) {}
finally { closeDB(aCon, aPs, aRs); }

/* ── Fetch active alerts ─────────────────────────────────── */
java.util.List<java.util.Map<String,String>> alerts = new java.util.ArrayList<>();
StringBuilder sql = new StringBuilder(
    "SELECT ua.ALERT_ID, ua.TITLE, ua.DESCRIPTION, ua.ALERT_TYPE, " +
    "       ua.EXPIRES_AT, ua.CREATED_AT, ua.ISSUED_BY_ADMIN, ar.AREA_NAME " +
    "FROM URBAN_ALERTS ua JOIN UA_AREAS ar ON ua.AREA_ID = ar.AREA_ID " +
    "WHERE ua.IS_ACTIVE = 1 " +
    "AND (ua.EXPIRES_AT IS NULL OR ua.EXPIRES_AT > CURRENT_TIMESTAMP) "
);
if (!filterAreaId.isEmpty()) sql.append("AND ua.AREA_ID = ? ");
if (!filterType.isEmpty())   sql.append("AND ua.ALERT_TYPE = ? ");
sql.append("ORDER BY ua.CREATED_AT DESC");

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    ps  = con.prepareStatement(sql.toString());
    int i = 1;
    if (!filterAreaId.isEmpty()) ps.setInt(i++, Integer.parseInt(filterAreaId));
    if (!filterType.isEmpty())   ps.setString(i++, filterType);
    rs = ps.executeQuery();
    while (rs.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("id",          rs.getString("ALERT_ID"));
        row.put("title",       rs.getString("TITLE"));
        row.put("description", rs.getString("DESCRIPTION"));
        row.put("alertType",   rs.getString("ALERT_TYPE"));
        row.put("expiresAt",   rs.getString("EXPIRES_AT"));
        row.put("createdAt",   rs.getString("CREATED_AT"));
        row.put("issuedBy",    rs.getString("ISSUED_BY_ADMIN"));
        row.put("areaName",    rs.getString("AREA_NAME"));
        alerts.add(row);
    }
} catch(Exception e) { logError("Transport/alerts.jsp", e); }
finally { closeDB(con, ps, rs); }

/* ── Type config maps ────────────────────────────────────── */
java.util.Map<String,String> typeIcons = new java.util.HashMap<>();
typeIcons.put("water_outage","💧"); typeIcons.put("roadblock","🚧");
typeIcons.put("weather","⛈");      typeIcons.put("strike","✊");
typeIcons.put("crime","🚨");

java.util.Map<String,String> typeColors = new java.util.HashMap<>();
typeColors.put("water_outage","rgba(96,165,250,0.18),#93c5fd");
typeColors.put("roadblock",   "rgba(251,191,36,0.18),#fcd34d");
typeColors.put("weather",     "rgba(167,139,250,0.18),#c4b5fd");
typeColors.put("strike",      "rgba(251,146,60,0.18),#fdba74");
typeColors.put("crime",       "rgba(248,113,113,0.18),#f87171");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Urban Alerts — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.alert-card {
    padding:20px 22px; border-radius:var(--radius);
    border:1px solid var(--glass-bdr); background:var(--glass-bg);
    margin-bottom:14px; transition:transform 0.2s;
}
.alert-card:hover { transform:translateY(-2px); }
.alert-card-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:12px; flex-wrap:wrap; gap:8px; }
.alert-type-badge  { padding:5px 14px; border-radius:20px; font-size:0.8rem; font-weight:700; display:inline-flex; align-items:center; gap:5px; }
.alert-meta        { font-size:0.8rem; color:var(--text-muted); }
.alert-title       { font-weight:700; color:#fff; font-size:1rem; margin-bottom:6px; }
.alert-desc        { font-size:0.87rem; color:var(--text-light); margin-bottom:10px; }
.alert-footer      { display:flex; gap:16px; flex-wrap:wrap; font-size:0.8rem; color:var(--text-muted); }
</style>
</head>
<body>

<% if ("Varatia".equalsIgnoreCase(userType)) { %>
    <%@ include file="../varatiya/nav.jsp" %>
<% } else { %>
    <%@ include file="../bariwala/nav.jsp" %>
<% } %>

<div class="bv-container">

    <div class="glass bv-page-header" style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;">
        <div>
            <h4>&#128680; Urban Alerts</h4>
            <p>Active alerts issued by admin — water, roadblock, weather, strike, crime</p>
        </div>
        <span class="bv-badge" style="background:rgba(248,113,113,0.18);color:#f87171;font-size:0.9rem;">
            <%=alerts.size()%> Active
        </span>
    </div>

    <%-- Filter bar --%>
    <form method="get" class="glass bv-filter" style="margin-bottom:22px;">
        <select name="area_id" class="bv-select">
            <option value="">All Areas</option>
            <% for (java.util.Map<String,String> a : areas) { %>
            <option value="<%=sanitize(a.get("id"))%>" <%=a.get("id").equals(filterAreaId)?"selected":""%>>
                <%=sanitize(a.get("name"))%>
            </option>
            <% } %>
        </select>
        <select name="alert_type" class="bv-select">
            <option value="">All Types</option>
            <option value="water_outage" <%="water_outage".equals(filterType)?"selected":""%>>💧 Water Outage</option>
            <option value="roadblock"   <%="roadblock".equals(filterType)  ?"selected":""%>>🚧 Roadblock</option>
            <option value="weather"     <%="weather".equals(filterType)    ?"selected":""%>>⛈ Weather</option>
            <option value="strike"      <%="strike".equals(filterType)     ?"selected":""%>>✊ Strike</option>
            <option value="crime"       <%="crime".equals(filterType)      ?"selected":""%>>🚨 Crime</option>
        </select>
        <button type="submit" class="bv-btn bv-btn-danger bv-btn-sm">Filter</button>
        <a href="alerts.jsp" class="bv-btn bv-btn-outline bv-btn-sm">Reset</a>
    </form>

    <% if (alerts.isEmpty()) { %>
    <div class="bv-empty glass">
        <span class="bv-empty-icon">&#128680;</span>
        <p style="color:var(--text-muted);">No active alerts at the moment.</p>
    </div>
    <% } else {
        for (java.util.Map<String,String> al : alerts) {
            String aType   = al.get("alertType") != null ? al.get("alertType") : "";
            String icon    = typeIcons.getOrDefault(aType, "📢");
            String colors  = typeColors.getOrDefault(aType, "rgba(255,255,255,0.1),#fff");
            String[] colorParts = colors.split(",");
            String bgColor = colorParts[0];
            String fgColor = colorParts.length > 1 ? colorParts[1] : "#fff";
            String expires = al.get("expiresAt");
            String created = al.get("createdAt") != null ? al.get("createdAt").substring(0,16) : "";
    %>
    <div class="alert-card">
        <div class="alert-card-header">
            <span class="alert-type-badge" style="background:<%=bgColor%>;color:<%=fgColor%>;">
                <%=icon%> <%=sanitize(aType.replace("_"," "))%>
            </span>
            <span class="alert-meta">
                &#128205; <%=sanitize(al.get("areaName"))%> &bull; <%=sanitize(created)%>
            </span>
        </div>
        <div class="alert-title"><%=sanitize(al.get("title"))%></div>
        <% if (al.get("description") != null && !al.get("description").isEmpty()) { %>
        <div class="alert-desc"><%=sanitize(al.get("description"))%></div>
        <% } %>
        <div class="alert-footer">
            <span>&#128100; <%=sanitize(al.get("issuedBy"))%></span>
            <% if (expires != null && !expires.isEmpty()) { %>
            <span>&#9200; Expires: <%=sanitize(expires.substring(0,16))%></span>
            <% } else { %>
            <span>&#9200; No expiry</span>
            <% } %>
        </div>
    </div>
    <% } } %>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
