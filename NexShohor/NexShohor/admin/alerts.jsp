<%-- ============================================================
     Admin/alertsAdmin.jsp
     Admin session required
     Manage URBAN_ALERTS — create, deactivate, delete
     Also shows ALERT_BOOKMARKS stats per alert
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

String adminEmail = (String) session.getAttribute("userEmail");
String adminName  = (String) session.getAttribute("user");
String msg = ""; String msgType = "";

/* ── Handle POST ─────────────────────────────────────────────── */
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String action = request.getParameter("action");

    if ("create".equals(action)) {
        String areaId    = request.getParameter("areaId");
        String alertType = request.getParameter("alertType");
        String title     = request.getParameter("title");
        String desc      = request.getParameter("description");
        String expiresAt = request.getParameter("expiresAt");

        if (title==null||title.trim().isEmpty()||areaId==null||areaId.trim().isEmpty()||alertType==null||alertType.trim().isEmpty()) {
            msg="Title, area and type are required."; msgType="danger";
        } else {
            Connection cC=null; PreparedStatement cP=null;
            try {
                cC=getConnection();
                cP=cC.prepareStatement(
                    "INSERT INTO URBAN_ALERTS (ISSUED_BY_ADMIN,AREA_ID,ALERT_TYPE,TITLE,DESCRIPTION,EXPIRES_AT,IS_ACTIVE) " +
                    "VALUES(?,?,?,?,?,?,1)"
                );
                cP.setString(1, adminName);
                cP.setInt(2, Integer.parseInt(areaId.trim()));
                cP.setString(3, alertType.trim());
                cP.setString(4, title.trim());
                cP.setString(5, desc!=null?desc.trim():"");
                if (expiresAt!=null&&!expiresAt.trim().isEmpty()) {
                    cP.setTimestamp(6, java.sql.Timestamp.valueOf(expiresAt.trim().replace("T"," ")+":00"));
                } else { cP.setNull(6, java.sql.Types.TIMESTAMP); }
                cP.executeUpdate();
                msg="Alert published successfully."; msgType="success";
            } catch(Exception e){ logError("Admin/alertsAdmin.jsp#create",e); msg="Create failed: "+e.getMessage(); msgType="danger"; }
            finally{ closeDB(cC,cP,null); }
        }

    } else if ("toggle".equals(action)) {
        String alertId = request.getParameter("alertId");
        String curAct  = request.getParameter("curActive");
        if (alertId!=null&&!alertId.trim().isEmpty()) {
            Connection tC=null; PreparedStatement tP=null;
            try {
                tC=getConnection();
                tP=tC.prepareStatement("UPDATE URBAN_ALERTS SET IS_ACTIVE=? WHERE ALERT_ID=?");
                tP.setInt(1,"1".equals(curAct)?0:1);
                tP.setInt(2,Integer.parseInt(alertId.trim()));
                tP.executeUpdate();
                msg="Alert status updated."; msgType="success";
            } catch(Exception e){ msg="Toggle failed."; msgType="danger"; }
            finally{ closeDB(tC,tP,null); }
        }

    } else if ("delete".equals(action)) {
        String alertId = request.getParameter("alertId");
        if (alertId!=null&&!alertId.trim().isEmpty()) {
            Connection dC=null; PreparedStatement dP=null;
            try {
                dC=getConnection();
                dP=dC.prepareStatement("DELETE FROM ALERT_BOOKMARKS WHERE ALERT_ID=?");
                dP.setInt(1,Integer.parseInt(alertId.trim())); dP.executeUpdate(); dP.close();
                dP=dC.prepareStatement("DELETE FROM URBAN_ALERTS WHERE ALERT_ID=?");
                dP.setInt(1,Integer.parseInt(alertId.trim())); dP.executeUpdate();
                msg="Alert deleted."; msgType="warn";
            } catch(Exception e){ msg="Delete failed."; msgType="danger"; }
            finally{ closeDB(dC,dP,null); }
        }
    }
}

