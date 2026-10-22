<%-- ============================================================
     Admin/sosAdmin.jsp
     Admin session required
     View all SOS_LOGS, assign service, add note, resolve/reopen
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

/* ── Handle POST ─────────────────────────────────────────────── */
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String action    = request.getParameter("action");
    String sosId     = request.getParameter("sosId");
    String adminNote = request.getParameter("adminNote");
    String assignId  = request.getParameter("assignServiceId");

    if (sosId != null && !sosId.trim().isEmpty()) {
        Connection uC=null; PreparedStatement uP=null;
        try {
            uC = getConnection();
            if ("resolve".equals(action)) {
                uP = uC.prepareStatement(
                    "UPDATE SOS_LOGS SET IS_RESOLVED=1, RESOLVED_AT=CURRENT_TIMESTAMP, " +
                    "ADMIN_NOTE=?, ASSIGNED_SERVICE_ID=? WHERE SOS_ID=?"
                );
                uP.setString(1, adminNote != null ? adminNote.trim() : "");
                if (assignId != null && !assignId.trim().isEmpty()) {
                    uP.setInt(2, Integer.parseInt(assignId.trim()));
                } else { uP.setNull(2, java.sql.Types.INTEGER); }
                uP.setInt(3, Integer.parseInt(sosId.trim()));
                uP.executeUpdate();
                msg = "SOS #" + sosId + " marked as resolved."; msgType = "success";

            } else if ("reopen".equals(action)) {
                uP = uC.prepareStatement(
                    "UPDATE SOS_LOGS SET IS_RESOLVED=0, RESOLVED_AT=NULL WHERE SOS_ID=?"
                );
                uP.setInt(1, Integer.parseInt(sosId.trim()));
                uP.executeUpdate();
                msg = "SOS #" + sosId + " reopened."; msgType = "warn";

            } else if ("note".equals(action)) {
                uP = uC.prepareStatement(
                    "UPDATE SOS_LOGS SET ADMIN_NOTE=?, ASSIGNED_SERVICE_ID=? WHERE SOS_ID=?"
                );
                uP.setString(1, adminNote != null ? adminNote.trim() : "");
                if (assignId != null && !assignId.trim().isEmpty()) {
                    uP.setInt(2, Integer.parseInt(assignId.trim()));
                } else { uP.setNull(2, java.sql.Types.INTEGER); }
                uP.setInt(3, Integer.parseInt(sosId.trim()));
                uP.executeUpdate();
                msg = "SOS #" + sosId + " updated."; msgType = "success";
            }
        } catch(Exception e){ logError("Admin/sosAdmin.jsp#post",e); msg="Update failed."; msgType="danger"; }
        finally{ closeDB(uC,uP,null); }
    }
}

/* ── Filter params ────────────────────────────────────────────── */
String filterResolved = request.getParameter("resolved") != null ? request.getParameter("resolved").trim() : "";
String filterType     = request.getParameter("serviceType")!= null?request.getParameter("serviceType").trim():"";
int curPage = 1;
try{ curPage=Math.max(1,Integer.parseInt(request.getParameter("page"))); }catch(Exception e){}
int pageSize=12; int offset=(curPage-1)*pageSize;

/* ── Stats -──────────────────────────────────────────────────── */
int totAll=0, totPend=0, totResolved=0;
Connection stC=null; PreparedStatement stP=null; ResultSet stR=null;
try {
    stC=getConnection();
    stP=stC.prepareStatement("SELECT IS_RESOLVED, COUNT(*) FROM SOS_LOGS GROUP BY IS_RESOLVED");
    stR=stP.executeQuery();
    while(stR.next()){
        int cnt=stR.getInt(2); totAll+=cnt;
        if(stR.getInt(1)==0) totPend+=cnt; else totResolved+=cnt;
    }
} catch(Exception e){}
finally{ closeDB(stC,stP,stR); }

/* ── Fetch emergency services for dropdown ────────────────────── */
java.util.List<java.util.Map<String,String>> svcList = new java.util.ArrayList<>();
Connection svC=null; PreparedStatement svP=null; ResultSet svR=null;
try {
    svC=getConnection();
    svP=svC.prepareStatement(
        "SELECT es.SERVICE_ID, es.NAME, es.PHONE, st.TYPE_NAME, st.ICON " +
        "FROM EMERGENCY_SERVICES es JOIN SERVICE_TYPES st ON es.TYPE_ID=st.TYPE_ID " +
        "WHERE es.IS_ACTIVE=1 ORDER BY st.TYPE_NAME, es.NAME"
    );
    svR=svP.executeQuery();
    while(svR.next()){
        java.util.Map<String,String> r=new java.util.LinkedHashMap<>();
        r.put("id",svR.getString("SERVICE_ID")); r.put("name",svR.getString("NAME"));
        r.put("phone",svR.getString("PHONE"));   r.put("type",svR.getString("TYPE_NAME"));
        r.put("icon",svR.getString("ICON"));
        svcList.add(r);
    }
} catch(Exception e){}
finally{ closeDB(svC,svP,svR); }

