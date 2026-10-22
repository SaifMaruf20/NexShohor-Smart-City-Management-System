<%-- ============================================================
     Community/urbanAlerts.jsp
     Session required — Bariwala or Varatia
     water outage · roadblock · weather · strike · crime
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String userType  = (String) session.getAttribute("userType");
String userEmail = (String) session.getAttribute("userEmail");

/* ── Filters ─────────────────────────────────────────────── */
String filterType   = request.getParameter("alert_type") != null ? request.getParameter("alert_type").trim() : "";
String filterAreaId = request.getParameter("area_id")    != null ? request.getParameter("area_id").trim()    : "";

/* ── Fetch areas for dropdown ─────────────────────────────── */
java.util.List<java.util.Map<String,String>> areas = new java.util.ArrayList<>();
Connection aCon = null; PreparedStatement aPs = null; ResultSet aRs = null;
try {
    aCon = getConnection();
    aPs  = aCon.prepareStatement("SELECT AREA_ID, AREA_NAME FROM UA_AREAS WHERE IS_ACTIVE=1 ORDER BY AREA_NAME");
    aRs  = aPs.executeQuery();
    while (aRs.next()) {
        java.util.Map<String,String> r = new java.util.LinkedHashMap<>();
        r.put("id",   aRs.getString("AREA_ID"));
        r.put("name", aRs.getString("AREA_NAME"));
        areas.add(r);
    }
} catch(Exception e) {}
finally { closeDB(aCon, aPs, aRs); }

/* ── Fetch active alerts ─────────────────────────────────── */
java.util.List<java.util.Map<String,String>> alerts = new java.util.ArrayList<>();
StringBuilder sql = new StringBuilder(
    "SELECT ua.ALERT_ID, ua.TITLE, ua.DESCRIPTION, ua.ALERT_TYPE, " +
    "       ua.EXPIRES_AT, ua.CREATED_AT, ua.ISSUED_BY_ADMIN, ar.AREA_NAME, ar.AREA_ID " +
    "FROM URBAN_ALERTS ua JOIN UA_AREAS ar ON ua.AREA_ID = ar.AREA_ID " +
    "WHERE ua.IS_ACTIVE = 1 " +
    "AND (ua.EXPIRES_AT IS NULL OR ua.EXPIRES_AT > CURRENT_TIMESTAMP) "
);
if (!filterType.isEmpty())   sql.append("AND ua.ALERT_TYPE = ? ");
if (!filterAreaId.isEmpty()) sql.append("AND ua.AREA_ID = ? ");
sql.append("ORDER BY ua.CREATED_AT DESC");

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    ps  = con.prepareStatement(sql.toString());
    int i = 1;
    if (!filterType.isEmpty())   ps.setString(i++, filterType);
    if (!filterAreaId.isEmpty()) ps.setInt(i++, Integer.parseInt(filterAreaId));
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
        row.put("areaId",      rs.getString("AREA_ID"));
        alerts.add(row);
    }
} catch(Exception e) { logError("Community/urbanAlerts.jsp", e); }
finally { closeDB(con, ps, rs); }

/* ── Check bookmarked alert IDs for this user ────────────── */
java.util.Set<String> bookmarked = new java.util.HashSet<>();
Connection bCon = null; PreparedStatement bPs = null; ResultSet bRs = null;
try {
    bCon = getConnection();
    bPs  = bCon.prepareStatement(
        "SELECT ALERT_ID FROM ALERT_BOOKMARKS WHERE USER_EMAIL=? AND ALERT_ID IS NOT NULL"
    );
    bPs.setString(1, userEmail);
    bRs = bPs.executeQuery();
    while (bRs.next()) bookmarked.add(bRs.getString("ALERT_ID"));
} catch(Exception e) {}
finally { closeDB(bCon, bPs, bRs); }

