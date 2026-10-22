<%-- ============================================================
     Admin/transportAdmin.jsp
     Admin session required
     Manage INCIDENTS (approve/reject/close) + CROWD_REPORTS
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache");
response.setDateHeader("Expires", 0);
if (!"admin".equalsIgnoreCase((String) session.getAttribute("userType"))) {
    response.sendRedirect(request.getContextPath() + "/admin/login.jsp?msg=noaccess");
    return;
}

String msg = ""; String msgType = "";

/* ── Handle status-change POST ───────────────────────────────── */
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String action     = request.getParameter("action");
    String incidentId = request.getParameter("incidentId");
    String newStatus  = request.getParameter("newStatus");

    if ("updateStatus".equals(action) && incidentId != null && newStatus != null) {
        Connection uCon=null; PreparedStatement uPs=null;
        try {
            uCon = getConnection();
            uPs  = uCon.prepareStatement(
                "UPDATE INCIDENTS SET STATUS=? WHERE INCIDENT_ID=?"
            );
            uPs.setString(1, newStatus.trim());
            uPs.setInt(2, Integer.parseInt(incidentId.trim()));
            uPs.executeUpdate();
            msg = "Incident #" + incidentId + " status → " + newStatus;
            msgType = "success";
        } catch(Exception e) {
            logError("Admin/transportAdmin.jsp", e);
            msg = "Update failed: " + e.getMessage();
            msgType = "danger";
        } finally { closeDB(uCon, uPs, null); }
    }
}

/* ── Filter params ────────────────────────────────────────────── */
String filterStatus = request.getParameter("status") != null ? request.getParameter("status").trim() : "";
String filterArea   = request.getParameter("area")   != null ? request.getParameter("area").trim()   : "";
String filterSev    = request.getParameter("severity")!= null ? request.getParameter("severity").trim(): "";
int    curPage     = 1;
try { curPage = Math.max(1, Integer.parseInt(request.getParameter("page"))); } catch(Exception e) {}
int pageSize = 15;
int offset   = (curPage - 1) * pageSize;

/* ── Fetch distinct areas ─────────────────────────────────────── */
java.util.List<String> areaList = new java.util.ArrayList<>();
Connection aCon=null; PreparedStatement aPs=null; ResultSet aRs=null;
try {
    aCon = getConnection();
    aPs  = aCon.prepareStatement("SELECT DISTINCT AREA FROM INCIDENTS WHERE AREA IS NOT NULL ORDER BY AREA");
    aRs  = aPs.executeQuery();
    while (aRs.next()) areaList.add(aRs.getString("AREA"));
} catch(Exception e) {}
finally { closeDB(aCon, aPs, aRs); }

/* ── Summary stats ────────────────────────────────────────────── */
int totalOpen=0,totalInReview=0,totalResolved=0,totalTotal=0;
Connection stCon=null; PreparedStatement stPs=null; ResultSet stRs=null;
try {
    stCon = getConnection();
    stPs  = stCon.prepareStatement(
        "SELECT STATUS, COUNT(*) AS CNT FROM INCIDENTS GROUP BY STATUS"
    );
    stRs = stPs.executeQuery();
    while (stRs.next()) {
        String st = stRs.getString("STATUS"); int cnt = stRs.getInt("CNT");
        totalTotal += cnt;
        if ("Open".equalsIgnoreCase(st))      totalOpen += cnt;
        if ("In Review".equalsIgnoreCase(st)) totalInReview += cnt;
        if ("Resolved".equalsIgnoreCase(st))  totalResolved += cnt;
    }
} catch(Exception e) {}
finally { closeDB(stCon, stPs, stRs); }

/* ── Fetch incidents with pagination ─────────────────────────── */
java.util.List<java.util.Map<String,String>> incidents = new java.util.ArrayList<>();
int totalRows = 0;
StringBuilder sql = new StringBuilder(
    "SELECT i.INCIDENT_ID, i.REPORTED_BY, i.AREA, i.TITLE, i.DESCRIPTION, " +
    "       i.SEVERITY, i.STATUS, i.CROWD_LEVEL, " +
    "       (SELECT COUNT(*) FROM CROWD_REPORTS cr WHERE cr.INCIDENT_ID=i.INCIDENT_ID) AS REPORT_CNT " +
    "FROM INCIDENTS i WHERE 1=1 "
);
if (!filterStatus.isEmpty()) sql.append("AND UPPER(i.STATUS) = UPPER(?) ");
if (!filterArea.isEmpty())   sql.append("AND UPPER(i.AREA)   = UPPER(?) ");
if (!filterSev.isEmpty())    sql.append("AND UPPER(i.SEVERITY)= UPPER(?) ");
sql.append("ORDER BY i.INCIDENT_ID DESC");