/* ── Fetch areas ──────────────────────────────────────────────── */
java.util.List<java.util.Map<String,String>> areas = new java.util.ArrayList<>();
Connection arC=null; PreparedStatement arP=null; ResultSet arR=null;
try {
    arC=getConnection();
    arP=arC.prepareStatement("SELECT AREA_ID,AREA_NAME FROM UA_AREAS WHERE IS_ACTIVE=1 ORDER BY AREA_NAME");
    arR=arP.executeQuery();
    while(arR.next()){
        java.util.Map<String,String> r=new java.util.LinkedHashMap<>();
        r.put("id",arR.getString("AREA_ID")); r.put("name",arR.getString("AREA_NAME")); areas.add(r);
    }
} catch(Exception e){}
finally{ closeDB(arC,arP,arR); }

/* ── Filter ───────────────────────────────────────────────────── */
String filterActive = request.getParameter("active")    != null ? request.getParameter("active").trim() : "";
String filterType   = request.getParameter("alert_type")!= null ? request.getParameter("alert_type").trim():"";

/* ── Stats ────────────────────────────────────────────────────── */
int totActive=0,totExpired=0;
Connection stC=null; PreparedStatement stP=null; ResultSet stR=null;
try {
    stC=getConnection();
    stP=stC.prepareStatement("SELECT IS_ACTIVE,COUNT(*) FROM URBAN_ALERTS GROUP BY IS_ACTIVE");
    stR=stP.executeQuery();
    while(stR.next()){ if(stR.getInt(1)==1) totActive=stR.getInt(2); else totExpired=stR.getInt(2); }
} catch(Exception e){}
finally{ closeDB(stC,stP,stR); }

/* ── Fetch alerts ─────────────────────────────────────────────── */
java.util.List<java.util.Map<String,String>> alerts = new java.util.ArrayList<>();
StringBuilder sql = new StringBuilder(
    "SELECT ua.ALERT_ID, ua.ISSUED_BY_ADMIN, ua.ALERT_TYPE, ua.TITLE, ua.DESCRIPTION, " +
    "       ua.EXPIRES_AT, ua.IS_ACTIVE, ua.CREATED_AT, ar.AREA_NAME, " +
    "       (SELECT COUNT(*) FROM ALERT_BOOKMARKS ab WHERE ab.ALERT_ID=ua.ALERT_ID) AS BK_CNT " +
    "FROM URBAN_ALERTS ua JOIN UA_AREAS ar ON ua.AREA_ID=ar.AREA_ID WHERE 1=1 "
);
if (!filterActive.isEmpty()) sql.append("AND ua.IS_ACTIVE=? ");
if (!filterType.isEmpty())   sql.append("AND ua.ALERT_TYPE=? ");
sql.append("ORDER BY ua.CREATED_AT DESC");

Connection con=null; PreparedStatement ps=null; ResultSet rs=null;
try {
    con=getConnection(); ps=con.prepareStatement(sql.toString());
    int i=1;
    if(!filterActive.isEmpty()) ps.setInt(i++,"1".equals(filterActive)?1:0);
    if(!filterType.isEmpty())   ps.setString(i++,filterType);
    rs=ps.executeQuery();
    while(rs.next()){
        java.util.Map<String,String> row=new java.util.LinkedHashMap<>();
        row.put("id",        rs.getString("ALERT_ID")); row.put("issuedBy",rs.getString("ISSUED_BY_ADMIN"));
        row.put("alertType", rs.getString("ALERT_TYPE")); row.put("title",  rs.getString("TITLE"));
        row.put("description",rs.getString("DESCRIPTION")); row.put("expiresAt",rs.getString("EXPIRES_AT"));
        row.put("isActive",  rs.getString("IS_ACTIVE")); row.put("createdAt",rs.getString("CREATED_AT"));
        row.put("areaName",  rs.getString("AREA_NAME")); row.put("bkCnt",   rs.getString("BK_CNT"));
        alerts.add(row);
    }
} catch(Exception e){ logError("Admin/alertsAdmin.jsp#list",e); }
finally{ closeDB(con,ps,rs); }

