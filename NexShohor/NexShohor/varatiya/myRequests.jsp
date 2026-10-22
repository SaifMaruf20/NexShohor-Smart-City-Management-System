<%@ page import="java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
String _requiredRole = "Varatia";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String tenantEmail = _sessionEmail;
String actionMsg   = "";
String actionType  = "";

/* ── Handle Cancel ───────────────────────────────────────── */
String cancelId = request.getParameter("cancelId");
if (cancelId != null && !cancelId.trim().isEmpty()) {
    Connection conC = null; PreparedStatement psC = null;
    try {
        int cid = Integer.parseInt(cancelId.trim());
        conC = getConnection(); conC.setAutoCommit(false);
        psC  = conC.prepareStatement(
            "UPDATE TENANT_REQUESTS SET STATUS='Cancelled' " +
            "WHERE REQUEST_ID=? AND TENANT_EMAIL=? AND STATUS='Pending'");
        psC.setInt(1, cid); psC.setString(2, tenantEmail);
        int rows = psC.executeUpdate();
        if (rows > 0) { conC.commit(); actionMsg="Request #"+cid+" cancelled."; actionType="success"; }
        else { conC.rollback(); actionMsg="Cancel failed — request not found or already processed."; actionType="warn"; }
    } catch(Exception e) {
        if (conC!=null) try{conC.rollback();}catch(Exception ig){}
        logError("myRequests.jsp", e); actionMsg="Server error."; actionType="danger";
    } finally { closeDB(conC, psC, null); }
}

/* ── Pagination & Filter ─────────────────────────────────── */
int pageSize = 8;
int currentPage = 1;
try { currentPage = Integer.parseInt(request.getParameter("page")); } catch(Exception ig){}
if (currentPage < 1) currentPage = 1;
int offset = (currentPage-1)*pageSize;

String filterStatus = request.getParameter("status");
if (filterStatus == null) filterStatus = "";

List<Map<String,Object>> reqs = new ArrayList<>();
int totalCount = 0;

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    String base =
        "FROM TENANT_REQUESTS tr LEFT JOIN HOUSE_POST h ON tr.POST_ID=h.POST_ID " +
        "WHERE tr.TENANT_EMAIL=?" +
        (!filterStatus.isEmpty() ? " AND tr.STATUS=?" : "");

    ps = con.prepareStatement("SELECT COUNT(*) " + base);
    ps.setString(1, tenantEmail);
    if (!filterStatus.isEmpty()) ps.setString(2, filterStatus);
    rs = ps.executeQuery(); if (rs.next()) totalCount = rs.getInt(1);
    rs.close(); ps.close();

    ps = con.prepareStatement(
        "SELECT tr.REQUEST_ID,tr.TENANT_NAME,tr.TENANT_PHONE,h.ADDRESS,h.TOTAL_ROOMS," +
        "h.TOTAL_WASHROOMS,tr.REQUEST_TYPE,tr.DESCRIPTION,tr.STATUS,tr.CREATED_AT " +
        base + " ORDER BY tr.CREATED_AT DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
    int idx=1;
    ps.setString(idx++, tenantEmail);
    if (!filterStatus.isEmpty()) ps.setString(idx++, filterStatus);
    ps.setInt(idx++, offset); ps.setInt(idx++, pageSize);
    rs = ps.executeQuery();

    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, HH:mm");
    while (rs.next()) {
        Map<String,Object> m = new HashMap<>();
        m.put("id",          rs.getInt("REQUEST_ID"));
        m.put("address",     rs.getString("ADDRESS"));
        m.put("rooms",       rs.getInt("TOTAL_ROOMS"));
        m.put("washrooms",   rs.getInt("TOTAL_WASHROOMS"));
        m.put("reqType",     rs.getString("REQUEST_TYPE"));
        m.put("description", rs.getString("DESCRIPTION"));
        m.put("status",      rs.getString("STATUS"));
        java.sql.Timestamp ts = rs.getTimestamp("CREATED_AT");
        m.put("date", ts != null ? sdf.format(ts) : "—");
        reqs.add(m);
    }
} catch(Exception e) {
    logError("myRequests.jsp", e); actionMsg="Error loading requests."; actionType="danger";
} finally { closeDB(con, ps, rs); }

int totalPages = (int)Math.ceil((double)totalCount/pageSize);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Requests – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head>
<body>
<%@ include file="../varatiya/nav.jsp" %>

