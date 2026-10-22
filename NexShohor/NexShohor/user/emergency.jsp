<%-- ============================================================
     Emergency/directory.jsp
     Public page — no session required
     Searchable emergency services directory
     Filter by: type + area
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
/* ── Filters ─────────────────────────────────────────────── */
String filterType = request.getParameter("type");
String filterArea = request.getParameter("area");
if (filterType == null) filterType = "";
if (filterArea == null) filterArea = "";

/* ── Build query dynamically ─────────────────────────────── */
StringBuilder sql = new StringBuilder(
    "SELECT es.SERVICE_ID, es.NAME, es.AREA, es.ADDRESS, es.PHONE, " +
    "       st.TYPE_NAME, st.ICON " +
    "FROM EMERGENCY_SERVICES es " +
    "JOIN SERVICE_TYPES st ON es.TYPE_ID = st.TYPE_ID " +
    "WHERE es.IS_ACTIVE = 1 "
);
if (!filterType.isEmpty()) sql.append("AND LOWER(st.TYPE_NAME) = LOWER(?) ");
if (!filterArea.isEmpty()) sql.append("AND LOWER(es.AREA) LIKE LOWER(?) ");
sql.append("ORDER BY st.TYPE_NAME, es.NAME");

java.util.List<java.util.Map<String,String>> services = new java.util.ArrayList<>();
Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    ps  = con.prepareStatement(sql.toString());
    int idx = 1;
    if (!filterType.isEmpty()) ps.setString(idx++, filterType);
    if (!filterArea.isEmpty()) ps.setString(idx++, "%" + filterArea + "%");
    rs = ps.executeQuery();
    while (rs.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("id",      rs.getString("SERVICE_ID"));
        row.put("name",    rs.getString("NAME"));
        row.put("area",    rs.getString("AREA"));
        row.put("address", rs.getString("ADDRESS"));
        row.put("phone",   rs.getString("PHONE"));
        row.put("type",    rs.getString("TYPE_NAME"));
        row.put("icon",    rs.getString("ICON"));
        services.add(row);
    }
} catch(Exception e) { logError("Emergency/directory.jsp", e); }
finally { closeDB(con, ps, rs); }

