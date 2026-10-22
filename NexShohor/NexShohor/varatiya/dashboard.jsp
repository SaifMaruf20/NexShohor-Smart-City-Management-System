<%-- ============================================================
     Varatia/myDashboard.jsp
     Session required — Varatia only
     Sections: Saved Rentals · SOS History · Bookmarked Alerts · Area Alerts
     FIXES: _sessionEmail/_sessionUser → session.getAttribute()
            stream().filter() → manual loop (JSP compatibility)
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "Varatia";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String userEmail = (String) session.getAttribute("userEmail");
String userName  = (String) session.getAttribute("user");

/* ── 1. Saved rental bookmarks ───────────────────────────── */
java.util.List<java.util.Map<String,String>> savedRentals = new java.util.ArrayList<>();
Connection r1Con=null; PreparedStatement r1Ps=null; ResultSet r1Rs=null;
try {
    r1Con = getConnection();
    r1Ps  = r1Con.prepareStatement(
        "SELECT ab.BOOKMARK_ID, ab.SAVED_AT, " +
        "       hp.POST_ID, hp.ADDRESS, hp.TOTAL_ROOMS, hp.STATUS, " +
        "       bu.name AS OWNER_NAME, bu.phone AS OWNER_PHONE " +
        "FROM ALERT_BOOKMARKS ab " +
        "JOIN HOUSE_POST hp ON ab.POST_ID = hp.POST_ID " +
        "JOIN nexshohor_users bu ON hp.OWNER_EMAIL = bu.email " +
        "WHERE ab.USER_EMAIL = ? AND ab.POST_ID IS NOT NULL " +
        "ORDER BY ab.SAVED_AT DESC"
    );
    r1Ps.setString(1, userEmail);
    r1Rs = r1Ps.executeQuery();
    while (r1Rs.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("bookmarkId", r1Rs.getString("BOOKMARK_ID"));
        row.put("postId",     r1Rs.getString("POST_ID"));
        row.put("address",    r1Rs.getString("ADDRESS"));
        row.put("totalRooms", r1Rs.getString("TOTAL_ROOMS"));
        row.put("status",     r1Rs.getString("STATUS"));
        row.put("ownerName",  r1Rs.getString("OWNER_NAME"));
        row.put("ownerPhone", r1Rs.getString("OWNER_PHONE"));
        row.put("savedAt",    r1Rs.getString("SAVED_AT"));
        savedRentals.add(row);
    }
} catch(Exception e) { logError("Varatia/myDashboard.jsp#rentals", e); }
finally { closeDB(r1Con, r1Ps, r1Rs); }

/* ── 2. SOS history ──────────────────────────────────────── */
java.util.List<java.util.Map<String,String>> sosList = new java.util.ArrayList<>();
Connection s1Con=null; PreparedStatement s1Ps=null; ResultSet s1Rs=null;
try {
    s1Con = getConnection();
    s1Ps  = s1Con.prepareStatement(
        "SELECT sl.SOS_ID, sl.SERVICE_TYPE, sl.AREA, sl.DESCRIPTION, " +
        "       sl.IS_RESOLVED, sl.ADMIN_NOTE, sl.CREATED_AT, sl.RESOLVED_AT, " +
        "       es.NAME AS SERVICE_NAME, es.PHONE AS SERVICE_PHONE " +
        "FROM SOS_LOGS sl " +
        "LEFT JOIN EMERGENCY_SERVICES es ON sl.ASSIGNED_SERVICE_ID = es.SERVICE_ID " +
        "WHERE sl.USER_EMAIL = ? " +
        "ORDER BY sl.CREATED_AT DESC FETCH FIRST 20 ROWS ONLY"
    );
    s1Ps.setString(1, userEmail);
    s1Rs = s1Ps.executeQuery();
    while (s1Rs.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("sosId",       s1Rs.getString("SOS_ID"));
        row.put("serviceType", s1Rs.getString("SERVICE_TYPE"));
        row.put("area",        s1Rs.getString("AREA"));
        row.put("description", s1Rs.getString("DESCRIPTION"));
        row.put("isResolved",  s1Rs.getString("IS_RESOLVED"));
        row.put("adminNote",   s1Rs.getString("ADMIN_NOTE"));
        row.put("createdAt",   s1Rs.getString("CREATED_AT"));
        row.put("resolvedAt",  s1Rs.getString("RESOLVED_AT"));
        row.put("serviceName", s1Rs.getString("SERVICE_NAME"));
        row.put("servicePhone",s1Rs.getString("SERVICE_PHONE"));
        sosList.add(row);
    }
} catch(Exception e) { logError("Varatia/myDashboard.jsp#sos", e); }
finally { closeDB(s1Con, s1Ps, s1Rs); }