java.util.Map<String,String[]> typeConfig=new java.util.LinkedHashMap<>();
typeConfig.put("water_outage",new String[]{"💧","Water Outage","#93c5fd"});
typeConfig.put("roadblock",   new String[]{"🚧","Roadblock",   "#fcd34d"});
typeConfig.put("weather",     new String[]{"⛈","Weather",     "#c4b5fd"});
typeConfig.put("strike",      new String[]{"✊","Strike",      "#fdba74"});
typeConfig.put("crime",       new String[]{"🚨","Crime",       "#f87171"});
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Alerts Admin — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.al-create { padding:24px 28px; margin-bottom:22px; }
.al-create h5 { font-weight:700; color:#fff; margin-bottom:18px; font-size:1rem; }
.al-form-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(180px,1fr)); gap:12px; }
.al-row-admin { display:flex; align-items:flex-start; gap:12px; padding:16px 18px;
    border-radius:var(--radius); background:var(--glass-bg); border:1px solid var(--glass-bdr);
    margin-bottom:12px; flex-wrap:wrap; }
.al-row-admin.inactive { opacity:0.55; }
.al-type-tag { padding:3px 10px; border-radius:20px; font-size:0.76rem; font-weight:700; display:inline-flex; align-items:center; gap:4px; }
</style>
</head>
<body>
<%@ include file="../admin/nav.jsp" %>

