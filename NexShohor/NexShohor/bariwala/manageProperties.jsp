<%@ page import="java.sql.*,java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
String _requiredRole = "Bariwala";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String ownerEmail = _sessionEmail;

/* ── Pagination ────────────────────────────────────────────── */
int pageSize = 9;
int currentPage = 1;
try { currentPage = Integer.parseInt(request.getParameter("page")); } catch(Exception ig){}
if (currentPage < 1) currentPage = 1;
int offset = (currentPage - 1) * pageSize;

/* ── Search/Filter ──────────────────────────────────────────── */
String filterStatus = request.getParameter("status");
if (filterStatus == null) filterStatus = "";
String searchQ = request.getParameter("q");
if (searchQ == null) searchQ = "";

List<Map<String,Object>> properties = new ArrayList<>();
int totalCount = 0;

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();

    // Count total
    String countSql = "SELECT COUNT(*) FROM HOUSE_POST WHERE OWNER_EMAIL=?" +
        (!filterStatus.isEmpty() ? " AND STATUS=?" : "") +
        (!searchQ.isEmpty() ? " AND LOWER(ADDRESS) LIKE ?" : "");
    ps = con.prepareStatement(countSql);
    int idx=1;
    ps.setString(idx++, ownerEmail);
    if (!filterStatus.isEmpty()) ps.setString(idx++, filterStatus);
    if (!searchQ.isEmpty()) ps.setString(idx++, "%" + searchQ.toLowerCase() + "%");
    rs = ps.executeQuery();
    if (rs.next()) totalCount = rs.getInt(1);
    rs.close(); ps.close();

    // Fetch page
    String dataSql = "SELECT POST_ID,ADDRESS,PHONE,TOTAL_ROOMS,TOTAL_WASHROOMS,STATUS,VIDEO_LINK " +
        "FROM HOUSE_POST WHERE OWNER_EMAIL=?" +
        (!filterStatus.isEmpty() ? " AND STATUS=?" : "") +
        (!searchQ.isEmpty() ? " AND LOWER(ADDRESS) LIKE ?" : "") +
        " ORDER BY CREATED_AT DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
    ps = con.prepareStatement(dataSql);
    idx=1;
    ps.setString(idx++, ownerEmail);
    if (!filterStatus.isEmpty()) ps.setString(idx++, filterStatus);
    if (!searchQ.isEmpty()) ps.setString(idx++, "%" + searchQ.toLowerCase() + "%");
    ps.setInt(idx++, offset);
    ps.setInt(idx++, pageSize);
    rs = ps.executeQuery();
    while (rs.next()) {
        Map<String,Object> m = new HashMap<>();
        m.put("id",        rs.getInt("POST_ID"));
        m.put("address",   rs.getString("ADDRESS"));
        m.put("phone",     rs.getString("PHONE"));
        m.put("rooms",     rs.getInt("TOTAL_ROOMS"));
        m.put("washrooms", rs.getInt("TOTAL_WASHROOMS"));
        String st = rs.getString("STATUS");
        m.put("status",    st != null ? st : "Available");
        m.put("videoLink", rs.getString("VIDEO_LINK"));
        properties.add(m);
    }
} catch(Exception e) {
    logError("manageHouse.jsp", e);
} finally {
    closeDB(con, ps, rs);
}

int totalPages = (int) Math.ceil((double)totalCount / pageSize);

/* ── Build YouTube embed helper ─────────────────────────────── */
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Manage Houses – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head>
<body>
<%@ include file="../includes/bwNav.jsp" %>