/* ── 3. Bookmarked alerts ────────────────────────────────── */
java.util.List<java.util.Map<String,String>> bkAlerts = new java.util.ArrayList<>();
Connection a1Con=null; PreparedStatement a1Ps=null; ResultSet a1Rs=null;
try {
    a1Con = getConnection();
    a1Ps  = a1Con.prepareStatement(
        "SELECT ua.ALERT_ID, ua.TITLE, ua.DESCRIPTION, ua.ALERT_TYPE, " +
        "       ua.EXPIRES_AT, ua.IS_ACTIVE, ua.CREATED_AT, " +
        "       ar.AREA_NAME, ab.SAVED_AT " +
        "FROM ALERT_BOOKMARKS ab " +
        "JOIN URBAN_ALERTS ua ON ab.ALERT_ID = ua.ALERT_ID " +
        "JOIN UA_AREAS ar ON ua.AREA_ID = ar.AREA_ID " +
        "WHERE ab.USER_EMAIL = ? AND ab.ALERT_ID IS NOT NULL " +
        "ORDER BY ab.SAVED_AT DESC"
    );
    a1Ps.setString(1, userEmail);
    a1Rs = a1Ps.executeQuery();
    while (a1Rs.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("alertId",     a1Rs.getString("ALERT_ID"));
        row.put("title",       a1Rs.getString("TITLE"));
        row.put("description", a1Rs.getString("DESCRIPTION"));
        row.put("alertType",   a1Rs.getString("ALERT_TYPE"));
        row.put("expiresAt",   a1Rs.getString("EXPIRES_AT"));
        row.put("isActive",    a1Rs.getString("IS_ACTIVE"));
        row.put("createdAt",   a1Rs.getString("CREATED_AT"));
        row.put("areaName",    a1Rs.getString("AREA_NAME"));
        row.put("savedAt",     a1Rs.getString("SAVED_AT"));
        bkAlerts.add(row);
    }
} catch(Exception e) { logError("Varatia/myDashboard.jsp#bkAlerts", e); }
finally { closeDB(a1Con, a1Ps, a1Rs); }

/* ── 4. Active area alerts strip (latest 6) ──────────────── */
java.util.List<java.util.Map<String,String>> areaAlerts = new java.util.ArrayList<>();
Connection l1Con=null; PreparedStatement l1Ps=null; ResultSet l1Rs=null;
try {
    l1Con = getConnection();
    l1Ps  = l1Con.prepareStatement(
        "SELECT ua.ALERT_ID, ua.TITLE, ua.ALERT_TYPE, ar.AREA_NAME " +
        "FROM URBAN_ALERTS ua JOIN UA_AREAS ar ON ua.AREA_ID = ar.AREA_ID " +
        "WHERE ua.IS_ACTIVE=1 " +
        "AND (ua.EXPIRES_AT IS NULL OR ua.EXPIRES_AT > CURRENT_TIMESTAMP) " +
        "ORDER BY ua.CREATED_AT DESC FETCH FIRST 6 ROWS ONLY"
    );
    l1Rs = l1Ps.executeQuery();
    while (l1Rs.next()) {
        java.util.Map<String,String> row = new java.util.LinkedHashMap<>();
        row.put("alertId",   l1Rs.getString("ALERT_ID"));
        row.put("title",     l1Rs.getString("TITLE"));
        row.put("alertType", l1Rs.getString("ALERT_TYPE"));
        row.put("areaName",  l1Rs.getString("AREA_NAME"));
        areaAlerts.add(row);
    }
} catch(Exception e) {}
finally { closeDB(l1Con, l1Ps, l1Rs); }

