<%@ page import="java.sql.*,java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
String _requiredRole = "Bariwala";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String ownerEmail = _sessionEmail;
String ownerName  = _sessionUser;

int tenantCount   = 0;
int houseCount    = 0;
int pendingCount  = 0;
int availableCount = 0;

List<Map<String,Object>> myProperties = new ArrayList<>();

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();

    ps = con.prepareStatement(
        "SELECT COUNT(*) FROM TENANT_REQUESTS tr JOIN HOUSE_POST h ON tr.POST_ID=h.POST_ID " +
        "WHERE h.OWNER_EMAIL=? AND tr.STATUS='Approved'");
    ps.setString(1, ownerEmail); rs = ps.executeQuery();
    if (rs.next()) tenantCount = rs.getInt(1);
    rs.close(); ps.close();

    ps = con.prepareStatement("SELECT COUNT(*) FROM HOUSE_POST WHERE OWNER_EMAIL=?");
    ps.setString(1, ownerEmail); rs = ps.executeQuery();
    if (rs.next()) houseCount = rs.getInt(1);
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT COUNT(*) FROM TENANT_REQUESTS tr JOIN HOUSE_POST h ON tr.POST_ID=h.POST_ID " +
        "WHERE h.OWNER_EMAIL=? AND tr.STATUS='Pending'");
    ps.setString(1, ownerEmail); rs = ps.executeQuery();
    if (rs.next()) pendingCount = rs.getInt(1);
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT COUNT(*) FROM HOUSE_POST WHERE OWNER_EMAIL=? AND STATUS='Available'");
    ps.setString(1, ownerEmail); rs = ps.executeQuery();
    if (rs.next()) availableCount = rs.getInt(1);
    rs.close(); ps.close();

    // My properties with pagination (first 6)
    ps = con.prepareStatement(
        "SELECT POST_ID,ADDRESS,PHONE,TOTAL_ROOMS,TOTAL_WASHROOMS,STATUS,VIDEO_LINK " +
        "FROM HOUSE_POST WHERE OWNER_EMAIL=? ORDER BY CREATED_AT DESC " +
        "FETCH FIRST 6 ROWS ONLY");
    ps.setString(1, ownerEmail); rs = ps.executeQuery();
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
        myProperties.add(m);
    }
} catch(Exception e) {
    logError("BaBody.jsp", e);
} finally {
    closeDB(con, ps, rs);
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Bariwala Dashboard – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.welcome-box { padding:28px 32px; margin-bottom:26px; position:relative; }
.welcome-box h3 { font-weight:800; color:#fff; font-size:1.7rem; }
.welcome-box p  { color:rgba(255,255,255,0.75); margin-top:6px; }
.live-badge {
    position:absolute; right:20px; top:18px;
    background:linear-gradient(45deg,#22c55e,#16a34a);
    color:#fff; font-size:0.78rem; padding:5px 12px;
    border-radius:999px; font-weight:600;
    box-shadow:0 0 12px rgba(34,197,94,0.5);
    animation:pulse 2s infinite;
}
@keyframes pulse { 0%,100%{transform:scale(1)} 50%{transform:scale(1.05)} }
.stat-link { text-decoration:none; display:block; }
.bv-stat:hover { transform:translateY(-5px) scale(1.03); }
.bv-stat { transition:0.3s ease; cursor:pointer; }
.action-card { padding:22px; text-decoration:none; display:block; color:inherit; transition:0.3s; }
.action-card:hover { transform:translateY(-5px); }
.action-card h5 { color:#fff; font-weight:700; margin-bottom:6px; }
.action-card p  { color:var(--text-muted); font-size:0.85rem; }
.action-icon   { font-size:2rem; margin-bottom:10px; }
.prop-card { padding:16px; }
.prop-actions { display:flex; gap:8px; margin-top:12px; }
</style>
</head>
<body>
<%@ include file="../bariwala/nav.jsp" %>

<div class="bv-container">

    <!-- WELCOME -->
    <div class="glass welcome-box">
        <span class="live-badge">&#11044; LIVE</span>
        <div style="font-size:2.2rem; color:var(--blue); margin-bottom:10px;">&#127968;</div>
        <h3>Welcome, <%= sanitize(ownerName) %>!</h3>
        <p>Manage your properties, review tenant requests, and track your rental activity.</p>
    </div>

    <!-- STATS -->
    <div class="bv-section-title">Overview</div>
    <div class="bv-grid bv-grid-4" style="margin-bottom:28px;">

        <a class="stat-link" href="manageHouse.jsp">
            <div class="glass bv-stat">
                <div class="bv-stat-icon" style="color:var(--blue);">&#127968;</div>
                <div class="bv-stat-num" style="color:var(--blue);"><%= houseCount %></div>
                <div class="bv-stat-lbl">Total Houses</div>
            </div>
        </a>

        <a class="stat-link" href="manageHouse.jsp">
            <div class="glass bv-stat">
                <div class="bv-stat-icon" style="color:var(--success);">&#128994;</div>
                <div class="bv-stat-num" style="color:var(--success);"><%= availableCount %></div>
                <div class="bv-stat-lbl">Available</div>
            </div>
        </a>

        <a class="stat-link" href="tenantRequests.jsp">
            <div class="glass bv-stat">
                <div class="bv-stat-icon" style="color:var(--warn);">&#9203;</div>
                <div class="bv-stat-num" style="color:var(--warn);"><%= pendingCount %></div>
                <div class="bv-stat-lbl">Pending Requests</div>
            </div>
        </a>

        <a class="stat-link" href="tenantRequests.jsp">
            <div class="glass bv-stat">
                <div class="bv-stat-icon" style="color:var(--accent);">&#128101;</div>
                <div class="bv-stat-num" style="color:var(--accent);"><%= tenantCount %></div>
                <div class="bv-stat-lbl">Approved Tenants</div>
            </div>
        </a>

    </div>

    <!-- QUICK ACTIONS -->
    <div class="bv-section-title">Quick Actions</div>
    <div class="bv-grid bv-grid-3" style="margin-bottom:32px;">

        <div class="glass action-card">
            <a href="AddHouse.jsp" style="text-decoration:none; color:inherit;">
                <div class="action-icon" style="color:var(--success);">&#43;&#127968;</div>
                <h5>Add New House</h5>
                <p>Post a new property listing for tenants to browse.</p>
            </a>
        </div>

        <div class="glass action-card">
            <a href="tenantRequests.jsp" style="text-decoration:none; color:inherit;">
                <div class="action-icon" style="color:var(--warn);">&#128203;</div>
                <h5>Tenant Requests</h5>
                <p>Review and approve or reject incoming rental requests.</p>
            </a>
        </div>

        <div class="glass action-card">
            <a href="manageHouse.jsp" style="text-decoration:none; color:inherit;">
                <div class="action-icon" style="color:var(--blue);">&#128295;</div>
                <h5>Manage Houses</h5>
                <p>Edit or remove your existing property listings.</p>
            </a>
        </div>

    </div>

    <!-- MY PROPERTIES PREVIEW -->
    <div class="bv-section-title">My Recent Properties</div>

    <% if (myProperties.isEmpty()) { %>
    <div class="glass bv-empty">
        <span class="bv-empty-icon">&#127963;</span>
        <h5>No properties yet</h5>
        <p style="color:var(--text-muted); margin-bottom:14px;">Start by adding your first house listing.</p>
        <a href="AddHouse.jsp" class="bv-btn bv-btn-primary">&#43; Add Property</a>
    </div>
    <% } else { %>
    <div class="bv-grid bv-grid-3">
    <% for (Map<String,Object> prop : myProperties) {
           String st = (String) prop.get("status"); %>
        <div class="glass bv-prop-card">
            <div class="prop-card">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;">
                    <span style="color:var(--text-muted);font-size:0.75rem;">#<%= prop.get("id") %></span>
                    <% if ("Rented".equalsIgnoreCase(st)) { %>
                        <span class="bv-badge bv-badge-rented">&#128308; Rented</span>
                    <% } else { %>
                        <span class="bv-badge bv-badge-available">&#128994; Available</span>
                    <% } %>
                </div>
                <div class="bv-prop-address">&#128205; <%= sanitize((String)prop.get("address")) %></div>
                <div class="bv-prop-detail">&#128222; <%= sanitize((String)prop.get("phone")) %></div>
                <div class="bv-prop-detail">&#127960; <%= prop.get("rooms") %> rooms &nbsp;|&nbsp; &#128137; <%= prop.get("washrooms") %> washrooms</div>
                <div class="prop-actions">
                    <a href="editHouse.jsp?id=<%= prop.get("id") %>" class="bv-btn bv-btn-warn bv-btn-sm">&#9998; Edit</a>
                    <a href="deleteHouse.jsp?id=<%= prop.get("id") %>" class="bv-btn bv-btn-danger bv-btn-sm"
                       onclick="return bvConfirm('Delete this property?');">&#128465; Delete</a>
                </div>
            </div>
        </div>
    <% } %>
    </div>
    <% if (houseCount > 6) { %>
    <div style="text-align:center; margin-top:16px;">
        <a href="manageHouse.jsp" class="bv-btn bv-btn-outline">View All <%= houseCount %> Properties &#8594;</a>
    </div>
    <% } %>
    <% } %>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