/* ── Fetch SOS logs ───────────────────────────────────────────── */
java.util.List<java.util.Map<String,String>> sosList = new java.util.ArrayList<>();
int totalRows=0;
StringBuilder sql = new StringBuilder(
    "SELECT sl.SOS_ID, sl.USER_EMAIL, sl.SERVICE_TYPE, sl.AREA, sl.DESCRIPTION, " +
    "       sl.IS_RESOLVED, sl.ADMIN_NOTE, sl.CREATED_AT, sl.RESOLVED_AT, " +
    "       sl.ASSIGNED_SERVICE_ID, " +
    "       es.NAME AS SVC_NAME, es.PHONE AS SVC_PHONE, " +
    "       bu.name AS USER_NAME " +
    "FROM SOS_LOGS sl " +
    "LEFT JOIN EMERGENCY_SERVICES es ON sl.ASSIGNED_SERVICE_ID=es.SERVICE_ID " +
    "LEFT JOIN nexshohor_users bu ON sl.USER_EMAIL=bu.email " +
    "WHERE 1=1 "
);
if (!filterResolved.isEmpty()) sql.append("AND sl.IS_RESOLVED=? ");
if (!filterType.isEmpty())     sql.append("AND UPPER(sl.SERVICE_TYPE)=UPPER(?) ");
sql.append("ORDER BY sl.IS_RESOLVED ASC, sl.CREATED_AT DESC");

Connection con=null; PreparedStatement ps=null; ResultSet rs=null;
try {
    con=getConnection();
    PreparedStatement cPs=con.prepareStatement("SELECT COUNT(*) FROM ("+sql+")");
    int ci=1;
    if(!filterResolved.isEmpty()) cPs.setInt(ci++,"0".equals(filterResolved)?0:1);
    if(!filterType.isEmpty())     cPs.setString(ci++,filterType);
    ResultSet cRs=cPs.executeQuery(); if(cRs.next()) totalRows=cRs.getInt(1);
    cRs.close(); cPs.close();

    String pagSql="SELECT * FROM (SELECT rownum rn, q.* FROM ("+sql+") q WHERE rownum<=?) WHERE rn>?";
    ps=con.prepareStatement(pagSql);
    int pi=1;
    if(!filterResolved.isEmpty()) ps.setInt(pi++,"0".equals(filterResolved)?0:1);
    if(!filterType.isEmpty())     ps.setString(pi++,filterType);
    ps.setInt(pi++,offset+pageSize); ps.setInt(pi,offset);
    rs=ps.executeQuery();
    while(rs.next()){
        java.util.Map<String,String> row=new java.util.LinkedHashMap<>();
        row.put("id",         rs.getString("SOS_ID"));
        row.put("userEmail",  rs.getString("USER_EMAIL"));
        row.put("userName",   rs.getString("USER_NAME"));
        row.put("serviceType",rs.getString("SERVICE_TYPE"));
        row.put("area",       rs.getString("AREA"));
        row.put("description",rs.getString("DESCRIPTION"));
        row.put("isResolved", rs.getString("IS_RESOLVED"));
        row.put("adminNote",  rs.getString("ADMIN_NOTE"));
        row.put("createdAt",  rs.getString("CREATED_AT"));
        row.put("resolvedAt", rs.getString("RESOLVED_AT"));
        row.put("assignedId", rs.getString("ASSIGNED_SERVICE_ID"));
        row.put("svcName",    rs.getString("SVC_NAME"));
        row.put("svcPhone",   rs.getString("SVC_PHONE"));
        sosList.add(row);
    }
} catch(Exception e){ logError("Admin/sosAdmin.jsp#list",e); }
finally{ closeDB(con,ps,rs); }

int totalPages=(int)Math.ceil((double)totalRows/pageSize);