<div class="bv-container">

    <div class="glass bv-page-header">
        <h4>&#127963; Manage Houses</h4>
        <p><%= totalCount %> propert<%= totalCount==1?"y":"ies" %> found</p>
    </div>

    <!-- FILTER BAR -->
    <form method="get" class="glass bv-filter" style="margin-bottom:20px;">
        <input type="text" name="q" class="bv-input" placeholder="&#128269; Search by address..."
               value="<%= sanitize(searchQ) %>" style="flex:2;">
        <select name="status" class="bv-select" style="flex:1; min-width:130px;">
            <option value="">All Status</option>
            <option value="Available" <%= "Available".equals(filterStatus)?"selected":"" %>>Available</option>
            <option value="Rented"    <%= "Rented".equals(filterStatus)   ?"selected":"" %>>Rented</option>
        </select>
        <button type="submit" class="bv-btn bv-btn-primary">Filter</button>
        <a href="manageHouse.jsp" class="bv-btn bv-btn-outline">Reset</a>
        <a href="AddHouse.jsp"    class="bv-btn bv-btn-primary">&#43; Add House</a>
    </form>

    <% if (properties.isEmpty()) { %>
    <div class="glass bv-empty">
        <span class="bv-empty-icon">&#127963;</span>
        <h5>No properties found</h5>
        <p style="color:var(--text-muted); margin-bottom:14px;">Try a different filter or add a new property.</p>
        <a href="AddHouse.jsp" class="bv-btn bv-btn-primary">&#43; Add Property</a>
    </div>
    <% } else { %>

    <div class="bv-grid bv-grid-3">
    <% for (Map<String,Object> prop : properties) {
           String st = (String) prop.get("status");
           String vl = (String) prop.get("videoLink");
           // Extract YouTube ID
           String embedUrl = null;
           if (vl != null && !vl.isEmpty()) {
               try {
                   java.util.regex.Matcher m =
                       java.util.regex.Pattern.compile("(?:v=|/)([0-9A-Za-z_-]{11})").matcher(vl);
                   if (m.find()) embedUrl = "https://www.youtube.com/embed/" + m.group(1);
               } catch(Exception ig){}
           }
    %>
    <div class="glass bv-prop-card">

        <% if (embedUrl != null) { %>
            <iframe src="<%= embedUrl %>" class="bv-prop-thumb" allowfullscreen></iframe>
        <% } else { %>
            <div class="bv-prop-placeholder">&#127968;</div>
        <% } %>

        <div class="bv-prop-body">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
                <span style="color:var(--text-muted);font-size:0.73rem;">#<%= prop.get("id") %></span>
                <% if ("Rented".equalsIgnoreCase(st)) { %>
                    <span class="bv-badge bv-badge-rented">&#128308; Rented</span>
                <% } else { %>
                    <span class="bv-badge bv-badge-available">&#128994; Available</span>
                <% } %>
            </div>
            <div class="bv-prop-address">&#128205; <%= sanitize((String)prop.get("address")) %></div>
            <div class="bv-prop-detail">&#128222; <%= sanitize((String)prop.get("phone")) %></div>
            <div class="bv-prop-detail">&#127960; <%= prop.get("rooms") %> rooms | &#128137; <%= prop.get("washrooms") %> washrooms</div>

            <div style="display:flex;gap:8px;margin-top:14px;">
                <a href="editHouse.jsp?id=<%= prop.get("id") %>" class="bv-btn bv-btn-warn bv-btn-sm" style="flex:1;text-align:center;">&#9998; Edit</a>
                <a href="deleteHouse.jsp?id=<%= prop.get("id") %>" class="bv-btn bv-btn-danger bv-btn-sm" style="flex:1;text-align:center;"
                   onclick="return bvConfirm('Delete property #<%= prop.get("id") %>?');">&#128465; Delete</a>
            </div>
        </div>
    </div>
    <% } %>
    </div>

    <!-- PAGINATION -->
    <% if (totalPages > 1) { %>
    <div class="bv-pagination" style="justify-content:center;">
        <% if (currentPage > 1) { %>
            <a href="manageHouse.jsp?page=<%= currentPage-1 %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>" class="bv-page-btn">&#8249; Prev</a>
        <% } %>
        <% for (int i=1; i<=totalPages; i++) { %>
            <a href="manageHouse.jsp?page=<%= i %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>"
               class="bv-page-btn <%= i==currentPage?"active":"" %>"><%= i %></a>
        <% } %>
        <% if (currentPage < totalPages) { %>
            <a href="manageHouse.jsp?page=<%= currentPage+1 %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>" class="bv-page-btn">Next &#8250;</a>
        <% } %>
    </div>
    <% } %>

    <% } %>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
