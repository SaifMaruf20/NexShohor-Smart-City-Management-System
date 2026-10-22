<%-- ============================================================
     Transport/feed.jsp
     Session required — Bariwala or Varatia
     Incident list with area filter, severity badge, pagination
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String userType  = (String) session.getAttribute("userType");

/* ── Filters ─────────────────────────────────────────────── */
String filterArea     = request.getParameter("area")     != null ? request.getParameter("area").trim()     : "";
String filterSeverity = request.getParameter("severity") != null ? request.getParameter("severity").trim() : "";
int    pageNum        = 1;
try { pageNum = Integer.parseInt(request.getParameter("page")); if(pageNum<1) pageNum=1; } catch(Exception ignored){}
int pageSize = 10;
int offset   = (pageNum - 1) * pageSize;

/* ── Count total for pagination ──────────────────────────── */
int totalCount = 0;
StringBuilder countSql = new StringBuilder("SELECT COUNT(*) FROM INCIDENTS WHERE 1=1 ");
if (!filterArea.isEmpty())     countSql.append("AND LOWER(AREA) LIKE LOWER(?) ");
if (!filterSeverity.isEmpty()) countSql.append("AND SEVERITY = ? ");

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    ps  = con.prepareStatement(countSql.toString());
    int i = 1;
    if (!filterArea.isEmpty())     ps.setString(i++, "%" + filterArea + "%");
    if (!filterSeverity.isEmpty()) ps.setString(i++, filterSeverity);
    rs = ps.executeQuery();
    if (rs.next()) totalCount = rs.getInt(1);
} catch(Exception e) { logError("Transport/feed.jsp count", e); }
finally { closeDB(con, ps, rs); }

int totalPages = (int) Math.ceil((double) totalCount / pageSize);

