<%-- ============================================================
     Admin/systemSettings.jsp
     Admin session required
     Manage UA_AREAS + SERVICE_TYPES + site-wide toggles
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache"); response.setDateHeader("Expires", 0);
if (!"admin".equalsIgnoreCase((String) session.getAttribute("userType"))) {
    response.sendRedirect(request.getContextPath() + "/admin/login.jsp?msg=noaccess"); return;
}
String msg = ""; String msgType = "";

if ("POST".equalsIgnoreCase(request.getMethod())) {
    String action = request.getParameter("action");

    /* ── Add UA_AREA ─── */
    if ("addArea".equals(action)) {
        String areaName = request.getParameter("areaName");
        if (areaName==null||areaName.trim().isEmpty()) { msg="Area name is required."; msgType="danger"; }
        else {
            Connection c=null; PreparedStatement p=null;
            try {
                c=getConnection();
                p=c.prepareStatement("INSERT INTO UA_AREAS (AREA_NAME,IS_ACTIVE) VALUES(?,1)");
                p.setString(1,areaName.trim()); p.executeUpdate();
                msg="Area '"+sanitize(areaName.trim())+"' added."; msgType="success";
            } catch(Exception e){ msg="Add failed (name may already exist)."; msgType="danger"; }
            finally{ closeDB(c,p,null); }
        }

    /* ── Toggle UA_AREA ─── */
    } else if ("toggleArea".equals(action)) {
        String areaId  = request.getParameter("areaId");
        String curState= request.getParameter("curState");
        if (areaId!=null&&!areaId.trim().isEmpty()) {
            Connection c=null; PreparedStatement p=null;
            try {
                c=getConnection();
                p=c.prepareStatement("UPDATE UA_AREAS SET IS_ACTIVE=? WHERE AREA_ID=?");
                p.setInt(1,"1".equals(curState)?0:1); p.setInt(2,Integer.parseInt(areaId.trim()));
                p.executeUpdate(); msg="Area status updated."; msgType="success";
            } catch(Exception e){ msg="Toggle failed."; msgType="danger"; }
            finally{ closeDB(c,p,null); }
        }

    /* ── Delete UA_AREA ─── */
    } else if ("deleteArea".equals(action)) {
        String areaId = request.getParameter("areaId");
        if (areaId!=null&&!areaId.trim().isEmpty()) {
            Connection c=null; PreparedStatement p=null;
            try {
                c=getConnection();
                p=c.prepareStatement("DELETE FROM UA_AREAS WHERE AREA_ID=?");
                p.setInt(1,Integer.parseInt(areaId.trim())); p.executeUpdate();
                msg="Area deleted."; msgType="warn";
            } catch(Exception e){ msg="Delete failed (area may be in use)."; msgType="danger"; }
            finally{ closeDB(c,p,null); }
        }

    /* ── Add SERVICE_TYPE ─── */
    } else if ("addType".equals(action)) {
        String typeName = request.getParameter("typeName");
        String icon     = request.getParameter("icon");
        if (typeName==null||typeName.trim().isEmpty()) { msg="Type name is required."; msgType="danger"; }
        else {
            Connection c=null; PreparedStatement p=null;
            try {
                c=getConnection();
                p=c.prepareStatement("INSERT INTO SERVICE_TYPES (TYPE_NAME,ICON) VALUES(?,?)");
                p.setString(1,typeName.trim()); p.setString(2,icon!=null?icon.trim():"🏢");
                p.executeUpdate(); msg="Service type added."; msgType="success";
            } catch(Exception e){ msg="Add failed (name may already exist)."; msgType="danger"; }
            finally{ closeDB(c,p,null); }
        }

    /* ── Delete SERVICE_TYPE ─── */
    } else if ("deleteType".equals(action)) {
        String typeId = request.getParameter("typeId");
        if (typeId!=null&&!typeId.trim().isEmpty()) {
            Connection c=null; PreparedStatement p=null;
            try {
                c=getConnection();
                p=c.prepareStatement("DELETE FROM SERVICE_TYPES WHERE TYPE_ID=?");
                p.setInt(1,Integer.parseInt(typeId.trim())); p.executeUpdate();
                msg="Service type deleted."; msgType="warn";
            } catch(Exception e){ msg="Delete failed (type may be in use)."; msgType="danger"; }
            finally{ closeDB(c,p,null); }
        }
    }
}

/* ── Fetch UA_AREAS ─── */
java.util.List<java.util.Map<String,String>> areas = new java.util.ArrayList<>();
Connection arC=null; PreparedStatement arP=null; ResultSet arR=null;
try {
    arC=getConnection();
    arP=arC.prepareStatement("SELECT AREA_ID,AREA_NAME,IS_ACTIVE FROM UA_AREAS ORDER BY AREA_NAME");
    arR=arP.executeQuery();
    while(arR.next()){
        java.util.Map<String,String> r=new java.util.LinkedHashMap<>();
        r.put("id",arR.getString("AREA_ID")); r.put("name",arR.getString("AREA_NAME")); r.put("active",arR.getString("IS_ACTIVE"));
        areas.add(r);
    }
} catch(Exception e){}
finally{ closeDB(arC,arP,arR); }