/* ── 5. Handle remove-rental-bookmark POST ───────────────── */
String actionMsg = ""; String actionMsgType = "";
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String action     = request.getParameter("action");
    String bookmarkId = request.getParameter("bookmarkId");
    if ("removeRental".equals(action) && bookmarkId != null && !bookmarkId.trim().isEmpty()) {
        Connection dCon=null; PreparedStatement dPs=null;
        try {
            dCon = getConnection();
            dPs  = dCon.prepareStatement(
                "DELETE FROM ALERT_BOOKMARKS WHERE BOOKMARK_ID=? AND USER_EMAIL=?"
            );
            dPs.setInt(1, Integer.parseInt(bookmarkId.trim()));
            dPs.setString(2, userEmail);
            dPs.executeUpdate();
            actionMsg     = "Rental bookmark removed.";
            actionMsgType = "warn";
            java.util.Iterator<java.util.Map<String,String>> it = savedRentals.iterator();
            while (it.hasNext()) {
                if (bookmarkId.trim().equals(it.next().get("bookmarkId"))) { it.remove(); break; }
            }
        } catch(Exception e) {}
        finally { closeDB(dCon, dPs, null); }
    }
}

/* ── Count pending/resolved manually (no streams) ────────── */
int pendingCount = 0; int resolvedCount = 0;
for (java.util.Map<String,String> s : sosList) {
    if ("1".equals(s.get("isResolved"))) resolvedCount++; else pendingCount++;
}

/* ── Type icon/color maps ────────────────────────────────── */
java.util.Map<String,String> typeIcon  = new java.util.LinkedHashMap<>();
typeIcon.put("water_outage","💧"); typeIcon.put("roadblock","🚧");
typeIcon.put("weather","⛈");      typeIcon.put("strike","✊");
typeIcon.put("crime","🚨");

java.util.Map<String,String> typeColor = new java.util.LinkedHashMap<>();
typeColor.put("water_outage","#93c5fd"); typeColor.put("roadblock","#fcd34d");
typeColor.put("weather","#c4b5fd");     typeColor.put("strike","#fdba74");
typeColor.put("crime","#f87171");