/* ── Fetch incidents ─────────────────────────────────────── */
java.util.List<java.util.Map<String,String>> incidents = new java.util.ArrayList<>();
StringBuilder sql = new StringBuilder(
    "SELECT INCIDENT_ID, TITLE, AREA, SEVERITY, STATUS, CROWD_LEVEL, CREATED_AT " +
    "FROM INCIDENTS WHERE 1=1 "
);
if (!filterArea.isEmpty())     sql.append("AND LOWER(AREA) LIKE LOWER(?) ");
if (!filterSeverity.isEmpty()) sql.append("AND SEVERITY = ? ");
sql.append("ORDER BY CREATED_AT DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

Connection con2 = null; PreparedStatement ps2 = null; ResultSet rs2 = null;
try {
    con2 = getConnection();
    ps2  = con2.prepareStatement(sql.toString());
    int i = 1;
    if (!filterArea.isEmpty())     ps2.setString(i++, "%" + filterArea + "%");
    if (!filterSeverity.isEmpty()) ps2.setString(i++, filterSeverity);
    ps2.setInt(i++, offset);
    ps2.setInt(i++, pageSize);
    rs2 = ps2.executeQuery();
    while (rs2.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("id",         rs2.getString("INCIDENT_ID"));
        row.put("title",      rs2.getString("TITLE"));
        row.put("area",       rs2.getString("AREA"));
        row.put("severity",   rs2.getString("SEVERITY"));
        row.put("status",     rs2.getString("STATUS"));
        row.put("crowdLevel", rs2.getString("CROWD_LEVEL"));
        row.put("createdAt",  rs2.getString("CREATED_AT"));
        incidents.add(row);
    }
} catch(Exception e) { logError("Transport/feed.jsp fetch", e); }
finally { closeDB(con2, ps2, rs2); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Transport Feed — NexShohor</title>
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
            <h4>&#128652; Transport Incidents</h4>
            <p>Live incident feed — filtered by area &amp; severity</p>
        </div>
        <a href="../user/reportIncident.jsp" class="bv-btn bv-btn-primary">&#43; Report Incident</a>
    </div>

    <%-- Filter bar --%>
    <form method="get" class="glass bv-filter" style="margin-bottom:20px;">
        <input type="text" name="area" class="bv-input" placeholder="&#128205; Filter by area..." value="<%=sanitize(filterArea)%>">
        <select name="severity" class="bv-select">
            <option value="">All Severities</option>
            <% for (String sev : new String[]{"Low","Medium","High","Critical"}) { %>
            <option value="<%=sev%>" <%=sev.equals(filterSeverity)?"selected":""%>><%=sev%></option>
            <% } %>
        </select>
        <button type="submit" class="bv-btn bv-btn-primary bv-btn-sm">Filter</button>
        <a href="feed.jsp" class="bv-btn bv-btn-outline bv-btn-sm">Reset</a>
    </form>

    <div style="color:var(--text-muted);font-size:0.85rem;margin-bottom:14px;">
        Showing <strong style="color:#fff;"><%=incidents.size()%></strong> of <strong style="color:#fff;"><%=totalCount%></strong> incident(s)
    </div>

    <% if (incidents.isEmpty()) { %>
    <div class="bv-empty glass">
        <span class="bv-empty-icon">&#128652;</span>
        <p style="color:var(--text-muted);">No incidents found.</p>
        <a href="feed.jsp" class="bv-btn bv-btn-outline" style="margin-top:16px;">Clear Filters</a>
    </div>
    <% } else { %>
    <div class="glass bv-table-wrap">
    <table class="bv-table">
        <thead>
            <tr>
                <th>Title</th>
                <th>Area</th>
                <th>Severity</th>
                <th>Crowd</th>
                <th>Status</th>
                <th>Reported</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
        <% for (java.util.Map<String,String> inc : incidents) {
            String sev   = inc.get("severity")   != null ? inc.get("severity")   : "";
            String crowd = inc.get("crowdLevel")  != null ? inc.get("crowdLevel") : "";
            String stat  = inc.get("status")      != null ? inc.get("status")     : "";
            String sevCss   = sev.equals("Low")?"sev-low":sev.equals("Medium")?"sev-medium":sev.equals("High")?"sev-high":"sev-critical";
            String crowdCss = crowd.equals("Low")?"crowd-low":crowd.equals("Moderate")?"crowd-mod":crowd.equals("High")?"crowd-high":"crowd-jammed";
            String statCss  = stat.equals("Open")?"stat-open":stat.equals("In Progress")?"stat-prog":"stat-res";
            String createdAt = inc.get("createdAt") != null ? inc.get("createdAt").substring(0,16) : "";
        %>
        <tr>
            <td style="font-weight:600;color:#fff;"><%=sanitize(inc.get("title"))%></td>
            <td><span class="bv-badge" style="background:rgba(96,165,250,0.15);color:#93c5fd;">&#128205; <%=sanitize(inc.get("area"))%></span></td>
            <td><span class="bv-badge <%=sevCss%>"><%=sanitize(sev)%></span></td>
            <td><span class="bv-badge <%=crowdCss%>"><%=sanitize(crowd)%></span></td>
            <td><span class="bv-badge <%=statCss%>"><%=sanitize(stat)%></span></td>
            <td style="color:var(--text-muted);font-size:0.82rem;"><%=sanitize(createdAt)%></td>
            <td><a href="detail.jsp?id=<%=sanitize(inc.get("id"))%>" class="bv-btn bv-btn-sm bv-btn-outline">View</a></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    </div>

    <%-- Pagination --%>
    <% if (totalPages > 1) { %>
    <div class="bv-pagination" style="margin-top:20px;">
        <% if (pageNum > 1) { %>
        <a href="feed.jsp?area=<%=sanitize(filterArea)%>&severity=<%=sanitize(filterSeverity)%>&page=<%=pageNum-1%>" class="bv-page-btn">&laquo; Prev</a>
        <% } %>
        <% for (int p = 1; p <= totalPages; p++) { %>
        <a href="feed.jsp?area=<%=sanitize(filterArea)%>&severity=<%=sanitize(filterSeverity)%>&page=<%=p%>" class="bv-page-btn <%=p==pageNum?"active":""%>"><%=p%></a>
        <% } %>
        <% if (pageNum < totalPages) { %>
        <a href="feed.jsp?area=<%=sanitize(filterArea)%>&severity=<%=sanitize(filterSeverity)%>&page=<%=pageNum+1%>" class="bv-page-btn">Next &raquo;</a>
        <% } %>
    </div>
    <% } %>
    <% } %>

</div>
<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