<div class="bv-container">

    <div class="glass bv-page-header">
        <h4>&#128203; My Rental Requests</h4>
        <p><%= totalCount %> request<%= totalCount==1?"":"s" %> found</p>
    </div>

    <% if (!actionMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-<%= actionType %>">
        <%= "success".equals(actionType)?"&#10003;":"&#9888;" %> <%= sanitize(actionMsg) %>
    </div>
    <% } %>

    <!-- FILTER TABS -->
    <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:20px;">
        <% String[] statuses = {"","Pending","Approved","Rejected","Cancelled"};
           String[] labels   = {"All","Pending","Approved","Rejected","Cancelled"};
           for (int i=0;i<statuses.length;i++) { %>
        <a href="myRequests.jsp?status=<%= statuses[i] %>"
           class="bv-page-btn <%= filterStatus.equals(statuses[i])?"active":"" %>">
            <%= labels[i] %>
        </a>
        <% } %>
        <a href="browse.jsp" class="bv-btn bv-btn-primary bv-btn-sm" style="margin-left:auto;">
            &#43; New Request
        </a>
    </div>

    <% if (reqs.isEmpty()) { %>
    <div class="glass bv-empty">
        <span class="bv-empty-icon">&#128203;</span>
        <h5>No requests yet</h5>
        <p style="color:var(--text-muted);margin-bottom:14px;">Browse properties and submit a rental request.</p>
        <a href="browse.jsp" class="bv-btn bv-btn-primary">&#128269; Browse Properties</a>
    </div>
    <% } else { %>

    <div class="glass" style="overflow:hidden;">
    <div class="bv-table-wrap">
    <table class="bv-table">
        <thead>
        <tr>
            <th>#</th>
            <th>Property</th>
            <th>Rooms</th>
            <th>Type</th>
            <th>Description</th>
            <th>Status</th>
            <th>Date</th>
            <th>Action</th>
        </tr>
        </thead>
        <tbody>
        <% int rowNum = offset+1;
           for (Map<String,Object> req : reqs) {
               String st = (String) req.get("status");
               if (st == null) st = "Pending";
               String desc = req.get("description") != null ? req.get("description").toString() : "";
        %>
        <tr>
            <td><%= rowNum++ %></td>
            <td style="max-width:160px;word-break:break-word;">
                &#128205; <%= sanitize((String)req.get("address")) != null ? sanitize((String)req.get("address")) : "—" %>
            </td>
            <td>
                <div>&#127960; <%= req.get("rooms") %></div>
                <div>&#128137; <%= req.get("washrooms") %></div>
            </td>
            <td><%= sanitize((String)req.get("reqType")) %></td>
            <td style="max-width:160px;word-break:break-word;">
                <%= sanitize(desc.length()>60 ? desc.substring(0,60)+"…" : (desc.isEmpty()?"—":desc)) %>
            </td>
            <td>
                <% if ("Pending".equals(st)) { %>
                    <span class="bv-badge bv-badge-pending">&#9203; Pending</span>
                <% } else if ("Approved".equals(st)) { %>
                    <span class="bv-badge bv-badge-approved">&#10003; Approved</span>
                <% } else if ("Rejected".equals(st)) { %>
                    <span class="bv-badge bv-badge-rejected">&#10005; Rejected</span>
                <% } else { %>
                    <span class="bv-badge bv-badge-cancelled"><%= sanitize(st) %></span>
                <% } %>
            </td>
            <td style="white-space:nowrap;"><%= req.get("date") %></td>
            <td>
                <% if ("Pending".equals(st)) { %>
                <a href="myRequests.jsp?cancelId=<%= req.get("id") %>&status=<%= sanitize(filterStatus) %>&page=<%= currentPage %>"
                   class="bv-btn bv-btn-danger bv-btn-sm"
                   onclick="return bvConfirm('Cancel this request?');">
                    &#128465; Cancel
                </a>
                <% } else { %>
                    <span style="color:var(--text-muted);">—</span>
                <% } %>
                <a href="../includes/chat.jsp?rid=<%= req.get("id") %>"
                   class="bv-btn bv-btn-blue bv-btn-sm" style="margin-top:4px;display:inline-block;">
                   &#128172; Chat
                </a>
            </td>
        </tr>
        <% } %>
        </tbody>
    </table>
    </div>
    </div>

    <!-- PAGINATION -->
    <% if (totalPages > 1) { %>
    <div class="bv-pagination" style="justify-content:center;margin-top:20px;">
        <% if (currentPage>1) { %>
            <a href="myRequests.jsp?page=<%= currentPage-1 %>&status=<%= sanitize(filterStatus) %>" class="bv-page-btn">&#8249; Prev</a>
        <% } %>
        <% for (int i=1; i<=totalPages; i++) { %>
            <a href="myRequests.jsp?page=<%= i %>&status=<%= sanitize(filterStatus) %>"
               class="bv-page-btn <%= i==currentPage?"active":"" %>"><%= i %></a>
        <% } %>
        <% if (currentPage<totalPages) { %>
            <a href="myRequests.jsp?page=<%= currentPage+1 %>&status=<%= sanitize(filterStatus) %>" class="bv-page-btn">Next &#8250;</a>
        <% } %>
    </div>
    <% } %>

    <% } %>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
