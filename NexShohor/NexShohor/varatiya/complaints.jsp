<%@ page import="java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
String _requiredRole = "Varatia";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String userEmail=_sessionEmail, userName=_sessionUser;
String actionMsg="",actionType="";
Connection con=null; PreparedStatement ps=null; ResultSet rs=null;

/* ── SUBMIT COMPLAINT ──────────────────────────────────────── */
if("POST".equalsIgnoreCase(request.getMethod())){
    String subject=request.getParameter("subject"), desc=request.getParameter("description");
    if(subject==null||subject.trim().isEmpty()||desc==null||desc.trim().isEmpty()){
        actionMsg="Subject and description are required."; actionType="danger";
    } else if(subject.trim().length()<5){
        actionMsg="Subject must be at least 5 characters."; actionType="danger";
    } else if(desc.trim().length()<10){
        actionMsg="Description must be at least 10 characters."; actionType="danger";
    } else {
        try{
            con=getConnection(); con.setAutoCommit(false);
            ps=con.prepareStatement("INSERT INTO COMPLAINTS(USER_EMAIL,USER_TYPE,SUBJECT,DESCRIPTION) VALUES(?,?,?,?)");
            ps.setString(1,userEmail); ps.setString(2,"Varatia");
            ps.setString(3,subject.trim().substring(0,Math.min(subject.trim().length(),200)));
            ps.setString(4,desc.trim());
            ps.executeUpdate(); con.commit();
            actionMsg="Complaint submitted. Admin will review it soon."; actionType="success";
        }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
            logError("myComplaints.jsp(V)",e); actionMsg="Submission failed. Try again."; actionType="danger";
        }finally{closeDB(con,ps,null);}
    }
}

/* ── LOAD MY COMPLAINTS ────────────────────────────────────── */
List<Map<String,Object>> myComplaints=new ArrayList<>();
try{
    con=getConnection();
    ps=con.prepareStatement("SELECT COMPLAINT_ID,SUBJECT,STATUS,ADMIN_NOTE,CREATED_AT,UPDATED_AT FROM COMPLAINTS WHERE USER_EMAIL=? ORDER BY CREATED_AT DESC");
    ps.setString(1,userEmail); rs=ps.executeQuery();
    SimpleDateFormat sdf=new SimpleDateFormat("dd MMM yyyy HH:mm");
    while(rs.next()){Map<String,Object> m=new HashMap<>();
        m.put("id",rs.getInt("COMPLAINT_ID")); m.put("subject",rs.getString("SUBJECT"));
        m.put("status",rs.getString("STATUS")); m.put("adminNote",rs.getString("ADMIN_NOTE"));
        java.sql.Timestamp ts=rs.getTimestamp("CREATED_AT"); m.put("date",ts!=null?sdf.format(ts):"—");
        java.sql.Timestamp ut=rs.getTimestamp("UPDATED_AT"); m.put("updated",ut!=null?sdf.format(ut):"—");
        myComplaints.add(m);}
}catch(Exception e){logError("myComplaints.jsp(V)",e);}finally{closeDB(con,ps,rs);}
%>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Complaints – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head><body>
<%@ include file="../varatiya/nav.jsp" %>
<div class="bv-container">
    <div class="glass bv-page-header">
        <h4>&#128226; My Complaints</h4>
        <p>Submit issues or concerns to the admin</p>
    </div>

    <%if(!actionMsg.isEmpty()){%><div class="bv-alert bv-alert-<%=actionType%>"><%="success".equals(actionType)?"&#10003;":"&#9888;"%> <%=sanitize(actionMsg)%></div><%}%>

    <div class="glass" style="padding:24px;margin-bottom:28px;">
        <div class="bv-section-title" style="margin-bottom:16px;">&#128221; Submit New Complaint</div>
        <form method="post" onsubmit="return bvValidate(this);" novalidate>
            <div class="bv-form-group">
                <label class="bv-label">Subject <span class="bv-required">*</span></label>
                <input type="text" name="subject" class="bv-input" placeholder="Brief summary of your issue..." data-required maxlength="200">
                <div class="bv-field-error">Subject is required (min 5 chars).</div>
            </div>
            <div class="bv-form-group">
                <label class="bv-label">Description <span class="bv-required">*</span></label>
                <textarea name="description" class="bv-textarea" placeholder="Describe your complaint in detail..." rows="5" data-required></textarea>
                <div class="bv-field-error">Description is required (min 10 chars).</div>
            </div>
            <button type="submit" class="bv-btn bv-btn-primary">&#128228; Submit Complaint</button>
        </form>
    </div>

    <div class="bv-section-title" style="margin-bottom:14px;">&#128203; My Submitted Complaints (<%= myComplaints.size() %>)</div>
    <%if(myComplaints.isEmpty()){%>
    <div class="glass bv-empty"><span class="bv-empty-icon">&#128226;</span><h5>No complaints yet</h5></div>
    <%}else{%>
    <div style="display:flex;flex-direction:column;gap:12px;">
    <%for(Map<String,Object> c:myComplaints){
        String st=(String)c.get("status");
        String badgeCls="bv-badge-open";
        if("In Review".equals(st))badgeCls="bv-badge-inreview";
        else if("Resolved".equals(st))badgeCls="bv-badge-resolved";
        else if("Closed".equals(st))badgeCls="bv-badge-closed";
    %>
    <div class="glass" style="padding:18px;">
        <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px;">
            <div>
                <span style="font-weight:700;color:#fff;">&#128226; #<%=c.get("id")%> – <%=sanitize((String)c.get("subject"))%></span>
                <span class="bv-badge <%=badgeCls%>" style="margin-left:8px;"><%=st%></span>
            </div>
            <span style="font-size:0.78rem;color:var(--text-muted);">Submitted: <%=c.get("date")%></span>
        </div>
        <%String note=(String)c.get("adminNote"); if(note!=null&&!note.isEmpty()){%>
        <div style="margin-top:10px;padding:10px 14px;background:rgba(52,211,153,0.08);border-left:3px solid var(--success);border-radius:0 6px 6px 0;">
            <div style="font-size:0.78rem;color:var(--success);font-weight:600;margin-bottom:4px;">&#128100; Admin Response:</div>
            <div style="font-size:0.85rem;color:var(--text-light);"><%=sanitize(note)%></div>
            <div style="font-size:0.72rem;color:var(--text-muted);margin-top:4px;">Updated: <%=c.get("updated")%></div>
        </div>
        <%}%>
    </div>
    <%}%>
    </div>
    <%}%>
</div>
<%@ include file="../includes/scripts.jsp" %>
</body></html>
