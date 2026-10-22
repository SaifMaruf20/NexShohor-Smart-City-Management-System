<%-- ============================================================
     Emergency/sos.jsp
     Session required (Bariwala or Varatia)
     SOS submission — inserts SOS_LOGS + fires admin notification
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "";  /* any logged-in user */
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String userEmail = (String) session.getAttribute("userEmail");
String userName  = (String) session.getAttribute("user");
String userType  = (String) session.getAttribute("userType");

String msg     = "";
String msgType = "";

/* ── Fetch areas for dropdown ─────────────────────────────── */
java.util.List<String> areaList = new java.util.ArrayList<>();
Connection aCon = null; PreparedStatement aPs = null; ResultSet aRs = null;
try {
    aCon = getConnection();
    aPs  = aCon.prepareStatement("SELECT AREA_NAME FROM UA_AREAS WHERE IS_ACTIVE=1 ORDER BY AREA_NAME");
    aRs  = aPs.executeQuery();
    while (aRs.next()) areaList.add(aRs.getString("AREA_NAME"));
} catch(Exception e) {}
finally { closeDB(aCon, aPs, aRs); }

/* ── Handle POST ─────────────────────────────────────────── */
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String serviceType = request.getParameter("serviceType");
    String area        = request.getParameter("area");
    String desc        = request.getParameter("description");

    if (serviceType == null || serviceType.trim().isEmpty() ||
        area        == null || area.trim().isEmpty()) {
        msg     = "Service type and area are required.";
        msgType = "danger";
    } else {
        Connection con = null; PreparedStatement ps = null;
        try {
            con = getConnection();
            /* Insert SOS log */
            ps = con.prepareStatement(
                "INSERT INTO SOS_LOGS (USER_EMAIL, SERVICE_TYPE, AREA, DESCRIPTION) " +
                "VALUES (?, ?, ?, ?)"
            );
            ps.setString(1, userEmail);
            ps.setString(2, serviceType.trim());
            ps.setString(3, area.trim());
            ps.setString(4, desc != null ? desc.trim() : "");
            ps.executeUpdate();
            ps.close();

            /* Fire notification to all admins (stored as system notification) */
            ps = con.prepareStatement(
                "INSERT INTO NOTIFICATIONS (USER_EMAIL, NOTIF_TYPE, TITLE, BODY, LINK_URL) " +
                "SELECT email, 'SOS_ALERT', '🚨 SOS Received', ?, '../user/sosStatus.jsp' " +
                "FROM nexshohor_users WHERE userType='admin' OR email IN " +
                "(SELECT DISTINCT USER_EMAIL FROM NOTIFICATIONS WHERE NOTIF_TYPE='ADMIN')"
            );
            /* Simple approach: notify a known admin email if exists */
            ps.setString(1, userName + " needs " + serviceType + " in " + area);
            try { ps.executeUpdate(); } catch(Exception ignored){}

            msg     = "✅ SOS sent successfully! Help is on the way. Track your SOS below.";
            msgType = "success";
        } catch(Exception e) {
            logError("Emergency/sos.jsp", e);
            msg     = "Failed to send SOS. Please call emergency services directly.";
            msgType = "danger";
        } finally { closeDB(con, ps, null); }
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SOS — NexShohor Emergency</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.sos-hero {
    text-align:center; padding:36px 24px 28px;
    background:linear-gradient(135deg,rgba(220,38,38,0.20),rgba(248,113,113,0.10));
    border:1px solid rgba(220,38,38,0.35); border-radius:var(--radius);
    margin-bottom:28px;
}
.sos-hero h2 { font-size:1.8rem; font-weight:900; color:#fff; margin-bottom:6px; }
.sos-hero p  { color:var(--text-muted); font-size:0.9rem; }
.sos-pulse {
    display:inline-block; font-size:3.5rem;
    animation: pulse 1.2s ease-in-out infinite;
}
@keyframes pulse {
    0%,100% { transform:scale(1);   opacity:1; }
    50%      { transform:scale(1.15);opacity:0.7; }
}
.sos-type-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(140px,1fr)); gap:12px; margin-bottom:20px; }
.sos-type-btn {
    padding:18px 10px; border-radius:var(--radius); text-align:center;
    background:var(--glass-bg); border:2px solid var(--glass-bdr);
    cursor:pointer; transition:0.2s; font-size:0.9rem; font-weight:600;
    color:var(--text-light);
}
.sos-type-btn:hover, .sos-type-btn.selected {
    border-color:var(--danger); background:rgba(248,113,113,0.15); color:#fff;
}
.sos-type-btn .icon { font-size:2rem; display:block; margin-bottom:6px; }
.sos-submit-btn {
    width:100%; padding:16px; font-size:1.1rem; font-weight:800;
    background:linear-gradient(135deg,#dc2626,var(--danger));
    border:none; border-radius:var(--radius); color:#fff; cursor:pointer;
    box-shadow:0 4px 20px rgba(248,113,113,0.4);
    transition:transform 0.2s, box-shadow 0.2s;
}
.sos-submit-btn:hover { transform:scale(1.02); box-shadow:0 6px 28px rgba(248,113,113,0.6); }
</style>
</head>
<body>

<%-- Nav based on user type --%>
<% if ("Varatia".equalsIgnoreCase(userType)) { %>
    <%@ include file="../varatiya/nav.jsp" %>
<% } else { %>
    <%@ include file="../bariwala/nav.jsp" %>
<% } %>

<div class="bv-container" style="max-width:680px;">

    <div class="sos-hero glass">
        <span class="sos-pulse">🚨</span>
        <h2>Send Emergency SOS</h2>
        <p>Your request will be logged and admin will be notified immediately</p>
    </div>

    <% if (!msg.isEmpty()) { %>
    <div class="bv-alert bv-alert-<%=msgType%>"><%=msg%></div>
    <% if (msgType.equals("success")) { %>
    <div style="text-align:center;margin-bottom:20px;">
        <a href="../user/sosStatus.jsp" class="bv-btn bv-btn-danger">&#128203; Track My SOS</a>
        <a href="../user/emergency.jsp" class="bv-btn bv-btn-outline" style="margin-left:10px;">&#128657; View Directory</a>
    </div>
    <% } %>
    <% } %>

    <div class="glass" style="padding:28px;">
        <form method="POST" action="sos.jsp"
              onsubmit="return confirm('This will alert emergency services. Submit SOS?');">

            <div class="bv-form-group">
                <label class="bv-label">&#128657; Select Emergency Type <span class="bv-required">*</span></label>
                <div class="sos-type-grid" id="typeGrid">
                    <div class="sos-type-btn" data-value="hospital"  onclick="selectType(this)"><span class="icon">🏥</span>Hospital</div>
                    <div class="sos-type-btn" data-value="police"    onclick="selectType(this)"><span class="icon">🚔</span>Police</div>
                    <div class="sos-type-btn" data-value="fire"      onclick="selectType(this)"><span class="icon">🚒</span>Fire Brigade</div>
                    <div class="sos-type-btn" data-value="ambulance" onclick="selectType(this)"><span class="icon">🚑</span>Ambulance</div>
                    <div class="sos-type-btn" data-value="pharmacy"  onclick="selectType(this)"><span class="icon">💊</span>Pharmacy</div>
                </div>
                <input type="hidden" name="serviceType" id="serviceType" required>
                <div class="bv-field-error" id="typeError" style="display:none;">Please select an emergency type.</div>
            </div>

            <div class="bv-form-group">
                <label class="bv-label" for="area">&#128205; Your Area <span class="bv-required">*</span></label>
                <select name="area" id="area" class="bv-select" required>
                    <option value="">-- Select your area --</option>
                    <% for (String a : areaList) { %>
                    <option value="<%=sanitize(a)%>"><%=sanitize(a)%></option>
                    <% } %>
                </select>
            </div>

            <div class="bv-form-group">
                <label class="bv-label" for="description">&#128221; Describe your situation (optional)</label>
                <textarea name="description" id="description" class="bv-textarea"
                    placeholder="Briefly describe what happened or what help you need..."></textarea>
            </div>

            <button type="submit" class="sos-submit-btn" id="sosBtn">
                &#128721; SEND SOS NOW
            </button>
        </form>
    </div>

    <div class="glass" style="padding:16px 20px;margin-top:16px;text-align:center;">
        <span style="color:var(--text-muted);font-size:0.88rem;">
            Already sent an SOS?
        </span>
        <a href="../user/sosStatus.jsp" class="bv-btn bv-btn-sm bv-btn-outline" style="margin-left:10px;">
            &#128203; Track Status
        </a>
        <a href="../user/emergency.jsp" class="bv-btn bv-btn-sm bv-btn-outline" style="margin-left:6px;">
            &#128657; Browse Directory
        </a>
    </div>

</div>

<%@ include file="../includes/scripts.jsp" %>
<script>
function selectType(el) {
    document.querySelectorAll('.sos-type-btn').forEach(b => b.classList.remove('selected'));
    el.classList.add('selected');
    document.getElementById('serviceType').value = el.dataset.value;
    document.getElementById('typeError').style.display = 'none';
}

document.getElementById('sosForm').addEventListener('submit', function(e) {
    if (!document.getElementById('serviceType').value) {
        e.preventDefault();
        document.getElementById('typeError').style.display = 'block';
        return;
    }
    document.getElementById('sosBtn').textContent = '⏳ Sending...';
    document.getElementById('sosBtn').disabled = true;
});
</script>
</body>
</html>
