<%-- ============================================================
     Admin/emergencyAdmin.jsp
     Admin session required
     Manage EMERGENCY_SERVICES — add, toggle active, view by type
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
    String action = request.getParameter("action");

    if ("add".equals(action)) {
        String typeId  = request.getParameter("typeId");
        String name    = request.getParameter("name");
        String area    = request.getParameter("area");
        String address = request.getParameter("address");
        String phone   = request.getParameter("phone");

        if (name==null||name.trim().isEmpty()||phone==null||phone.trim().isEmpty()||
            area==null||area.trim().isEmpty()||typeId==null||typeId.trim().isEmpty()) {
            msg = "Name, type, area and phone are required."; msgType="danger";
        } else {
            Connection aC=null; PreparedStatement aP=null;
            try {
                aC = getConnection();
                aP = aC.prepareStatement(
                    "INSERT INTO EMERGENCY_SERVICES (TYPE_ID,NAME,AREA,ADDRESS,PHONE,IS_ACTIVE) VALUES(?,?,?,?,?,1)"
                );
                aP.setInt(1, Integer.parseInt(typeId.trim()));
                aP.setString(2, name.trim()); aP.setString(3, area.trim());
                aP.setString(4, address!=null?address.trim():"");
                aP.setString(5, phone.trim());
                aP.executeUpdate();
                msg="Service added successfully."; msgType="success";
            } catch(Exception e){ logError("Admin/emergencyAdmin.jsp#add",e); msg="Add failed."; msgType="danger"; }
            finally{ closeDB(aC,aP,null); }
        }

    } else if ("toggle".equals(action)) {
        String svcId    = request.getParameter("serviceId");
        String curState = request.getParameter("curState");
        if (svcId!=null && !svcId.trim().isEmpty()) {
            Connection tC=null; PreparedStatement tP=null;
            try {
                tC = getConnection();
                tP = tC.prepareStatement("UPDATE EMERGENCY_SERVICES SET IS_ACTIVE=? WHERE SERVICE_ID=?");
                tP.setInt(1, "1".equals(curState)?0:1);
                tP.setInt(2, Integer.parseInt(svcId.trim()));
                tP.executeUpdate();
                msg="Service status updated."; msgType="success";
            } catch(Exception e){ msg="Toggle failed."; msgType="danger"; }
            finally{ closeDB(tC,tP,null); }
        }

    } else if ("delete".equals(action)) {
        String svcId = request.getParameter("serviceId");
        if (svcId!=null && !svcId.trim().isEmpty()) {
            Connection dC=null; PreparedStatement dP=null;
            try {
                dC = getConnection();
                dP = dC.prepareStatement("DELETE FROM EMERGENCY_SERVICES WHERE SERVICE_ID=?");
                dP.setInt(1, Integer.parseInt(svcId.trim()));
                dP.executeUpdate();
                msg="Service deleted."; msgType="warn";
            } catch(Exception e){ msg="Delete failed."; msgType="danger"; }
            finally{ closeDB(dC,dP,null); }
        }
    }
}

/* ── Fetch service types ──────────────────────────────────────── */
java.util.List<java.util.Map<String,String>> svcTypes = new java.util.ArrayList<>();
Connection stC=null; PreparedStatement stP=null; ResultSet stR=null;
try {
    stC=getConnection();
    stP=stC.prepareStatement("SELECT TYPE_ID,TYPE_NAME,ICON FROM SERVICE_TYPES ORDER BY TYPE_NAME");
    stR=stP.executeQuery();
    while(stR.next()){
        java.util.Map<String,String> r=new java.util.LinkedHashMap<>();
        r.put("id",stR.getString("TYPE_ID")); r.put("name",stR.getString("TYPE_NAME")); r.put("icon",stR.getString("ICON"));
        svcTypes.add(r);
    }
} catch(Exception e){}
finally{ closeDB(stC,stP,stR); }

/* ── Filter ───────────────────────────────────────────────────── */
String filterType = request.getParameter("typeId") != null ? request.getParameter("typeId").trim() : "";
String filterArea = request.getParameter("area")   != null ? request.getParameter("area").trim()   : "";