<div class="bv-container">

    <div class="bv-page-header glass">
        <h4>&#127758; Urban Alerts Admin</h4>
        <p>Publish and manage area alerts — water outages, roadblocks, weather, strikes, crime</p>
    </div>

    <% if (!msg.isEmpty()) { %>
    <div class="bv-alert bv-alert-<%=msgType%>"><%=sanitize(msg)%></div>
    <% } %>

    <%-- Stats --%>
    <div class="bv-grid bv-grid-4" style="margin-bottom:22px;">
        <div class="glass bv-stat"><div class="bv-stat-icon">&#127758;</div><div class="bv-stat-num"><%=totActive+totExpired%></div><div class="bv-stat-lbl">Total Alerts</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--danger);">&#128721;</div><div class="bv-stat-num" style="color:var(--danger);"><%=totActive%></div><div class="bv-stat-lbl">Active</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--text-muted);">&#128683;</div><div class="bv-stat-num" style="color:var(--text-muted);"><%=totExpired%></div><div class="bv-stat-lbl">Inactive</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--blue);">&#128205;</div><div class="bv-stat-num" style="color:var(--blue);"><%=areas.size()%></div><div class="bv-stat-lbl">Active Areas</div></div>
    </div>

    <%-- Create form --%>
    <div class="glass al-create" style="margin-bottom:22px;">
        <h5>&#10009; Publish New Alert</h5>
        <form method="post">
            <input type="hidden" name="action" value="create">
            <div class="al-form-grid">
                <div class="bv-form-group" style="margin-bottom:0;">
                    <label class="bv-label">Alert Type <span class="bv-required">*</span></label>
                    <select name="alertType" class="bv-select" required>
                        <option value="">-- Select Type --</option>
                        <% for (java.util.Map.Entry<String,String[]> e : typeConfig.entrySet()) { %>
                        <option value="<%=e.getKey()%>"><%=e.getValue()[0]%> <%=e.getValue()[1]%></option>
                        <% } %>
                    </select>
                </div>
                <div class="bv-form-group" style="margin-bottom:0;">
                    <label class="bv-label">Area <span class="bv-required">*</span></label>
                    <select name="areaId" class="bv-select" required>
                        <option value="">-- Select Area --</option>
                        <% for (java.util.Map<String,String> a : areas) { %>
                        <option value="<%=sanitize(a.get("id"))%>"><%=sanitize(a.get("name"))%></option>
                        <% } %>
                    </select>
                </div>
                <div class="bv-form-group" style="margin-bottom:0;">
                    <label class="bv-label">Expires At (optional)</label>
                    <input type="datetime-local" name="expiresAt" class="bv-input">
                </div>
            </div>
            <div class="bv-form-group" style="margin-top:14px;margin-bottom:0;">
                <label class="bv-label">Title <span class="bv-required">*</span></label>
                <input type="text" name="title" class="bv-input" placeholder="e.g. Water supply disruption in Block C" required>
            </div>
            <div class="bv-form-group" style="margin-top:12px;margin-bottom:0;">
                <label class="bv-label">Description</label>
                <textarea name="description" class="bv-textarea" rows="2" placeholder="Additional details..."></textarea>
            </div>
            <button type="submit" class="bv-btn bv-btn-danger" style="margin-top:16px;">&#128721; Publish Alert</button>
        </form>
    </div>

    <%-- Filters --%>
    <form method="get" class="glass bv-filter" style="margin-bottom:18px;">
        <select name="active" class="bv-select">
            <option value="">All Status</option>
            <option value="1" <%="1".equals(filterActive)?"selected":""%>>Active Only</option>
            <option value="0" <%="0".equals(filterActive)?"selected":""%>>Inactive Only</option>
        </select>
        <select name="alert_type" class="bv-select">
            <option value="">All Types</option>
            <% for (java.util.Map.Entry<String,String[]> e : typeConfig.entrySet()) { %>
            <option value="<%=e.getKey()%>" <%=e.getKey().equals(filterType)?"selected":""%>>
                <%=e.getValue()[0]%> <%=e.getValue()[1]%>
            </option>
            <% } %>
        </select>
        <button type="submit" class="bv-btn bv-btn-primary bv-btn-sm">&#128269; Filter</button>
        <a href="alertsAdmin.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#10006; Reset</a>
    </form>

    <%-- Alerts list --%>
    <% if (alerts.isEmpty()) { %>
    <div class="bv-empty glass"><span class="bv-empty-icon">&#127758;</span><p style="color:var(--text-muted);">No alerts found.</p></div>
    <% } else { for (java.util.Map<String,String> al : alerts) {
        String at      = al.get("alertType")!=null?al.get("alertType"):"";
        String[] cfg   = typeConfig.getOrDefault(at,new String[]{"📢","Alert","#fff"});
        boolean active = "1".equals(al.get("isActive"));
        String expires = al.get("expiresAt");
        String created = al.get("createdAt")!=null?al.get("createdAt").substring(0,16):"—";
    %>
    <div class="al-row-admin <%=active?"":"inactive"%>">
        <div style="font-size:1.8rem;flex-shrink:0;"><%=cfg[0]%></div>
        <div style="flex:1;min-width:180px;">
            <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-bottom:6px;">
                <span class="al-type-tag" style="background:<%=cfg[2]%>22;color:<%=cfg[2]%>;"><%=sanitize(cfg[1])%></span>
                <span class="bv-badge <%=active?"bv-badge-approved":"bv-badge-closed"%>"><%=active?"Active":"Inactive"%></span>
                <span class="bv-badge bv-badge-pending">&#11088; <%=sanitize(al.get("bkCnt"))%> saved</span>
            </div>
            <div style="font-weight:800;color:#fff;font-size:0.95rem;"><%=sanitize(al.get("title"))%></div>
            <% if (al.get("description")!=null&&!al.get("description").isEmpty()) { %>
            <div style="font-size:0.83rem;color:var(--text-light);margin-top:4px;"><%=sanitize(al.get("description"))%></div>
            <% } %>
            <div style="font-size:0.78rem;color:var(--text-muted);margin-top:6px;">
                &#128205; <%=sanitize(al.get("areaName"))%>
                &nbsp;·&nbsp; &#128100; <%=sanitize(al.get("issuedBy"))%>
                &nbsp;·&nbsp; &#128337; <%=sanitize(created)%>
                <% if (expires!=null&&!expires.isEmpty()) { %>
                &nbsp;·&nbsp; <span style="color:var(--warn);">&#9200; Expires: <%=sanitize(expires.substring(0,16))%></span>
                <% } %>
            </div>
        </div>
        <div style="display:flex;flex-direction:column;gap:6px;flex-shrink:0;">
            <form method="post" style="margin:0;">
                <input type="hidden" name="action"    value="toggle">
                <input type="hidden" name="alertId"   value="<%=sanitize(al.get("id"))%>">
                <input type="hidden" name="curActive" value="<%=sanitize(al.get("isActive"))%>">
                <button type="submit" class="bv-btn bv-btn-sm <%=active?"bv-btn-warn":"bv-btn-primary"%>">
                    <%=active?"&#9940; Deactivate":"&#9989; Activate"%>
                </button>
            </form>
            <form method="post" style="margin:0;" onsubmit="return confirm('Delete this alert and all its bookmarks?');">
                <input type="hidden" name="action"  value="delete">
                <input type="hidden" name="alertId" value="<%=sanitize(al.get("id"))%>">
                <button type="submit" class="bv-btn bv-btn-sm bv-btn-danger">&#128465; Delete</button>
            </form>
        </div>
    </div>
    <% } } %>

</div>
<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
