<%@ page import="java.sql.*,java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "Varatia";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
/* ── Pagination ─────────────────────────────────────────────── */
int pageSize = 9;
int currentPage = 1;
try { currentPage = Integer.parseInt(request.getParameter("page")); } catch(Exception ig){}
if (currentPage < 1) currentPage = 1;
int offset = (currentPage - 1) * pageSize;

/* ── Search ──────────────────────────────────────────────────── */
String searchQ = request.getParameter("q");
if (searchQ == null) searchQ = "";

List<Map<String,Object>> properties = new ArrayList<>();
int totalCount = 0;

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();

    String base = "FROM HOUSE_POST WHERE STATUS='Available'" +
        (!searchQ.isEmpty() ? " AND (LOWER(ADDRESS) LIKE ? OR LOWER(DESCRIPTION) LIKE ?)" : "");

    // Count
    ps = con.prepareStatement("SELECT COUNT(*) " + base);
    if (!searchQ.isEmpty()) {
        String lq = "%" + searchQ.toLowerCase() + "%";
        ps.setString(1, lq); ps.setString(2, lq);
    }
    rs = ps.executeQuery(); if (rs.next()) totalCount = rs.getInt(1);
    rs.close(); ps.close();

    // Fetch
    ps = con.prepareStatement(
        "SELECT POST_ID,OWNER_EMAIL,PHONE,ADDRESS,TOTAL_ROOMS,TOTAL_WASHROOMS,DESCRIPTION,VIDEO_LINK " +
        base + " ORDER BY CREATED_AT DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
    int idx = 1;
    if (!searchQ.isEmpty()) {
        String lq = "%" + searchQ.toLowerCase() + "%";
        ps.setString(idx++, lq); ps.setString(idx++, lq);
    }
    ps.setInt(idx++, offset);
    ps.setInt(idx++, pageSize);
    rs = ps.executeQuery();
    while (rs.next()) {
        Map<String,Object> m = new HashMap<>();
        m.put("id",          rs.getInt("POST_ID"));
        m.put("ownerEmail",  rs.getString("OWNER_EMAIL"));
        m.put("phone",       rs.getString("PHONE"));
        m.put("address",     rs.getString("ADDRESS"));
        m.put("rooms",       rs.getInt("TOTAL_ROOMS"));
        m.put("washrooms",   rs.getInt("TOTAL_WASHROOMS"));
        m.put("description", rs.getString("DESCRIPTION"));
        m.put("videoLink",   rs.getString("VIDEO_LINK"));
        properties.add(m);
    }
} catch(Exception e) {
    logError("browseProperties.jsp", e);
} finally {
    closeDB(con, ps, rs);
}

int totalPages = (int)Math.ceil((double)totalCount / pageSize);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Browse Properties – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.bv-req-btn {
    display:block; width:100%; padding:9px; border:none;
    border-radius:8px; text-align:center; font-weight:600;
    font-size:0.88rem; text-decoration:none; transition:0.2s;
    background: linear-gradient(135deg, var(--accent-dark), var(--accent));
    color:#000; cursor:pointer;
}
.bv-req-btn:hover { opacity:0.88; transform:translateY(-1px); }
</style>
</head>
<body>
<%@ include file="../varatiya/nav.jsp" %>