Connection con=null; PreparedStatement ps=null; ResultSet rs=null;
try {
    con = getConnection();
    /* count */
    PreparedStatement cntPs = con.prepareStatement(
        "SELECT COUNT(*) FROM (" + sql.toString() + ")"
    );
    int ci=1;
    if (!filterStatus.isEmpty()) cntPs.setString(ci++, filterStatus);
    if (!filterArea.isEmpty())   cntPs.setString(ci++, filterArea);
    if (!filterSev.isEmpty())    cntPs.setString(ci++, filterSev);
    ResultSet cntRs = cntPs.executeQuery();
    if (cntRs.next()) totalRows = cntRs.getInt(1);
    cntRs.close(); cntPs.close();

    /* paginated */
    String pagSql = "SELECT * FROM (SELECT rownum rn, q.* FROM (" + sql + ") q WHERE rownum <= ?) WHERE rn > ?";
    ps = con.prepareStatement(pagSql);
    int pi=1;
    if (!filterStatus.isEmpty()) ps.setString(pi++, filterStatus);
    if (!filterArea.isEmpty())   ps.setString(pi++, filterArea);
    if (!filterSev.isEmpty())    ps.setString(pi++, filterSev);
    ps.setInt(pi++, offset + pageSize);
    ps.setInt(pi,   offset);
    rs = ps.executeQuery();
    while (rs.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("id",          rs.getString("INCIDENT_ID"));
        row.put("reportedBy",  rs.getString("REPORTED_BY"));
        row.put("area",        rs.getString("AREA"));
        row.put("title",       rs.getString("TITLE"));
        row.put("description", rs.getString("DESCRIPTION"));
        row.put("severity",    rs.getString("SEVERITY"));
        row.put("status",      rs.getString("STATUS"));
        row.put("crowdLevel",  rs.getString("CROWD_LEVEL"));
        row.put("reportCnt",   rs.getString("REPORT_CNT"));
        incidents.add(row);
    }
} catch(Exception e) { logError("Admin/transportAdmin.jsp", e); }
finally { closeDB(con, ps, rs); }

int totalPages = (int) Math.ceil((double) totalRows / pageSize);

