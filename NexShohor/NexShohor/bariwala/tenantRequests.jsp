<%@ page import="java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
String _requiredRole = "Bariwala";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String ownerEmail = _sessionEmail;
String actionMsg  = "";
String actionType = ""; // success | danger | warn

/* ── HANDLE STATUS UPDATE ────────────────────────────────── */
String updateId     = request.getParameter("updateId");
String updateStatus = request.getParameter("updateStatus");

if (updateId != null && updateStatus != null
    && !updateId.trim().isEmpty() && !updateStatus.trim().isEmpty()) {

    // Whitelist allowed statuses
    if (!"Approved".equals(updateStatus) && !"Rejected".equals(updateStatus)) {
        actionMsg  = "Invalid status value.";
        actionType = "danger";
    } else {
        Connection conU = null; PreparedStatement psU = null;
        try {
            int reqId = Integer.parseInt(updateId.trim());
            conU = getConnection();
            conU.setAutoCommit(false);

            // Update only if house belongs to this owner
            psU = conU.prepareStatement(
                "UPDATE TENANT_REQUESTS SET STATUS=? WHERE REQUEST_ID=? " +
                "AND POST_ID IN (SELECT POST_ID FROM HOUSE_POST WHERE OWNER_EMAIL=?) " +
                "AND STATUS='Pending'");
            psU.setString(1, updateStatus);
            psU.setInt   (2, reqId);
            psU.setString(3, ownerEmail);
            int rows = psU.executeUpdate();
            psU.close();

            if (rows > 0 && "Approved".equals(updateStatus)) {
                // Get POST_ID for this request
                psU = conU.prepareStatement(
                    "SELECT POST_ID FROM TENANT_REQUESTS WHERE REQUEST_ID=?");
                psU.setInt(1, reqId);
                ResultSet rsG = psU.executeQuery();
                int pid = 0;
                if (rsG.next()) pid = rsG.getInt("POST_ID");
                rsG.close(); psU.close();

                if (pid > 0) {
                    // Mark house as Rented
                    psU = conU.prepareStatement(
                        "UPDATE HOUSE_POST SET STATUS='Rented' WHERE POST_ID=?");
                    psU.setInt(1, pid);
                    psU.executeUpdate(); psU.close();

                    // Reject all other pending requests for same house
                    psU = conU.prepareStatement(
                        "UPDATE TENANT_REQUESTS SET STATUS='Rejected' " +
                        "WHERE POST_ID=? AND REQUEST_ID<>? AND STATUS='Pending'");
                    psU.setInt(1, pid);
                    psU.setInt(2, reqId);
                    psU.executeUpdate(); psU.close();
                }
            }

            if (rows > 0) {
                conU.commit();
                /* ── Notify the tenant ─────────────────────────────── */
                try {
                    PreparedStatement psNq = conU.prepareStatement(
                        "SELECT TENANT_EMAIL, h.ADDRESS FROM TENANT_REQUESTS tr " +
                        "JOIN HOUSE_POST h ON tr.POST_ID=h.POST_ID WHERE tr.REQUEST_ID=?");
                    psNq.setInt(1,reqId); ResultSet rsNq=psNq.executeQuery();
                    if(rsNq.next()){
                        String tEmail=rsNq.getString("TENANT_EMAIL"), addr=rsNq.getString("ADDRESS");
                        PreparedStatement psN=conU.prepareStatement(
                            "INSERT INTO NOTIFICATIONS(USER_EMAIL,NOTIF_TYPE,TITLE,BODY,LINK_URL) VALUES(?,?,?,?,?)");
                        psN.setString(1,tEmail); psN.setString(2,"request_status");
                        psN.setString(3,"Request "+updateStatus);
                        psN.setString(4,"Your rental request for "+addr+" was "+updateStatus.toLowerCase()+".");
                        psN.setString(5,"../varatiya/myRequests.jsp");
                        psN.executeUpdate(); psN.close(); conU.commit();
                    }
                    rsNq.close(); psNq.close();
                } catch(Exception notifEx) { /* non-critical */ }
                actionMsg  = "Request #" + reqId + " updated to " + updateStatus + ".";
                actionType = "success";
            } else {
                conU.rollback();
                actionMsg  = "Update failed — request not found or already processed.";
                actionType = "warn";
            }

        } catch(NumberFormatException nfe) {
            actionMsg = "Invalid request ID."; actionType = "danger";
        } catch(Exception e) {
            if (conU!=null) try{conU.rollback();}catch(Exception ig){}
            logError("tenantRequests.jsp", e);
            actionMsg = "Server error. Please try again."; actionType = "danger";
        } finally {
            closeDB(conU, psU, null);
        }
    }
}