<div class="bv-container">

    <div class="glass bv-page-header">
        <h4>&#127963; Browse Properties</h4>
        <p><%= totalCount %> propert<%= totalCount==1?"y":"ies" %> available</p>
    </div>

    <!-- SEARCH BAR -->
    <form method="get" class="glass bv-filter" style="margin-bottom:24px;">
        <input type="text" name="q" class="bv-input" placeholder="&#128269; Search by address or description..."
               value="<%= sanitize(searchQ) %>" style="flex:1;">
        <button type="submit" class="bv-btn bv-btn-primary">Search</button>
        <% if (!searchQ.isEmpty()) { %>
        <a href="browse.jsp" class="bv-btn bv-btn-outline">&#10005; Clear</a>
        <% } %>
    </form>

    <% if (properties.isEmpty()) { %>
    <div class="glass bv-empty">
        <span class="bv-empty-icon">&#127963;</span>
        <h5>No properties found</h5>
        <p style="color:var(--text-muted);">
            <%= !searchQ.isEmpty() ? "Try a different search term." : "No properties are listed yet." %>
        </p>
    </div>
    <% } else { %>

    <div class="bv-grid bv-grid-3">
    <% for (Map<String,Object> prop : properties) {
           String vl = (String) prop.get("videoLink");
           String embedUrl = null;
           if (vl != null && !vl.isEmpty()) {
               try {
                   java.util.regex.Matcher mt =
                       java.util.regex.Pattern.compile("(?:v=|/)([0-9A-Za-z_-]{11})").matcher(vl);
                   if (mt.find()) embedUrl = "https://www.youtube.com/embed/" + mt.group(1);
               } catch(Exception ig){}
           }
           String desc = prop.get("description") != null ? prop.get("description").toString() : "";
           String addrEncoded = "";
           try { addrEncoded = java.net.URLEncoder.encode(prop.get("address").toString(), "UTF-8"); } catch(Exception ig){}
    %>
    <div class="glass bv-prop-card">

        <% if (embedUrl != null) { %>
            <iframe src="<%= embedUrl %>" class="bv-prop-thumb"
                    allow="accelerometer; autoplay; encrypted-media" allowfullscreen></iframe>
        <% } else { %>
            <div class="bv-prop-placeholder">&#127968;</div>
        <% } %>

        <div class="bv-prop-body">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
                <span class="bv-badge bv-badge-available">&#128994; Available</span>
            </div>

            <div class="bv-prop-address">&#128205; <%= sanitize((String)prop.get("address")) %></div>
            <div class="bv-prop-detail">&#128222; <%= sanitize((String)prop.get("phone")) %></div>
            <div class="bv-prop-detail">&#9993; <%= sanitize((String)prop.get("ownerEmail")) %></div>
            <div class="bv-prop-detail">
                &#127960; <%= prop.get("rooms") %> Room(s) &nbsp;|&nbsp; &#128137; <%= prop.get("washrooms") %> Washroom(s)
            </div>
            <% if (!desc.isEmpty()) { %>
            <div class="bv-prop-detail" style="margin-top:6px;">
                &#8505; <%= sanitize(desc.length()>90 ? desc.substring(0,90)+"…" : desc) %>
            </div>
            <% } %>

            <div style="margin-top:14px;">
                <a href="submitRequest.jsp?postId=<%= prop.get("id") %>&address=<%= addrEncoded %>"
                   class="bv-req-btn">
                    &#128228; Send Rental Request
                </a>
            </div>
        </div>
    </div>
    <% } %>
    </div>

    <!-- PAGINATION -->
    <% if (totalPages > 1) { %>
    <div class="bv-pagination" style="justify-content:center;margin-top:24px;">
        <% if (currentPage > 1) { %>
            <a href="browseProperties.jsp?page=<%= currentPage-1 %>&q=<%= sanitize(searchQ) %>" class="bv-page-btn">&#8249; Prev</a>
        <% } %>
        <% for (int i=1; i<=totalPages; i++) { %>
            <a href="browseProperties.jsp?page=<%= i %>&q=<%= sanitize(searchQ) %>"
               class="bv-page-btn <%= i==currentPage?"active":"" %>"><%= i %></a>
        <% } %>
        <% if (currentPage < totalPages) { %>
            <a href="browseProperties.jsp?page=<%= currentPage+1 %>&q=<%= sanitize(searchQ) %>" class="bv-page-btn">Next &#8250;</a>
        <% } %>
    </div>
    <% } %>

    <% } %>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