/* ── Severity color map ───────────────────────────────────────── */
java.util.Map<String,String> sevColor = new java.util.LinkedHashMap<>();
sevColor.put("Low","#34d399"); sevColor.put("Medium","#fbbf24");
sevColor.put("High","#f87171"); sevColor.put("Critical","#dc2626");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Transport Admin — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.sev-dot { display:inline-block; width:10px; height:10px; border-radius:50%; margin-right:6px; vertical-align:middle; }
.ta-status-select { background:rgba(255,255,255,0.08); border:1px solid var(--glass-bdr); color:#fff; border-radius:6px; padding:4px 8px; font-size:0.8rem; cursor:pointer; }
.ta-status-select option { background:#1f2937; }
.crowd-bar { height:6px; border-radius:3px; background:var(--glass-bdr); overflow:hidden; margin-top:4px; }
.crowd-fill { height:100%; border-radius:3px; background:linear-gradient(90deg,var(--accent),var(--warn)); }
</style>
</head>
<body>
<%@ include file="../admin/nav.jsp" %>

<div class="bv-container">

    <div class="bv-page-header glass">
        <h4>&#128652; Transport Incident Admin</h4>
        <p>Review, update, and manage all reported transport incidents</p>
    </div>

    <% if (!msg.isEmpty()) { %>
    <div class="bv-alert bv-alert-<%=msgType%>"><%=sanitize(msg)%></div>
    <% } %>

    <%-- Stats row --%>
    <div class="bv-grid bv-grid-4" style="margin-bottom:24px;">
        <div class="glass bv-stat"><div class="bv-stat-icon">&#128202;</div><div class="bv-stat-num"><%=totalTotal%></div><div class="bv-stat-lbl">Total Incidents</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--blue);">&#128270;</div><div class="bv-stat-num" style="color:var(--blue);"><%=totalOpen%></div><div class="bv-stat-lbl">Open</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--warn);">&#9203;</div><div class="bv-stat-num" style="color:var(--warn);"><%=totalInReview%></div><div class="bv-stat-lbl">In Review</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--success);">&#10003;</div><div class="bv-stat-num" style="color:var(--success);"><%=totalResolved%></div><div class="bv-stat-lbl">Resolved</div></div>
    </div>

    <%-- Filters --%>
    <form method="get" class="glass bv-filter" style="margin-bottom:18px;">
        <select name="status" class="bv-select">
            <option value="">All Status</option>
            <option value="Open"      <%="Open".equals(filterStatus)?"selected":""%>>Open</option>
            <option value="In Review" <%="In Review".equals(filterStatus)?"selected":""%>>In Review</option>
            <option value="Resolved"  <%="Resolved".equals(filterStatus)?"selected":""%>>Resolved</option>
            <option value="Closed"    <%="Closed".equals(filterStatus)?"selected":""%>>Closed</option>
        </select>
        <select name="severity" class="bv-select">
            <option value="">All Severity</option>
            <option value="Low"      <%="Low".equals(filterSev)?"selected":""%>>Low</option>
            <option value="Medium"   <%="Medium".equals(filterSev)?"selected":""%>>Medium</option>
            <option value="High"     <%="High".equals(filterSev)?"selected":""%>>High</option>
            <option value="Critical" <%="Critical".equals(filterSev)?"selected":""%>>Critical</option>
        </select>
        <select name="area" class="bv-select">
            <option value="">All Areas</option>
            <% for (String a : areaList) { %>
            <option value="<%=sanitize(a)%>" <%=a.equals(filterArea)?"selected":""%>><%=sanitize(a)%></option>
            <% } %>
        </select>
        <button type="submit" class="bv-btn bv-btn-primary bv-btn-sm">&#128269; Filter</button>
        <a href="transportAdmin.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#10006; Reset</a>
    </form>

    <%-- Table --%>
    <div class="glass" style="padding:0;overflow:hidden;">
        <div class="bv-table-wrap">
            <table class="bv-table">
                <thead>
                    <tr>
                        <th>#ID</th>
                        <th>Title / Area</th>
                        <th>Reported By</th>
                        <th>Severity</th>
                        <th>Crowd</th>
                        <th>Reports</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                <% if (incidents.isEmpty()) { %>
                <tr><td colspan="8" style="text-align:center;padding:40px;color:var(--text-muted);">No incidents found.</td></tr>
                <% } else { for (java.util.Map<String,String> inc : incidents) {
                    String sev   = inc.get("severity") != null ? inc.get("severity") : "Low";
                    String sevC  = sevColor.getOrDefault(sev, "#fff");
                    String stat  = inc.get("status")   != null ? inc.get("status")   : "Open";
                    String crowd = inc.get("crowdLevel")!= null ? inc.get("crowdLevel"): "0";
                    int crowdPct = 0;
                    try { crowdPct = Math.min(100, Integer.parseInt(crowd) * 10); } catch(Exception e2){}
                %>
                <tr>
                    <td style="font-weight:700;color:var(--accent);">#<%=sanitize(inc.get("id"))%></td>
                    <td>
                        <div style="font-weight:600;color:#fff;font-size:0.88rem;"><%=sanitize(inc.get("title"))%></div>
                        <div style="font-size:0.78rem;color:var(--text-muted);">&#128205; <%=sanitize(inc.get("area"))%></div>
                    </td>
                    <td style="font-size:0.83rem;"><%=sanitize(inc.get("reportedBy"))%></td>
                    <td>
                        <span class="sev-dot" style="background:<%=sevC%>;"></span>
                        <span style="color:<%=sevC%>;font-weight:600;font-size:0.82rem;"><%=sanitize(sev)%></span>
                    </td>
                    <td style="min-width:80px;">
                        <span style="font-size:0.78rem;color:var(--text-muted);"><%=sanitize(crowd)%>/10</span>
                        <div class="crowd-bar"><div class="crowd-fill" style="width:<%=crowdPct%>%;"></div></div>
                    </td>
                    <td style="text-align:center;">
                        <span class="bv-badge bv-badge-pending"><%=sanitize(inc.get("reportCnt"))%></span>
                    </td>
                    <td>
                        <span class="bv-badge
                            <%="Open".equalsIgnoreCase(stat)?"bv-badge-open":
                               "In Review".equalsIgnoreCase(stat)?"bv-badge-inreview":
                               "Resolved".equalsIgnoreCase(stat)?"bv-badge-resolved":"bv-badge-closed"%>">
                            <%=sanitize(stat)%>
                        </span>
                    </td>
                    <td>
                        <form method="post" style="margin:0;display:inline-flex;gap:4px;align-items:center;">
                            <input type="hidden" name="action"     value="updateStatus">
                            <input type="hidden" name="incidentId" value="<%=sanitize(inc.get("id"))%>">
                            <select name="newStatus" class="ta-status-select">
                                <option value="Open"      <%="Open".equalsIgnoreCase(stat)?"selected":""%>>Open</option>
                                <option value="In Review" <%="In Review".equalsIgnoreCase(stat)?"selected":""%>>In Review</option>
                                <option value="Resolved"  <%="Resolved".equalsIgnoreCase(stat)?"selected":""%>>Resolved</option>
                                <option value="Closed"    <%="Closed".equalsIgnoreCase(stat)?"selected":""%>>Closed</option>
                            </select>
                            <button type="submit" class="bv-btn bv-btn-sm bv-btn-primary">&#10004;</button>
                        </form>
                    </td>
                </tr>
                <% } } %>
                </tbody>
            </table>
        </div>
    </div>

    <%-- Pagination --%>
    <% if (totalPages > 1) { %>
    <div class="bv-pagination" style="margin-top:16px;">
        <span style="color:var(--text-muted);font-size:0.82rem;">
           Showing <%=(offset+1)%>–<%=Math.min(offset+pageSize,totalRows)%> of <%=totalRows%>
        </span>
        <% for (int i=1; i<=totalPages; i++) { %>
        <a href="transportAdmin.jsp?page=<%=i%>&status=<%=sanitize(filterStatus)%>&area=<%=sanitize(filterArea)%>&severity=<%=sanitize(filterSev)%>"
           class="bv-page-btn <%=i==curPage?"active":""%>"
        <% } %>
    </div>
    <% } %>

</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