/* ── Handle bookmark toggle POST ─────────────────────────── */
String bookmarkMsg = "";
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String action  = request.getParameter("action");
    String alertId = request.getParameter("alertId");
    if (alertId != null && !alertId.trim().isEmpty()) {
        Connection tCon = null; PreparedStatement tPs = null;
        try {
            tCon = getConnection();
            if ("bookmark".equals(action)) {
                tPs = tCon.prepareStatement(
                    "INSERT INTO ALERT_BOOKMARKS (USER_EMAIL, ALERT_ID) VALUES (?,?)"
                );
                tPs.setString(1, userEmail);
                tPs.setInt(2, Integer.parseInt(alertId));
                tPs.executeUpdate();
                bookmarked.add(alertId);
                bookmarkMsg = "Alert bookmarked!";
            } else if ("unbookmark".equals(action)) {
                tPs = tCon.prepareStatement(
                    "DELETE FROM ALERT_BOOKMARKS WHERE USER_EMAIL=? AND ALERT_ID=?"
                );
                tPs.setString(1, userEmail);
                tPs.setInt(2, Integer.parseInt(alertId));
                tPs.executeUpdate();
                bookmarked.remove(alertId);
                bookmarkMsg = "Bookmark removed.";
            }
        } catch(Exception e) {}
        finally { closeDB(tCon, tPs, null); }
    }
}

