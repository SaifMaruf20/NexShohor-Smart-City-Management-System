<%-- ============================================================
     Transport/report.jsp
     Session required — Bariwala or Varatia
     Submit incident + crowd level — inserts INCIDENTS + CROWD_REPORTS
     ============================================================ --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String _requiredRole = "";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String userEmail = (String) session.getAttribute("userEmail");
String userType  = (String) session.getAttribute("userType");
String msg       = "";
String msgType   = "";

/* ── Handle POST ─────────────────────────────────────────── */
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String title       = request.getParameter("title");
    String area        = request.getParameter("area");
    String description = request.getParameter("description");
    String severity    = request.getParameter("severity");
    String crowdLevel  = request.getParameter("crowdLevel");

    if (title == null || title.trim().isEmpty() ||
        area  == null || area.trim().isEmpty()) {
        msg     = "Title and Area are required.";
        msgType = "danger";
    } else {
        Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            con = getConnection();

            /* Insert into INCIDENTS — get generated key */
            ps = con.prepareStatement(
                "INSERT INTO INCIDENTS (REPORTED_BY, AREA, TITLE, DESCRIPTION, SEVERITY, CROWD_LEVEL) " +
                "VALUES (?, ?, ?, ?, ?, ?)",
                new String[]{"INCIDENT_ID"}
            );
            ps.setString(1, userEmail);
            ps.setString(2, area.trim());
            ps.setString(3, title.trim());
            ps.setString(4, description != null ? description.trim() : "");
            ps.setString(5, severity    != null ? severity.trim()    : "Low");
            ps.setString(6, crowdLevel  != null ? crowdLevel.trim()  : "Low");
            ps.executeUpdate();

            /* Get generated INCIDENT_ID */
            rs = ps.getGeneratedKeys();
            long incidentId = 0;
            if (rs.next()) incidentId = rs.getLong(1);
            rs.close(); ps.close();

            /* Insert into CROWD_REPORTS */
            if (incidentId > 0) {
                ps = con.prepareStatement(
                    "INSERT INTO CROWD_REPORTS (INCIDENT_ID, REPORTED_BY, CROWD_LEVEL, NOTE) " +
                    "VALUES (?, ?, ?, ?)"
                );
                ps.setLong(1, incidentId);
                ps.setString(2, userEmail);
                ps.setString(3, crowdLevel != null ? crowdLevel.trim() : "Low");
                ps.setString(4, description != null ? description.trim() : "");
                ps.executeUpdate();
            }

            msg     = "Incident reported successfully!";
            msgType = "success";
        } catch(Exception e) {
            logError("Transport/report.jsp", e);
            msg     = "Failed to submit incident. Please try again.";
            msgType = "danger";
        } finally { closeDB(con, ps, rs); }
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Report Incident — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head>
<body>

<% if ("Varatia".equalsIgnoreCase(userType)) { %>
    <%@ include file="../varatiya/nav.jsp" %>
<% } else { %>
    <%@ include file="../bariwala/nav.jsp" %>
<% } %>

<div class="bv-container">
    <div class="glass bv-form-card">

        <div style="margin-bottom:24px;">
            <h4 style="font-weight:800;color:#fff;margin-bottom:4px;">&#128652; Report Transport Incident</h4>
            <p style="color:var(--text-muted);font-size:0.9rem;">Help your community by reporting road incidents</p>
        </div>

        <% if (!msg.isEmpty()) { %>
        <div class="bv-alert bv-alert-<%=msgType%>"><%=msg%>
            <% if (msgType.equals("success")) { %>
            &nbsp;<a href="feed.jsp" style="color:inherit;font-weight:700;">View Feed &rarr;</a>
            <% } %>
        </div>
        <% } %>

        <form method="post">

            <div class="bv-form-group">
                <label class="bv-label" for="title">&#128221; Title <span class="bv-required">*</span></label>
                <input type="text" name="title" id="title" class="bv-input"
                    placeholder="e.g. Road blocked near Gulshan 1" required>
            </div>

            <div class="bv-form-group">
                <label class="bv-label" for="area">&#128205; Area <span class="bv-required">*</span></label>
                <input type="text" name="area" id="area" class="bv-input"
                    placeholder="e.g. Gulshan, Mirpur, Dhanmondi..." required>
            </div>

            <div class="bv-form-group">
                <label class="bv-label" for="description">&#128221; Description</label>
                <textarea name="description" id="description" class="bv-textarea"
                    placeholder="Describe what happened..."></textarea>
            </div>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
                <div class="bv-form-group">
                    <label class="bv-label" for="severity">&#9888; Severity</label>
                    <select name="severity" id="severity" class="bv-select">
                        <option value="Low">Low</option>
                        <option value="Medium">Medium</option>
                        <option value="High">High</option>
                        <option value="Critical">Critical</option>
                    </select>
                </div>
                <div class="bv-form-group">
                    <label class="bv-label" for="crowdLevel">&#128101; Crowd Level</label>
                    <select name="crowdLevel" id="crowdLevel" class="bv-select">
                        <option value="Low">Low</option>
                        <option value="Moderate">Moderate</option>
                        <option value="High">High</option>
                        <option value="Jammed">Jammed</option>
                    </select>
                    <div id="severityPreview" style="margin-top:8px;padding:8px 14px;
                         border-radius:8px;font-size:0.85rem;font-weight:600;display:none;"></div>
                </div>
            </div>

            <button type="submit" class="bv-btn bv-btn-primary bv-btn-w100">&#128652; Submit Incident</button>

        </form>

        <div style="text-align:center;margin-top:16px;">
            <a href="feed.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#8592; Back to Feed</a>
        </div>
    </div>
</div>

<%@ include file="../includes/scripts.jsp" %>
<script>
(function(){
  var cl = document.getElementById('crowdLevel');
  var sv = document.getElementById('severityPreview');
  if(!cl || !sv) return;
  function updateSeverity(){
    var v = cl.value;
    sv.style.display = 'block';
    if(v === 'High' || v === 'Jammed'){
      sv.textContent = '\u26a0 Severity: HIGH';
      sv.style.background = 'rgba(248,113,113,0.18)';
      sv.style.color = 'var(--danger)';
      sv.style.border = '1px solid var(--danger)';
    } else if(v === 'Moderate'){
      sv.textContent = '\u26a1 Severity: MEDIUM';
      sv.style.background = 'rgba(251,191,36,0.18)';
      sv.style.color = 'var(--warn)';
      sv.style.border = '1px solid var(--warn)';
    } else {
      sv.textContent = '\u2713 Severity: LOW';
      sv.style.background = 'rgba(52,211,153,0.18)';
      sv.style.color = 'var(--success)';
      sv.style.border = '1px solid var(--success)';
    }
  }
  cl.addEventListener('change', updateSeverity);
  if(cl.value) updateSeverity();
})();
</script>
</body>
</html>