/* ── PAGINATION & FILTER ─────────────────────────────────── */
int pageSize = 10;
int currentPage = 1;
try { currentPage = Integer.parseInt(request.getParameter("page")); } catch(Exception ig){}
if (currentPage < 1) currentPage = 1;
int offset = (currentPage - 1) * pageSize;

String filterStatus = request.getParameter("status");
if (filterStatus == null) filterStatus = "";
String searchQ = request.getParameter("q");
if (searchQ == null) searchQ = "";

List<Map<String,Object>> requests = new ArrayList<>();
int totalCount = 0;

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();

    String base =
        "FROM TENANT_REQUESTS tr JOIN HOUSE_POST h ON tr.POST_ID=h.POST_ID " +
        "WHERE h.OWNER_EMAIL=?" +
        (!filterStatus.isEmpty() ? " AND tr.STATUS=?" : "") +
        (!searchQ.isEmpty() ? " AND (LOWER(tr.TENANT_NAME) LIKE ? OR LOWER(h.ADDRESS) LIKE ?)" : "");

    // Count
    ps = con.prepareStatement("SELECT COUNT(*) " + base);
    int idx=1;
    ps.setString(idx++, ownerEmail);
    if (!filterStatus.isEmpty()) ps.setString(idx++, filterStatus);
    if (!searchQ.isEmpty()) { String lq="%" + searchQ.toLowerCase() + "%"; ps.setString(idx++, lq); ps.setString(idx++, lq); }
    rs = ps.executeQuery();
    if (rs.next()) totalCount = rs.getInt(1);
    rs.close(); ps.close();

    // Fetch
    ps = con.prepareStatement(
        "SELECT tr.REQUEST_ID,tr.TENANT_NAME,tr.TENANT_EMAIL,tr.TENANT_PHONE," +
        "h.ADDRESS,tr.REQUEST_TYPE,tr.DESCRIPTION,tr.STATUS,tr.CREATED_AT " +
        base + " ORDER BY tr.CREATED_AT DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
    idx=1;
    ps.setString(idx++, ownerEmail);
    if (!filterStatus.isEmpty()) ps.setString(idx++, filterStatus);
    if (!searchQ.isEmpty()) { String lq="%" + searchQ.toLowerCase() + "%"; ps.setString(idx++, lq); ps.setString(idx++, lq); }
    ps.setInt(idx++, offset);
    ps.setInt(idx++, pageSize);
    rs = ps.executeQuery();

    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, HH:mm");
    while (rs.next()) {
        Map<String,Object> m = new HashMap<>();
        m.put("id",          rs.getInt("REQUEST_ID"));
        m.put("tenantName",  rs.getString("TENANT_NAME"));
        m.put("tenantEmail", rs.getString("TENANT_EMAIL"));
        m.put("tenantPhone", rs.getString("TENANT_PHONE"));
        m.put("address",     rs.getString("ADDRESS"));
        m.put("reqType",     rs.getString("REQUEST_TYPE"));
        m.put("description", rs.getString("DESCRIPTION"));
        m.put("status",      rs.getString("STATUS"));
        java.sql.Timestamp ts = rs.getTimestamp("CREATED_AT");
        m.put("date", ts != null ? sdf.format(ts) : "—");
        requests.add(m);
    }
} catch(Exception e) {
    logError("tenantRequests.jsp", e);
    actionMsg = "Error loading requests."; actionType = "danger";
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
<title>Tenant Requests – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head>
<body>
<%@ include file="../includes/bwNav.jsp" %>

<div class="bv-container">

    <div class="glass bv-page-header">
        <h4>&#128101; Tenant Requests</h4>
        <p><%= totalCount %> request<%= totalCount==1?"":"s" %> found</p>
    </div>

    <% if (!actionMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-<%= actionType %>">
        <%= "success".equals(actionType) ? "&#10003;" : "&#9888;" %> <%= sanitize(actionMsg) %>
    </div>
    <% } %>

    <!-- FILTER BAR -->
    <form method="get" class="glass bv-filter" style="margin-bottom:20px;">
        <input type="text" name="q" class="bv-input" placeholder="&#128269; Search by tenant or address..."
               value="<%= sanitize(searchQ) %>" style="flex:2;">
        <select name="status" class="bv-select" style="flex:1;min-width:130px;">
            <option value="">All Status</option>
            <option value="Pending"  <%= "Pending" .equals(filterStatus)?"selected":"" %>>Pending</option>
            <option value="Approved" <%= "Approved".equals(filterStatus)?"selected":"" %>>Approved</option>
            <option value="Rejected" <%= "Rejected".equals(filterStatus)?"selected":"" %>>Rejected</option>
        </select>
        <button type="submit" class="bv-btn bv-btn-primary">Filter</button>
        <a href="tenantRequests.jsp" class="bv-btn bv-btn-outline">Reset</a>
    </form>

    <% if (requests.isEmpty()) { %>
    <div class="glass bv-empty">
        <span class="bv-empty-icon">&#128203;</span>
        <h5>No requests found</h5>
        <p style="color:var(--text-muted);">Requests from tenants will appear here.</p>
    </div>
    <% } else { %>

    <div class="glass" style="overflow:hidden;">
    <div class="bv-table-wrap">
    <table class="bv-table">
        <thead>
        <tr>
            <th>#ID</th>
            <th>Tenant</th>
            <th>Contact</th>
            <th>Property</th>
            <th>Type</th>
            <th>Status</th>
            <th>Date</th>
            <th>Action</th>
        </tr>
        </thead>
        <tbody>
        <% for (Map<String,Object> r : requests) {
               String st = (String) r.get("status");
               if (st == null) st = "Pending";
        %>
        <tr>
            <td><strong>#<%= r.get("id") %></strong></td>
            <td>
                <div style="font-weight:600;"><%= sanitize((String)r.get("tenantName")) %></div>
                <div style="font-size:0.78rem;color:var(--text-muted);"><%= sanitize((String)r.get("tenantEmail")) %></div>
            </td>
            <td><%= sanitize((String)r.get("tenantPhone")) %></td>
            <td style="max-width:160px;word-break:break-word;">&#128205; <%= sanitize((String)r.get("address")) %></td>
            <td><%= sanitize((String)r.get("reqType")) %></td>
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
            <td style="white-space:nowrap;"><%= r.get("date") %></td>
            <td>
                <% if ("Pending".equals(st)) { %>
                <form method="post" style="display:inline;">
                    <input type="hidden" name="updateId"     value="<%= r.get("id") %>">
                    <input type="hidden" name="updateStatus" value="Approved">
                    <input type="hidden" name="page"         value="<%= currentPage %>">
                    <input type="hidden" name="status"       value="<%= sanitize(filterStatus) %>">
                    <button type="submit" class="bv-btn bv-btn-sm"
                            style="background:rgba(52,211,153,0.18);border:1px solid var(--success);color:var(--success);"
                            onclick="return bvConfirm('Approve this request?');">
                        &#10003; Approve
                    </button>
                </form>
                <form method="post" style="display:inline;margin-left:4px;">
                    <input type="hidden" name="updateId"     value="<%= r.get("id") %>">
                    <input type="hidden" name="updateStatus" value="Rejected">
                    <input type="hidden" name="page"         value="<%= currentPage %>">
                    <input type="hidden" name="status"       value="<%= sanitize(filterStatus) %>">
                    <button type="submit" class="bv-btn bv-btn-danger bv-btn-sm"
                            onclick="return bvConfirm('Reject this request?');">
                        &#10005; Reject
                    </button>
                </form>
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
        <% if (currentPage > 1) { %>
            <a href="tenantRequests.jsp?page=<%= currentPage-1 %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>" class="bv-page-btn">&#8249; Prev</a>
        <% } %>
        <% for (int i=1; i<=totalPages; i++) { %>
            <a href="tenantRequests.jsp?page=<%= i %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>"
               class="bv-page-btn <%= i==currentPage?"active":"" %>"><%= i %></a>
        <% } %>
        <% if (currentPage < totalPages) { %>
            <a href="tenantRequests.jsp?page=<%= currentPage+1 %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>" class="bv-page-btn">Next &#8250;</a>
        <% } %>
    </div>
    <% } %>

    <% } %>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