/* ── Fetch distinct areas for filter dropdown ─────────────── */
java.util.List<String> areas = new java.util.ArrayList<>();
Connection con2 = null; PreparedStatement ps2 = null; ResultSet rs2 = null;
try {
    con2 = getConnection();
    ps2  = con2.prepareStatement("SELECT DISTINCT AREA FROM EMERGENCY_SERVICES WHERE IS_ACTIVE=1 ORDER BY AREA");
    rs2  = ps2.executeQuery();
    while (rs2.next()) areas.add(rs2.getString("AREA"));
} catch(Exception e) {}
finally { closeDB(con2, ps2, rs2); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Emergency Directory — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.em-type-tabs { display:flex; gap:8px; flex-wrap:wrap; margin-bottom:22px; }
.em-type-tab {
    padding:8px 18px; border-radius:20px; font-size:0.85rem; font-weight:600;
    border:1px solid var(--glass-bdr); color:var(--text-light);
    text-decoration:none; transition:0.2s; background:rgba(255,255,255,0.06);
}
.em-type-tab:hover, .em-type-tab.active {
    background:var(--danger); border-color:var(--danger); color:#fff;
}
.em-card {
    padding:18px 20px; border-radius:var(--radius);
    background:var(--glass-bg); border:1px solid var(--glass-bdr);
    transition:transform 0.2s;
}
.em-card:hover { transform:translateY(-3px); }
.em-card-icon { font-size:2rem; margin-bottom:8px; display:block; }
.em-card-name { font-weight:700; color:#fff; font-size:1rem; margin-bottom:4px; }
.em-card-area { font-size:0.82rem; color:var(--accent); margin-bottom:6px; }
.em-card-addr { font-size:0.82rem; color:var(--text-muted); margin-bottom:10px; }
.em-card-phone {
    display:inline-flex; align-items:center; gap:6px;
    background:rgba(248,113,113,0.15); border:1px solid var(--danger);
    color:var(--danger); padding:6px 14px; border-radius:20px;
    font-weight:700; font-size:0.88rem; text-decoration:none;
}
.em-card-phone:hover { background:var(--danger); color:#fff; }
.em-hero {
    text-align:center; padding:32px 20px 24px;
    background:linear-gradient(135deg,rgba(248,113,113,0.15),rgba(251,191,36,0.10));
    border:1px solid rgba(248,113,113,0.25); border-radius:var(--radius);
    margin-bottom:28px;
}
.em-hero h2 { font-size:1.6rem; font-weight:800; color:#fff; margin-bottom:6px; }
.em-hero p  { color:var(--text-muted); font-size:0.9rem; }
.em-sos-btn {
    display:inline-block; margin-top:14px;
    background:linear-gradient(135deg,#dc2626,var(--danger));
    color:#fff; font-weight:800; font-size:1rem;
    padding:12px 32px; border-radius:30px; text-decoration:none;
    box-shadow:0 4px 20px rgba(248,113,113,0.4);
    transition:transform 0.2s, box-shadow 0.2s;
}
.em-sos-btn:hover { transform:scale(1.04); box-shadow:0 6px 28px rgba(248,113,113,0.6); }
</style>
</head>
<body>

<%-- Minimal public nav --%>
<nav class="bv-nav">
    <a class="bv-nav-brand" href="../user/login.jsp">&#128247; NexShohor</a>
    <div class="bv-ham" id="bvHam"><span></span><span></span><span></span></div>
    <div class="bv-nav-links" id="bvNavLinks">
        <a href="../user/emergency.jsp" class="active">&#128657; Emergency</a>
        <a href="../user/login.jsp">&#128100; Login</a>
        <a href="../user/register.jsp">&#128221; Register</a>
    </div>
</nav>

<div class="bv-container">

    <%-- Hero --%>
    <div class="em-hero glass">
        <div style="font-size:3rem;">&#128680;</div>
        <h2>Emergency Services Directory</h2>
        <p>Find hospitals, police stations, fire brigades, ambulances &amp; pharmacies near you</p>
                <%
        String _emergencyUser = (String) session.getAttribute("userEmail");
        if (_emergencyUser != null && !_emergencyUser.isEmpty()) {
        %>
            <a href="../user/sos.jsp" class="em-sos-btn">&#128721; Send SOS &#8212; Need Help Now</a>
        <% } else { %>
            <a href="../user/login.jsp" class="em-sos-btn" style="background:rgba(255,255,255,0.1);">
              &#128274; Login to Send SOS
            </a>
        <% } %>
    </div>

    <%-- Type tabs --%>
    <div class="em-type-tabs">
        <a href="directory.jsp?area=<%=sanitize(filterArea)%>" class="em-type-tab <%=filterType.isEmpty()?"active":""%>">🔍 All</a>
        <a href="directory.jsp?type=hospital&area=<%=sanitize(filterArea)%>"  class="em-type-tab <%=filterType.equals("hospital") ?"active":""%>">🏥 Hospital</a>
        <a href="directory.jsp?type=police&area=<%=sanitize(filterArea)%>"   class="em-type-tab <%=filterType.equals("police")  ?"active":""%>">🚔 Police</a>
        <a href="directory.jsp?type=fire&area=<%=sanitize(filterArea)%>"     class="em-type-tab <%=filterType.equals("fire")    ?"active":""%>">🚒 Fire</a>
        <a href="directory.jsp?type=ambulance&area=<%=sanitize(filterArea)%>"class="em-type-tab <%=filterType.equals("ambulance")?"active":""%>">🚑 Ambulance</a>
        <a href="directory.jsp?type=pharmacy&area=<%=sanitize(filterArea)%>" class="em-type-tab <%=filterType.equals("pharmacy") ?"active":""%>">💊 Pharmacy</a>
    </div>

    <%-- Area filter --%>
    <div class="glass bv-filter" style="margin-bottom:24px;">
        <span style="color:var(--text-muted);font-size:0.88rem;white-space:nowrap;">&#128205; Filter by Area:</span>
        <form method="get" style="display:flex;gap:8px;flex:1;flex-wrap:wrap;">
            <input type="hidden" name="type" value="<%=sanitize(filterType)%>">
            <select name="area" class="bv-select" style="flex:1;min-width:180px;">
                <option value="">All Areas</option>
                <% for (String a : areas) { %>
                <option value="<%=sanitize(a)%>" <%=a.equals(filterArea)?"selected":""%>><%=sanitize(a)%></option>
                <% } %>
            </select>
            <button type="submit" class="bv-btn bv-btn-danger bv-btn-sm">Filter</button>
            <a href="directory.jsp" class="bv-btn bv-btn-outline bv-btn-sm">Reset</a>
        </form>
    </div>

    <%-- Results --%>
    <% if (services.isEmpty()) { %>
    <div class="bv-empty glass">
        <span class="bv-empty-icon">&#128657;</span>
        <p style="color:var(--text-muted);">No services found for the selected filter.</p>
        <a href="directory.jsp" class="bv-btn bv-btn-outline" style="margin-top:16px;">Show All</a>
    </div>
    <% } else { %>
    <div style="color:var(--text-muted);font-size:0.85rem;margin-bottom:14px;">
        Showing <strong style="color:#fff;"><%=services.size()%></strong> service(s)
    </div>
    <div class="bv-grid bv-grid-3">
        <% for (java.util.Map<String,String> s : services) { %>
        <div class="em-card">
            <span class="em-card-icon"><%=s.get("icon") != null ? s.get("icon") : "🏢"%></span>
            <div class="em-card-name"><%=sanitize(s.get("name"))%></div>
            <div class="em-card-area">&#128205; <%=sanitize(s.get("area"))%></div>
            <% if (s.get("address") != null && !s.get("address").isEmpty()) { %>
            <div class="em-card-addr">&#128205; <%=sanitize(s.get("address"))%></div>
            <% } %>
            <% if (s.get("phone") != null && !s.get("phone").isEmpty()) { %>
            <a href="tel:<%=sanitize(s.get("phone"))%>" class="em-card-phone">
                &#128222; <%=sanitize(s.get("phone"))%>
            </a>
            <% } else { %>
            <span style="color:var(--text-muted);font-size:0.82rem;">No phone listed</span>
            <% } %>
        </div>
        <% } %>
    </div>
    <% } %>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