/* ── Type config ─────────────────────────────────────────── */
java.util.Map<String,String[]> typeConfig = new java.util.LinkedHashMap<>();
typeConfig.put("water_outage", new String[]{"💧","Water Outage",  "rgba(96,165,250,0.18)","#93c5fd","rgba(96,165,250,0.35)"});
typeConfig.put("roadblock",    new String[]{"🚧","Roadblock",     "rgba(251,191,36,0.18)","#fcd34d","rgba(251,191,36,0.35)"});
typeConfig.put("weather",      new String[]{"⛈","Weather",       "rgba(167,139,250,0.18)","#c4b5fd","rgba(167,139,250,0.35)"});
typeConfig.put("strike",       new String[]{"✊","Strike",        "rgba(251,146,60,0.18)","#fdba74","rgba(251,146,60,0.35)"});
typeConfig.put("crime",        new String[]{"🚨","Crime",         "rgba(248,113,113,0.18)","#f87171","rgba(248,113,113,0.35)"});
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Urban Alerts — NexShohor Community</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.ua-hero {
    text-align:center; padding:30px 24px 22px;
    background:linear-gradient(135deg,rgba(248,113,113,0.12),rgba(251,191,36,0.08));
    border:1px solid rgba(248,113,113,0.22); border-radius:var(--radius);
    margin-bottom:26px;
}
.ua-hero h2 { font-size:1.6rem; font-weight:900; color:#fff; margin-bottom:4px; }
.ua-hero p  { color:var(--text-muted); font-size:0.9rem; }

/* Type filter tabs */
.ua-tabs { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:20px; }
.ua-tab {
    padding:7px 16px; border-radius:20px; font-size:0.83rem; font-weight:600;
    border:1px solid var(--glass-bdr); color:var(--text-light);
    text-decoration:none; transition:0.2s; background:rgba(255,255,255,0.06);
    display:inline-flex; align-items:center; gap:5px;
}
.ua-tab:hover  { background:rgba(255,255,255,0.12); }
.ua-tab.active { border-color:var(--danger); background:rgba(248,113,113,0.15); color:#fff; }

/* Alert card */
.ua-card {
    border-radius:var(--radius); border:1px solid var(--glass-bdr);
    background:var(--glass-bg); margin-bottom:14px;
    overflow:hidden; transition:transform 0.2s;
}
.ua-card:hover { transform:translateY(-2px); }
.ua-card-stripe { height:4px; width:100%; }
.ua-card-body   { padding:18px 20px; }
.ua-card-header { display:flex; align-items:flex-start; justify-content:space-between; flex-wrap:wrap; gap:10px; margin-bottom:12px; }
.ua-type-pill   { padding:5px 14px; border-radius:20px; font-size:0.8rem; font-weight:700; display:inline-flex; align-items:center; gap:5px; }
.ua-card-title  { font-weight:800; color:#fff; font-size:1rem; margin-bottom:6px; }
.ua-card-desc   { font-size:0.87rem; color:var(--text-light); line-height:1.6; margin-bottom:12px; }
.ua-card-footer { display:flex; gap:14px; flex-wrap:wrap; align-items:center; font-size:0.8rem; color:var(--text-muted); }
.ua-bookmark-btn {
    padding:5px 14px; border-radius:20px; font-size:0.8rem; font-weight:600;
    border:none; cursor:pointer; transition:0.2s;
}
.ua-bookmark-on  { background:rgba(251,191,36,0.18); color:#fcd34d; border:1px solid var(--warn); }
.ua-bookmark-on:hover  { background:var(--warn); color:#000; }
.ua-bookmark-off { background:rgba(255,255,255,0.06); color:var(--text-muted); border:1px solid var(--glass-bdr); }
.ua-bookmark-off:hover { background:rgba(255,255,255,0.12); color:#fff; }

/* Stats row */
.ua-stats { display:grid; grid-template-columns:repeat(auto-fill,minmax(120px,1fr)); gap:12px; margin-bottom:22px; }
.ua-stat  { padding:14px; text-align:center; border-radius:var(--radius); background:var(--glass-bg); border:1px solid var(--glass-bdr); }
.ua-stat-num  { font-size:1.6rem; font-weight:800; }
.ua-stat-lbl  { font-size:0.72rem; color:var(--text-muted); text-transform:uppercase; letter-spacing:0.4px; }
</style>
</head>
<body>

<% if ("Varatia".equalsIgnoreCase(userType)) { %>
    <%@ include file="../varatiya/nav.jsp" %>
<% } else { %>
    <%@ include file="../bariwala/nav.jsp" %>
<% } %>

<div class="bv-container">

    <%-- Hero --%>
    <div class="ua-hero glass">
        <div style="font-size:2.8rem;">&#127758;</div>
        <h2>Urban Community Alerts</h2>
        <p>Stay informed about water outages, roadblocks, weather, strikes &amp; crime in your area</p>
    </div>

    <%-- Bookmark message --%>
    <% if (!bookmarkMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-success">&#11088; <%=sanitize(bookmarkMsg)%></div>
    <% } %>

    <%-- Stats --%>
    <%
    java.util.Map<String,Integer> typeCounts = new java.util.LinkedHashMap<>();
    for (String[] cfg : typeConfig.values()) typeCounts.put(cfg[1], 0);
    for (java.util.Map<String,String> al : alerts) {
        String[] cfg = typeConfig.get(al.get("alertType"));
        if (cfg != null) typeCounts.put(cfg[1], typeCounts.getOrDefault(cfg[1],0)+1);
    }
    %>
    <div class="ua-stats">
        <div class="ua-stat glass">
            <div class="ua-stat-num" style="color:var(--danger);"><%=alerts.size()%></div>
            <div class="ua-stat-lbl">Total Active</div>
        </div>
        <% for (java.util.Map.Entry<String,Integer> e : typeCounts.entrySet()) { %>
        <div class="ua-stat glass">
            <div class="ua-stat-num" style="color:var(--warn);"><%=e.getValue()%></div>
            <div class="ua-stat-lbl"><%=e.getKey()%></div>
        </div>
        <% } %>
    </div>

    <%-- Type tabs --%>
    <div class="ua-tabs">
        <a href="urbanAlerts.jsp?area_id=<%=sanitize(filterAreaId)%>" class="ua-tab <%=filterType.isEmpty()?"active":""%>">🔍 All</a>
        <% for (java.util.Map.Entry<String,String[]> e : typeConfig.entrySet()) { %>
        <a href="urbanAlerts.jsp?alert_type=<%=e.getKey()%>&area_id=<%=sanitize(filterAreaId)%>"
           class="ua-tab <%=e.getKey().equals(filterType)?"active":""%>">
            <%=e.getValue()[0]%> <%=e.getValue()[1]%>
        </a>
        <% } %>
    </div>

    <%-- Area filter --%>
    <form method="get" class="glass bv-filter" style="margin-bottom:22px;">
        <input type="hidden" name="alert_type" value="<%=sanitize(filterType)%>">
        <span style="color:var(--text-muted);font-size:0.88rem;white-space:nowrap;">&#128205; Area:</span>
        <select name="area_id" class="bv-select" style="flex:1;min-width:180px;">
            <option value="">All Areas</option>
            <% for (java.util.Map<String,String> a : areas) { %>
            <option value="<%=sanitize(a.get("id"))%>" <%=a.get("id").equals(filterAreaId)?"selected":""%>>
                <%=sanitize(a.get("name"))%>
            </option>
            <% } %>
        </select>
        <button type="submit" class="bv-btn bv-btn-danger bv-btn-sm">Filter</button>
        <a href="urbanAlerts.jsp" class="bv-btn bv-btn-outline bv-btn-sm">Reset</a>
    </form>

    <%-- Alerts list --%>
    <% if (alerts.isEmpty()) { %>
    <div class="bv-empty glass">
        <span class="bv-empty-icon">&#127758;</span>
        <p style="color:var(--text-muted);">No active alerts right now. Stay safe!</p>
        <a href="urbanAlerts.jsp" class="bv-btn bv-btn-outline" style="margin-top:16px;">Clear Filters</a>
    </div>
    <% } else {
        for (java.util.Map<String,String> al : alerts) {
            String aType  = al.get("alertType") != null ? al.get("alertType") : "";
            String[] cfg  = typeConfig.getOrDefault(aType, new String[]{"📢","Alert","rgba(255,255,255,0.1)","#fff","rgba(255,255,255,0.2)"});
            String icon   = cfg[0]; String label = cfg[1];
            String bgCol  = cfg[2]; String fgCol = cfg[3]; String stripeCol = cfg[4];
            String alId   = al.get("id");
            boolean isBkm = bookmarked.contains(alId);
            String expires = al.get("expiresAt");
            String created = al.get("createdAt") != null ? al.get("createdAt").substring(0,16) : "";
    %>
    <div class="ua-card">
        <div class="ua-card-stripe" style="background:<%=stripeCol%>;"></div>
        <div class="ua-card-body">
            <div class="ua-card-header">
                <div>
                    <span class="ua-type-pill" style="background:<%=bgCol%>;color:<%=fgCol%>;">
                        <%=icon%> <%=sanitize(label)%>
                    </span>
                    <div style="margin-top:8px;" class="ua-card-title"><%=sanitize(al.get("title"))%></div>
                    <div style="font-size:0.8rem;color:var(--text-muted);">
                        &#128205; <%=sanitize(al.get("areaName"))%>
                    </div>
                </div>
                <%-- Bookmark form --%>
                <form method="post" style="margin:0;">
                    <input type="hidden" name="alertId" value="<%=sanitize(alId)%>">
                    <input type="hidden" name="alert_type" value="<%=sanitize(filterType)%>">
                    <input type="hidden" name="area_id"    value="<%=sanitize(filterAreaId)%>">
                    <button type="submit" name="action" value="<%=isBkm?"unbookmark":"bookmark"%>"
                        class="ua-bookmark-btn <%=isBkm?"ua-bookmark-on":"ua-bookmark-off"%>">
                        <%=isBkm?"⭐ Saved":"☆ Save"%>
                    </button>
                </form>
            </div>

            <% if (al.get("description") != null && !al.get("description").isEmpty()) { %>
            <div class="ua-card-desc"><%=sanitize(al.get("description"))%></div>
            <% } %>

            <div class="ua-card-footer">
                <span>&#128100; <%=sanitize(al.get("issuedBy"))%></span>
                <span>&#128337; <%=sanitize(created)%></span>
                <% if (expires != null && !expires.isEmpty()) { %>
                <span style="color:var(--warn);">&#9200; Expires: <%=sanitize(expires.substring(0,16))%></span>
                <% } else { %>
                <span>&#9200; No expiry set</span>
                <% } %>
            </div>
        </div>
    </div>
    <% } } %>

    <div style="text-align:center;margin-top:24px;">
        <a href="../user/sos.jsp"       class="bv-btn bv-btn-danger"  style="margin-right:10px;">&#128721; Send SOS</a>
        <a href="../user/emergency.jsp" class="bv-btn bv-btn-outline">&#128657; Emergency Directory</a>
    </div>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