/* ── Fetch SERVICE_TYPES ─── */
java.util.List<java.util.Map<String,String>> types = new java.util.ArrayList<>();
Connection tyC=null; PreparedStatement tyP=null; ResultSet tyR=null;
try {
    tyC=getConnection();
    tyP=tyC.prepareStatement("SELECT TYPE_ID,TYPE_NAME,ICON FROM SERVICE_TYPES ORDER BY TYPE_NAME");
    tyR=tyP.executeQuery();
    while(tyR.next()){
        java.util.Map<String,String> r=new java.util.LinkedHashMap<>();
        r.put("id",tyR.getString("TYPE_ID")); r.put("name",tyR.getString("TYPE_NAME")); r.put("icon",tyR.getString("ICON"));
        types.add(r);
    }
} catch(Exception e){}
finally{ closeDB(tyC,tyP,tyR); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>System Settings — NexShohor Admin</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.ss-section { margin-bottom:32px; }
.ss-section h5 { font-weight:800; color:#fff; font-size:1rem; margin-bottom:16px; padding-bottom:10px; border-bottom:1px solid var(--glass-bdr); }
.ss-add-row { display:flex; gap:10px; flex-wrap:wrap; align-items:flex-end; margin-bottom:18px; }
.ss-add-row .bv-input, .ss-add-row .bv-select { flex:1; min-width:160px; }
.ss-table-row {
    display:flex; align-items:center; justify-content:space-between; gap:10px;
    padding:12px 16px; border-radius:10px; background:var(--glass-bg);
    border:1px solid var(--glass-bdr); margin-bottom:8px; flex-wrap:wrap;
}
.ss-table-row.inactive { opacity:0.55; }
</style>
</head>
<body>
<%@ include file="../admin/nav.jsp" %>
<div class="bv-container">

    <div class="bv-page-header glass">
        <h4>&#9881; System Settings</h4>
        <p>Manage UA_AREAS, SERVICE_TYPES and platform configuration</p>
    </div>

    <% if (!msg.isEmpty()) { %>
    <div class="bv-alert bv-alert-<%=msgType%>"><%=sanitize(msg)%></div>
    <% } %>

    <%-- UA_AREAS --%>
    <div class="glass ss-section" style="padding:24px 28px;">
        <h5>&#128205; Urban Alert Areas (UA_AREAS) — <%=areas.size()%> total</h5>
        <form method="post" class="ss-add-row">
            <input type="hidden" name="action" value="addArea">
            <input type="text" name="areaName" class="bv-input" placeholder="New area name e.g. Mirpur" required>
            <button type="submit" class="bv-btn bv-btn-primary bv-btn-sm">&#43; Add Area</button>
        </form>
        <% for (java.util.Map<String,String> a : areas) {
            boolean act = "1".equals(a.get("active")); %>
        <div class="ss-table-row <%=act?"":"inactive"%>">
            <div>
                <span style="font-weight:700;color:#fff;"><%=sanitize(a.get("name"))%></span>
                <span class="bv-badge" style="margin-left:8px;<%=act?"background:rgba(52,211,153,0.15);color:#34d399;":"background:rgba(107,114,128,0.2);color:#9ca3af;"%>">
                    <%=act?"Active":"Inactive"%>
                </span>
            </div>
            <div style="display:flex;gap:6px;">
                <form method="post" style="margin:0;">
                    <input type="hidden" name="action"   value="toggleArea">
                    <input type="hidden" name="areaId"   value="<%=sanitize(a.get("id"))%>">
                    <input type="hidden" name="curState" value="<%=sanitize(a.get("active"))%>">
                    <button type="submit" class="bv-btn bv-btn-sm <%=act?"bv-btn-warn":"bv-btn-primary"%>">
                        <%=act?"Disable":"Enable"%>
                    </button>
                </form>
                <form method="post" style="margin:0;" onsubmit="return confirm('Delete area? This may affect existing alerts.');">
                    <input type="hidden" name="action" value="deleteArea">
                    <input type="hidden" name="areaId" value="<%=sanitize(a.get("id"))%>">
                    <button type="submit" class="bv-btn bv-btn-sm bv-btn-danger">&#128465;</button>
                </form>
            </div>
        </div>
        <% } %>
    </div>

    <%-- SERVICE_TYPES --%>
    <div class="glass ss-section" style="padding:24px 28px;">
        <h5>&#128657; Emergency Service Types (SERVICE_TYPES) — <%=types.size()%> total</h5>
        <form method="post" class="ss-add-row">
            <input type="hidden" name="action" value="addType">
            <input type="text"  name="typeName" class="bv-input" placeholder="Type name e.g. clinic" required>
            <input type="text"  name="icon"     class="bv-input" placeholder="Emoji icon e.g. 🏥" style="max-width:120px;">
            <button type="submit" class="bv-btn bv-btn-primary bv-btn-sm">&#43; Add Type</button>
        </form>
        <% for (java.util.Map<String,String> t : types) { %>
        <div class="ss-table-row">
            <div>
                <span style="font-size:1.4rem;margin-right:8px;"><%=sanitize(t.get("icon"))%></span>
                <span style="font-weight:700;color:#fff;text-transform:capitalize;"><%=sanitize(t.get("name"))%></span>
            </div>
            <form method="post" style="margin:0;" onsubmit="return confirm('Delete type? This may affect existing services.');">
                <input type="hidden" name="action" value="deleteType">
                <input type="hidden" name="typeId" value="<%=sanitize(t.get("id"))%>">
                <button type="submit" class="bv-btn bv-btn-sm bv-btn-danger">&#128465;</button>
            </form>
        </div>
        <% } %>
    </div>

</div>
<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