java.util.Map<String,String> sosIcons=new java.util.LinkedHashMap<>();
sosIcons.put("hospital","🏥"); sosIcons.put("police","🚔");
sosIcons.put("fire","🚒"); sosIcons.put("ambulance","🚑"); sosIcons.put("pharmacy","💊");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SOS Admin — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.sos-admin-card {
    border-radius:var(--radius); background:var(--glass-bg);
    border:1px solid var(--glass-bdr); margin-bottom:16px;
    overflow:hidden;
}
.sos-admin-card.resolved { opacity:0.65; }
.sos-admin-header {
    padding:14px 18px; display:flex; align-items:center;
    gap:12px; flex-wrap:wrap; justify-content:space-between;
    border-bottom:1px solid var(--glass-bdr);
}
.sos-admin-body { padding:16px 18px; }
.sos-action-form { display:flex; gap:8px; flex-wrap:wrap; align-items:flex-end; margin-top:12px; }
.sos-action-form .bv-select, .sos-action-form .bv-input { flex:1; min-width:140px; }
</style>
</head>
<body>
<%@ include file="../admin/nav.jsp" %>

<div class="bv-container">

    <div class="bv-page-header glass">
        <h4>&#128721; SOS Log Admin</h4>
        <p>View all emergency SOS requests, assign services, add notes and resolve cases</p>
    </div>

    <% if (!msg.isEmpty()) { %>
    <div class="bv-alert bv-alert-<%=msgType%>"><%=sanitize(msg)%></div>
    <% } %>

    <%-- Stats --%>
    <div class="bv-grid bv-grid-4" style="margin-bottom:22px;">
        <div class="glass bv-stat"><div class="bv-stat-icon">&#128721;</div><div class="bv-stat-num"><%=totAll%></div><div class="bv-stat-lbl">Total SOS</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--warn);">&#9203;</div><div class="bv-stat-num" style="color:var(--warn);"><%=totPend%></div><div class="bv-stat-lbl">Pending</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--success);">&#10003;</div><div class="bv-stat-num" style="color:var(--success);"><%=totResolved%></div><div class="bv-stat-lbl">Resolved</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--blue);">&#128657;</div><div class="bv-stat-num" style="color:var(--blue);"><%=svcList.size()%></div><div class="bv-stat-lbl">Active Services</div></div>
    </div>

    <%-- Filters --%>
    <form method="get" class="glass bv-filter" style="margin-bottom:18px;">
        <select name="resolved" class="bv-select">
            <option value="">All</option>
            <option value="0" <%="0".equals(filterResolved)?"selected":""%>>Pending Only</option>
            <option value="1" <%="1".equals(filterResolved)?"selected":""%>>Resolved Only</option>
        </select>
        <select name="serviceType" class="bv-select">
            <option value="">All Types</option>
            <option value="hospital"  <%="hospital".equals(filterType)?"selected":""%>>🏥 Hospital</option>
            <option value="police"    <%="police".equals(filterType)?"selected":""%>>🚔 Police</option>
            <option value="fire"      <%="fire".equals(filterType)?"selected":""%>>🚒 Fire</option>
            <option value="ambulance" <%="ambulance".equals(filterType)?"selected":""%>>🚑 Ambulance</option>
            <option value="pharmacy"  <%="pharmacy".equals(filterType)?"selected":""%>>💊 Pharmacy</option>
        </select>
        <button type="submit" class="bv-btn bv-btn-danger bv-btn-sm">&#128269; Filter</button>
        <a href="sosAdmin.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#10006; Reset</a>
    </form>

    <%-- SOS cards --%>
    <% if (sosList.isEmpty()) { %>
    <div class="bv-empty glass">
        <span class="bv-empty-icon">&#128721;</span>
        <p style="color:var(--text-muted);">No SOS records found.</p>
    </div>
    <% } else { for (java.util.Map<String,String> sos : sosList) {
        boolean resolved   = "1".equals(sos.get("isResolved"));
        String  sType      = sos.get("serviceType") != null ? sos.get("serviceType") : "";
        String  sIcon      = sosIcons.getOrDefault(sType, "🆘");
        String  createdAt  = sos.get("createdAt")  != null ? sos.get("createdAt").substring(0,16)  : "—";
        String  resolvedAt = sos.get("resolvedAt") != null ? sos.get("resolvedAt").substring(0,16) : null;
    %>
    <div class="sos-admin-card <%=resolved?"resolved":""%>">
        <div class="sos-admin-header" style="background:<%=resolved?"rgba(52,211,153,0.04)":"rgba(248,113,113,0.06)"%>;">
            <div style="display:flex;align-items:center;gap:10px;">
                <span style="font-size:1.6rem;"><%=sIcon%></span>
                <div>
                    <div style="font-weight:700;color:#fff;font-size:0.92rem;">
                        SOS #<%=sanitize(sos.get("id"))%> — <%=sanitize(sType.substring(0,1).toUpperCase()+sType.substring(1))%>
                    </div>
                    <div style="font-size:0.79rem;color:var(--text-muted);">
                        &#128205; <%=sanitize(sos.get("area"))%>
                        &nbsp;·&nbsp; &#128100; <%=sanitize(sos.get("userName")!=null?sos.get("userName"):sos.get("userEmail"))%>
                        (<%=sanitize(sos.get("userEmail"))%>)
                        &nbsp;·&nbsp; &#128337; <%=createdAt%>
                    </div>
                </div>
            </div>
            <span class="bv-badge <%=resolved?"bv-badge-approved":"bv-badge-pending"%>">
                <%=resolved?"✅ Resolved":"⏳ Pending"%>
            </span>
        </div>
        <div class="sos-admin-body">
            <% if (sos.get("description")!=null && !sos.get("description").isEmpty()) { %>
            <div style="font-size:0.88rem;color:var(--text-light);margin-bottom:10px;">
                &#128221; <%=sanitize(sos.get("description"))%>
            </div>
            <% } %>
            <% if (sos.get("svcName")!=null) { %>
            <div style="font-size:0.82rem;color:var(--accent);margin-bottom:8px;">
                &#128657; Assigned: <%=sanitize(sos.get("svcName"))%>
                <% if (sos.get("svcPhone")!=null) { %>
                &nbsp;&#128222; <%=sanitize(sos.get("svcPhone"))%>
                <% } %>
            </div>
            <% } %>
            <% if (sos.get("adminNote")!=null && !sos.get("adminNote").isEmpty()) { %>
            <div style="font-size:0.82rem;color:var(--warn);margin-bottom:8px;">
                &#128172; Note: <%=sanitize(sos.get("adminNote"))%>
            </div>
            <% } %>
            <% if (resolvedAt!=null) { %>
            <div style="font-size:0.78rem;color:var(--success);">&#10003; Resolved at: <%=sanitize(resolvedAt)%></div>
            <% } %>

            <%-- Action form --%>
            <form method="post" class="sos-action-form">
                <input type="hidden" name="sosId" value="<%=sanitize(sos.get("id"))%>">
                <select name="assignServiceId" class="bv-select">
                    <option value="">-- Assign Service (optional) --</option>
                    <% for (java.util.Map<String,String> svc : svcList) {
                        boolean sel = svc.get("id").equals(sos.get("assignedId"));
                    %>
                    <option value="<%=sanitize(svc.get("id"))%>" <%=sel?"selected":""%>>
                        <%=sanitize(svc.get("icon"))%> <%=sanitize(svc.get("name"))%> — <%=sanitize(svc.get("type"))%>
                    </option>
                    <% } %>
                </select>
                <input type="text" name="adminNote" class="bv-input"
                    value="<%=sanitize(sos.get("adminNote")!=null?sos.get("adminNote"):"")%>"
                    placeholder="Admin note...">
                <% if (!resolved) { %>
                <button type="submit" name="action" value="resolve" class="bv-btn bv-btn-primary bv-btn-sm">
                    &#10003; Resolve
                </button>
                <% } else { %>
                <button type="submit" name="action" value="reopen" class="bv-btn bv-btn-warn bv-btn-sm">
                    &#8635; Reopen
                </button>
                <% } %>
                <button type="submit" name="action" value="note" class="bv-btn bv-btn-outline bv-btn-sm">
                    &#128172; Save Note
                </button>
            </form>
        </div>
    </div>
    <% } } %>

    <%-- Pagination --%>
    <% if (totalPages > 1) { %>
<div class="bv-pagination">
    <span style="color:var(--text-muted);font-size:0.82rem;">
        Showing <%=(offset+1)%>–<%=Math.min(offset+pageSize,totalRows)%> of <%=totalRows%>
    </span>
    <% for (int i=1; i<=totalPages; i++) { %>
        <a href="sosAdmin.jsp?page=<%=i%>&resolved=<%=sanitize(filterResolved)%>&serviceType=<%=sanitize(filterType)%>"
           class="bv-page-btn <%=(i==curPage)?"active":""%>"><%=i%></a>
    <% } %>
</div>
<% } %>
</div>
<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