java.util.Map<String,String> sosIcon = new java.util.LinkedHashMap<>();
sosIcon.put("hospital","🏥"); sosIcon.put("police","🚔");
sosIcon.put("fire","🚒");     sosIcon.put("ambulance","🚑");
sosIcon.put("pharmacy","💊");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>My Dashboard — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.dash-hero {
    padding:26px 30px; margin-bottom:26px;
    background:linear-gradient(135deg,rgba(32,201,151,0.12),rgba(96,165,250,0.08));
    border:1px solid rgba(32,201,151,0.22); border-radius:var(--radius);
    display:flex; align-items:center; gap:20px; flex-wrap:wrap;
}
.dash-hero-avatar {
    width:64px; height:64px; border-radius:50%;
    background:linear-gradient(135deg,var(--accent-dark),var(--accent));
    display:flex; align-items:center; justify-content:center;
    font-size:1.8rem; font-weight:900; color:#000; flex-shrink:0;
}
.dash-hero-info h2 { font-size:1.5rem; font-weight:900; color:#fff; margin-bottom:4px; }
.dash-hero-info p  { color:var(--text-muted); font-size:0.9rem; }
.dash-tabs {
    display:flex; gap:6px; flex-wrap:wrap; margin-bottom:22px;
    border-bottom:1px solid var(--glass-bdr); padding-bottom:14px;
}
.dash-tab {
    padding:8px 18px; border-radius:22px; font-size:0.84rem; font-weight:600;
    background:rgba(255,255,255,0.06); border:1px solid var(--glass-bdr);
    color:var(--text-muted); cursor:pointer; transition:0.2s;
    display:inline-flex; align-items:center; gap:6px;
}
.dash-tab:hover  { background:rgba(255,255,255,0.12); color:#fff; }
.dash-tab.active { background:rgba(32,201,151,0.15); border-color:var(--accent); color:var(--accent); }
.rental-card {
    border-radius:var(--radius); background:var(--glass-bg);
    border:1px solid var(--glass-bdr); padding:18px 20px;
    display:flex; align-items:flex-start; justify-content:space-between;
    gap:16px; flex-wrap:wrap; margin-bottom:12px; transition:transform 0.2s;
}
.rental-card:hover { transform:translateY(-2px); }
.al-row {
    display:flex; align-items:center; gap:14px; padding:14px 16px;
    border-radius:10px; background:var(--glass-bg);
    border:1px solid var(--glass-bdr); margin-bottom:10px; flex-wrap:wrap;
}
.al-icon { font-size:1.6rem; flex-shrink:0; }
.al-info { flex:1; min-width:150px; }
.al-info-title { font-weight:700; color:#fff; font-size:0.9rem; }
.al-info-sub   { font-size:0.78rem; color:var(--text-muted); margin-top:2px; }
.area-strip {
    display:flex; gap:10px; flex-wrap:wrap; margin-bottom:24px; padding:16px;
    border-radius:var(--radius); background:rgba(248,113,113,0.06);
    border:1px solid rgba(248,113,113,0.18);
}
.area-chip {
    padding:6px 14px; border-radius:20px; font-size:0.8rem; font-weight:600;
    background:rgba(255,255,255,0.06); border:1px solid var(--glass-bdr);
    color:var(--text-light); display:inline-flex; align-items:center; gap:5px;
    text-decoration:none;
}
.area-chip:hover { background:rgba(255,255,255,0.12); }
.qstat-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(140px,1fr)); gap:12px; margin-bottom:26px; }
.qstat { padding:18px; text-align:center; border-radius:var(--radius); background:var(--glass-bg); border:1px solid var(--glass-bdr); }
.qstat-num { font-size:1.8rem; font-weight:800; line-height:1.1; }
.qstat-lbl { font-size:0.72rem; color:var(--text-muted); text-transform:uppercase; letter-spacing:0.5px; margin-top:4px; }
.dash-section { display:none; }
.dash-section.active { display:block; }
</style>
</head>
<body>
<%@ include file="../varatiya/nav.jsp" %>

<div class="bv-container">

    <div class="dash-hero glass">
        <div class="dash-hero-avatar"><%=sanitize(userName).substring(0,1).toUpperCase()%></div>
        <div class="dash-hero-info">
            <h2>&#128101; <%=sanitize(userName)%></h2>
            <p>&#128231; <%=sanitize(userEmail)%> &nbsp;·&nbsp; <span style="color:var(--accent);">Varatia</span></p>
            <p style="margin-top:6px;font-size:0.82rem;">
                <%=savedRentals.size()%> saved rental(s) &nbsp;·&nbsp;
                <%=sosList.size()%> SOS record(s) &nbsp;·&nbsp;
                <%=bkAlerts.size()%> bookmarked alert(s)
            </p>
        </div>
    </div>

    <% if (!actionMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-<%=actionMsgType%>"><%=sanitize(actionMsg)%></div>
    <% } %>

    <%-- Active area alerts strip --%>
    <% if (!areaAlerts.isEmpty()) { %>
    <div class="area-strip">
        <span style="color:var(--danger);font-weight:700;font-size:0.85rem;white-space:nowrap;">&#128721; Active:</span>
        <% for (java.util.Map<String,String> al : areaAlerts) {
               String at  = al.get("alertType") != null ? al.get("alertType") : "";
               String ico = typeIcon.getOrDefault(at,"📢");
               String col = typeColor.getOrDefault(at,"#fff");
        %>
        <a href="../user/alerts.jsp" class="area-chip" style="border-color:<%=col%>30;color:<%=col%>;">
            <%=ico%> <%=sanitize(al.get("title"))%> &mdash; <%=sanitize(al.get("areaName"))%>
        </a>
        <% } %>
        <a href="../user/alerts.jsp" class="area-chip" style="color:var(--text-muted);">View all ›</a>
    </div>
    <% } %>

    <%-- Quick stats --%>
    <div class="qstat-grid">
        <div class="qstat glass">
            <div class="qstat-num" style="color:var(--blue);"><%=savedRentals.size()%></div>
            <div class="qstat-lbl">Saved Rentals</div>
        </div>
        <div class="qstat glass">
            <div class="qstat-num" style="color:var(--danger);"><%=pendingCount%></div>
            <div class="qstat-lbl">SOS Pending</div>
        </div>
        <div class="qstat glass">
            <div class="qstat-num" style="color:var(--success);"><%=resolvedCount%></div>
            <div class="qstat-lbl">SOS Resolved</div>
        </div>
        <div class="qstat glass">
            <div class="qstat-num" style="color:var(--warn);"><%=bkAlerts.size()%></div>
            <div class="qstat-lbl">Saved Alerts</div>
        </div>
    </div>

    <%-- Section tabs --%>
    <div class="dash-tabs">
        <button class="dash-tab active" onclick="showSection('rentals',this)">&#127963; Saved Rentals (<%=savedRentals.size()%>)</button>
        <button class="dash-tab" onclick="showSection('sos',this)">&#128721; SOS History (<%=sosList.size()%>)</button>
        <button class="dash-tab" onclick="showSection('bkalerts',this)">&#11088; Bookmarked Alerts (<%=bkAlerts.size()%>)</button>
    </div>

    <%-- SECTION 1: Saved Rentals --%>
    <div class="dash-section active" id="sec-rentals">
        <% if (savedRentals.isEmpty()) { %>
        <div class="bv-empty glass">
            <span class="bv-empty-icon">&#127963;</span>
            <p style="color:var(--text-muted);">No saved rentals yet.</p>
            <a href="../varatiya/browse.jsp" class="bv-btn bv-btn-primary" style="margin-top:16px;">&#128269; Browse Properties</a>
        </div>
        <% } else { for (java.util.Map<String,String> rent : savedRentals) {
            String st = rent.get("status") != null ? rent.get("status") : "";
            boolean av = "Available".equalsIgnoreCase(st);
        %>
        <div class="rental-card">
            <div style="flex:1;min-width:200px;">
                <div style="font-size:1.5rem;margin-bottom:8px;">&#127968;</div>
                <div style="font-weight:800;color:#fff;font-size:0.95rem;margin-bottom:4px;"><%=sanitize(rent.get("address"))%></div>
                <div style="font-size:0.82rem;color:var(--text-muted);margin-bottom:4px;">
                    &#128101; <%=sanitize(rent.get("ownerName"))%> &nbsp;&#128222; <%=sanitize(rent.get("ownerPhone"))%>
                </div>
                <div style="font-size:0.82rem;color:var(--text-muted);">
                    &#128100; <%=sanitize(rent.get("totalRooms"))%> rooms &nbsp;·&nbsp;
                    Saved: <%=rent.get("savedAt")!=null?sanitize(rent.get("savedAt").substring(0,10)):"—"%>
                </div>
            </div>
            <div style="display:flex;flex-direction:column;align-items:flex-end;gap:8px;">
                <span class="bv-badge" style="<%=av?"background:rgba(52,211,153,0.15);color:#34d399;":"background:rgba(248,113,113,0.15);color:#f87171;"%>">
                    <%=av?"✅ Available":"🔴 Rented"%>
                </span>
                <% if (av) { %>
                <a href="../varatiya/submitRequest.jsp?postId=<%=sanitize(rent.get("postId"))%>" class="bv-btn bv-btn-primary bv-btn-sm">&#128203; Request</a>
                <% } %>
                <form method="post" style="margin:0;">
                    <input type="hidden" name="action"     value="removeRental">
                    <input type="hidden" name="bookmarkId" value="<%=sanitize(rent.get("bookmarkId"))%>">
                    <button type="submit" class="bv-btn bv-btn-danger bv-btn-sm"
                        onclick="return confirm('Remove this saved rental?');">&#128465; Remove</button>
                </form>
            </div>
        </div>
        <% } } %>
        <div style="margin-top:18px;">
            <a href="../varatiya/browse.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#128269; Browse More</a>
        </div>
    </div>

    <%-- SECTION 2: SOS History --%>
    <div class="dash-section" id="sec-sos">
        <% if (sosList.isEmpty()) { %>
        <div class="bv-empty glass">
            <span class="bv-empty-icon">&#128721;</span>
            <p style="color:var(--text-muted);">No SOS requests yet.</p>
            <a href="../user/sos.jsp" class="bv-btn bv-btn-danger" style="margin-top:16px;">&#128721; Send SOS</a>
        </div>
        <% } else { for (java.util.Map<String,String> sos : sosList) {
            boolean resolved = "1".equals(sos.get("isResolved"));
            String sType     = sos.get("serviceType") != null ? sos.get("serviceType") : "";
            String sIcon     = sosIcon.getOrDefault(sType,"🆘");
            String createdAt = sos.get("createdAt") != null ? sos.get("createdAt").substring(0,16) : "—";
            String resolvedAt= sos.get("resolvedAt");
        %>
        <div class="al-row">
            <div class="al-icon"><%=sIcon%></div>
            <div class="al-info">
                <div class="al-info-title">
                    <%=sanitize(sType.substring(0,1).toUpperCase()+sType.substring(1))%> — <%=sanitize(sos.get("area"))%>
                </div>
                <% if (sos.get("description")!=null&&!sos.get("description").isEmpty()) { %>
                <div class="al-info-sub">&#128221; <%=sanitize(sos.get("description"))%></div>
                <% } %>
                <% if (sos.get("serviceName")!=null) { %>
                <div class="al-info-sub" style="color:var(--accent);">
                    &#128657; <%=sanitize(sos.get("serviceName"))%>
                    <% if (sos.get("servicePhone")!=null) { %> &#128222; <%=sanitize(sos.get("servicePhone"))%><% } %>
                </div>
                <% } %>
                <% if (sos.get("adminNote")!=null&&!sos.get("adminNote").isEmpty()) { %>
                <div class="al-info-sub" style="color:var(--warn);">&#128172; <%=sanitize(sos.get("adminNote"))%></div>
                <% } %>
                <div class="al-info-sub">&#128337; <%=createdAt%>
                    <% if (resolvedAt!=null&&!resolvedAt.isEmpty()) { %> · Resolved: <%=sanitize(resolvedAt.substring(0,16))%><% } %>
                </div>
            </div>
            <span class="bv-badge" style="<%=resolved?"background:rgba(52,211,153,0.15);color:#34d399;":"background:rgba(251,191,36,0.15);color:#fbbf24;"%>">
                <%=resolved?"✅ Resolved":"⏳ Pending"%>
            </span>
        </div>
        <% } } %>
        <div style="margin-top:18px;display:flex;gap:10px;flex-wrap:wrap;">
            <a href="../user/sos.jsp"       class="bv-btn bv-btn-danger bv-btn-sm">&#128721; New SOS</a>
            <a href="../user/sosStatus.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#128203; Full Status</a>
        </div>
    </div>

    <%-- SECTION 3: Bookmarked Alerts --%>
    <div class="dash-section" id="sec-bkalerts">
        <% if (bkAlerts.isEmpty()) { %>
        <div class="bv-empty glass">
            <span class="bv-empty-icon">&#11088;</span>
            <p style="color:var(--text-muted);">No bookmarked alerts yet.</p>
            <a href="../user/alerts.jsp" class="bv-btn bv-btn-outline" style="margin-top:16px;">&#127758; View Alerts</a>
        </div>
        <% } else { for (java.util.Map<String,String> al : bkAlerts) {
            String at   = al.get("alertType") != null ? al.get("alertType") : "";
            String ico  = typeIcon.getOrDefault(at,"📢");
            String col  = typeColor.getOrDefault(at,"#fff");
            boolean act = "1".equals(al.get("isActive"));
            String exp  = al.get("expiresAt");
        %>
        <div class="al-row" style="border-color:<%=col%>25;">
            <div class="al-icon"><%=ico%></div>
            <div class="al-info">
                <div class="al-info-title" style="color:<%=col%>;"><%=sanitize(al.get("title"))%></div>
                <div class="al-info-sub">&#128205; <%=sanitize(al.get("areaName"))%></div>
                <% if (al.get("description")!=null&&!al.get("description").isEmpty()) { %>
                <div class="al-info-sub"><%=sanitize(al.get("description"))%></div>
                <% } %>
                <div class="al-info-sub">
                    Saved: <%=al.get("savedAt")!=null?sanitize(al.get("savedAt").substring(0,10)):"—"%>
                    <% if (exp!=null&&!exp.isEmpty()) { %> · &#9200; Expires: <%=sanitize(exp.substring(0,10))%><% } %>
                </div>
            </div>
            <div style="display:flex;flex-direction:column;align-items:flex-end;gap:6px;">
                <span class="bv-badge" style="<%=act?"background:rgba(52,211,153,0.15);color:#34d399;":"background:rgba(107,114,128,0.2);color:#9ca3af;"%>">
                    <%=act?"Active":"Expired"%>
                </span>
                <a href="../user/alerts.jsp" class="bv-btn bv-btn-sm bv-btn-outline">&#128279; View</a>
            </div>
        </div>
        <% } } %>
        <div style="margin-top:18px;">
            <a href="../user/alerts.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#127758; All Alerts</a>
        </div>
    </div>

    <%-- Quick nav --%>
    <div class="glass" style="margin-top:30px;padding:16px 20px;display:flex;gap:10px;flex-wrap:wrap;align-items:center;">
        <span style="color:var(--text-muted);font-size:0.85rem;">Quick Links:</span>
        <a href="../varatiya/browse.jsp" class="bv-btn bv-btn-sm bv-btn-outline">&#127963; Browse</a>
        <a href="../varatiya/myRequests.jsp"       class="bv-btn bv-btn-sm bv-btn-outline">&#128203; Requests</a>
        <a href="../user/sos.jsp"            class="bv-btn bv-btn-sm bv-btn-danger">&#128721; SOS</a>
        <a href="../user/alerts.jsp"    class="bv-btn bv-btn-sm bv-btn-outline">&#127758; Alerts</a>
        <a href="../user/transport.jsp"           class="bv-btn bv-btn-sm bv-btn-outline">&#128652; Transport</a>
    </div>

</div>

<%@ include file="../includes/scripts.jsp" %>
<script>
function showSection(id, btn) {
    document.querySelectorAll('.dash-section').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.dash-tab').forEach(t => t.classList.remove('active'));
    document.getElementById('sec-' + id).classList.add('active');
    btn.classList.add('active');
}
window.addEventListener('DOMContentLoaded', function(){
    const h = location.hash.replace('#','');
    if (h) {
        const btn = document.querySelector('[onclick*="' + h + '"]');
        if (btn) btn.click();
    }
});
</script>
</body>
</html>