/* ── Fetch services ───────────────────────────────────────────── */
java.util.List<java.util.Map<String,String>> services = new java.util.ArrayList<>();
StringBuilder sql = new StringBuilder(
    "SELECT es.SERVICE_ID, es.NAME, es.AREA, es.ADDRESS, es.PHONE, es.IS_ACTIVE, " +
    "       st.TYPE_NAME, st.ICON " +
    "FROM EMERGENCY_SERVICES es JOIN SERVICE_TYPES st ON es.TYPE_ID=st.TYPE_ID WHERE 1=1 "
);
if (!filterType.isEmpty()) sql.append("AND es.TYPE_ID=? ");
if (!filterArea.isEmpty()) sql.append("AND UPPER(es.AREA) LIKE UPPER(?) ");
sql.append("ORDER BY es.IS_ACTIVE DESC, st.TYPE_NAME, es.NAME");

Connection con=null; PreparedStatement ps=null; ResultSet rs=null;
try {
    con=getConnection(); ps=con.prepareStatement(sql.toString());
    int i=1;
    if (!filterType.isEmpty()) ps.setInt(i++, Integer.parseInt(filterType));
    if (!filterArea.isEmpty()) ps.setString(i++, "%"+filterArea+"%");
    rs=ps.executeQuery();
    while(rs.next()){
        java.util.Map<String,String> row=new java.util.LinkedHashMap<>();
        row.put("id",       rs.getString("SERVICE_ID")); row.put("name",  rs.getString("NAME"));
        row.put("area",     rs.getString("AREA"));       row.put("address",rs.getString("ADDRESS"));
        row.put("phone",    rs.getString("PHONE"));      row.put("isActive",rs.getString("IS_ACTIVE"));
        row.put("typeName", rs.getString("TYPE_NAME"));  row.put("icon",  rs.getString("ICON"));
        services.add(row);
    }
} catch(Exception e){ logError("Admin/emergencyAdmin.jsp#list",e); }
finally{ closeDB(con,ps,rs); }

long activeCount   = services.stream().filter(s->"1".equals(s.get("isActive"))).count();
long inactiveCount = services.size() - activeCount;
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Emergency Admin — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.ea-add-panel { padding:24px 28px; margin-bottom:24px; }
.ea-add-panel h5 { font-weight:700; color:#fff; margin-bottom:18px; }
.ea-form-row { display:grid; grid-template-columns:repeat(auto-fill,minmax(200px,1fr)); gap:14px; }
</style>
</head>
<body>
<%@ include file="../admin/nav.jsp" %>

<div class="bv-container">

    <div class="bv-page-header glass">
        <h4>&#128657; Emergency Services Admin</h4>
        <p>Add, activate/deactivate, and manage all emergency service listings</p>
    </div>

    <% if (!msg.isEmpty()) { %>
    <div class="bv-alert bv-alert-<%=msgType%>"><%=sanitize(msg)%></div>
    <% } %>

    <%-- Stats --%>
    <div class="bv-grid bv-grid-4" style="margin-bottom:22px;">
        <div class="glass bv-stat"><div class="bv-stat-icon">&#128657;</div><div class="bv-stat-num"><%=services.size()%></div><div class="bv-stat-lbl">Total Services</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--success);">&#9989;</div><div class="bv-stat-num" style="color:var(--success);"><%=activeCount%></div><div class="bv-stat-lbl">Active</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--danger);">&#9940;</div><div class="bv-stat-num" style="color:var(--danger);"><%=inactiveCount%></div><div class="bv-stat-lbl">Inactive</div></div>
        <div class="glass bv-stat"><div class="bv-stat-icon" style="color:var(--blue);">&#127973;</div><div class="bv-stat-num" style="color:var(--blue);"><%=svcTypes.size()%></div><div class="bv-stat-lbl">Service Types</div></div>
    </div>

    <%-- Add form --%>
    <div class="glass ea-add-panel" style="margin-bottom:22px;">
        <h5>&#10009; Add New Emergency Service</h5>
        <form method="post">
            <input type="hidden" name="action" value="add">
            <div class="ea-form-row">
                <div class="bv-form-group" style="margin-bottom:0;">
                    <label class="bv-label">Type <span class="bv-required">*</span></label>
                    <select name="typeId" class="bv-select" required>
                        <option value="">-- Select Type --</option>
                        <% for (java.util.Map<String,String> t : svcTypes) { %>
                        <option value="<%=sanitize(t.get("id"))%>">
                            <%=sanitize(t.get("icon"))%> <%=sanitize(t.get("name"))%>
                        </option>
                        <% } %>
                    </select>
                </div>
                <div class="bv-form-group" style="margin-bottom:0;">
                    <label class="bv-label">Service Name <span class="bv-required">*</span></label>
                    <input type="text" name="name" class="bv-input" placeholder="e.g. Dhaka Medical College" required>
                </div>
                <div class="bv-form-group" style="margin-bottom:0;">
                    <label class="bv-label">Area <span class="bv-required">*</span></label>
                    <input type="text" name="area" class="bv-input" placeholder="e.g. Mirpur" required>
                </div>
                <div class="bv-form-group" style="margin-bottom:0;">
                    <label class="bv-label">Phone <span class="bv-required">*</span></label>
                    <input type="text" name="phone" class="bv-input" placeholder="01XXXXXXXXX" required>
                </div>
            </div>
            <div class="bv-form-group" style="margin-top:14px;margin-bottom:0;">
                <label class="bv-label">Address (optional)</label>
                <input type="text" name="address" class="bv-input" placeholder="Full address...">
            </div>
            <button type="submit" class="bv-btn bv-btn-primary" style="margin-top:16px;">&#10009; Add Service</button>
        </form>
    </div>

    <%-- Filter --%>
    <form method="get" class="glass bv-filter" style="margin-bottom:18px;">
        <select name="typeId" class="bv-select">
            <option value="">All Types</option>
            <% for (java.util.Map<String,String> t : svcTypes) { %>
            <option value="<%=sanitize(t.get("id"))%>" <%=t.get("id").equals(filterType)?"selected":""%>>
                <%=sanitize(t.get("icon"))%> <%=sanitize(t.get("name"))%>
            </option>
            <% } %>
        </select>
        <input type="text" name="area" class="bv-input" value="<%=sanitize(filterArea)%>" placeholder="Filter by area...">
        <button type="submit" class="bv-btn bv-btn-primary bv-btn-sm">&#128269; Filter</button>
        <a href="emergencyAdmin.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#10006; Reset</a>
    </form>

    <%-- Table --%>
    <div class="glass" style="padding:0;overflow:hidden;">
        <div class="bv-table-wrap">
            <table class="bv-table">
                <thead>
                    <tr>
                        <th>Type</th>
                        <th>Name</th>
                        <th>Area / Address</th>
                        <th>Phone</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <% if (services.isEmpty()) { %>
                <tr><td colspan="6" style="text-align:center;padding:40px;color:var(--text-muted);">No services found.</td></tr>
                <% } else { for (java.util.Map<String,String> svc : services) {
                    boolean active = "1".equals(svc.get("isActive"));
                %>
                <tr style="<%=active?"":"opacity:0.55;"%>">
                    <td>
                        <span style="font-size:1.2rem;"><%=sanitize(svc.get("icon"))%></span>
                        <span style="font-size:0.8rem;color:var(--text-muted);"><%=sanitize(svc.get("typeName"))%></span>
                    </td>
                    <td style="font-weight:700;color:#fff;"><%=sanitize(svc.get("name"))%></td>
                    <td>
                        <div>&#128205; <%=sanitize(svc.get("area"))%></div>
                        <% if (svc.get("address")!=null && !svc.get("address").isEmpty()) { %>
                        <div style="font-size:0.78rem;color:var(--text-muted);"><%=sanitize(svc.get("address"))%></div>
                        <% } %>
                    </td>
                    <td><a href="tel:<%=sanitize(svc.get("phone"))%>" style="color:var(--accent);text-decoration:none;">&#128222; <%=sanitize(svc.get("phone"))%></a></td>
                    <td>
                        <span class="bv-badge <%=active?"bv-badge-active":"bv-badge-banned"%>">
                            <%=active?"Active":"Inactive"%>
                        </span>
                    </td>
                    <td style="display:flex;gap:6px;flex-wrap:wrap;align-items:center;">
                        <form method="post" style="margin:0;">
                            <input type="hidden" name="action"    value="toggle">
                            <input type="hidden" name="serviceId" value="<%=sanitize(svc.get("id"))%>">
                            <input type="hidden" name="curState"  value="<%=sanitize(svc.get("isActive"))%>">
                            <button type="submit" class="bv-btn bv-btn-sm <%=active?"bv-btn-warn":"bv-btn-primary"%>">
                                <%=active?"&#9940; Disable":"&#9989; Enable"%>
                            </button>
                        </form>
                        <form method="post" style="margin:0;"
                            onsubmit="return confirm('Delete this service?');">
                            <input type="hidden" name="action"    value="delete">
                            <input type="hidden" name="serviceId" value="<%=sanitize(svc.get("id"))%>">
                            <button type="submit" class="bv-btn bv-btn-sm bv-btn-danger">&#128465;</button>
                        </form>
                    </td>
                </tr>
                <% } } %>
                </tbody>
            </table>
        </div>
    </div>

</div>
<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
