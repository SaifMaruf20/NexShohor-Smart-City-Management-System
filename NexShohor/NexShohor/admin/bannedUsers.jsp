<%@ page import="java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
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
%>

<%
String actionMsg="",actionType="";
Connection con=null; PreparedStatement ps=null; ResultSet rs=null;

/* ── BAN USER ──────────────────────────────────────────────── */
String banEmail=request.getParameter("banEmail"), banReason=request.getParameter("banReason");
if(banEmail!=null&&!banEmail.trim().isEmpty()){
    try{
        con=getConnection(); con.setAutoCommit(false);
        ps=con.prepareStatement("UPDATE nexshohor_users SET is_banned=1,ban_reason=?,banned_at=CURRENT_TIMESTAMP WHERE email=?");
        ps.setString(1,banReason!=null?banReason.trim():"Suspicious activity");
        ps.setString(2,banEmail.trim().toLowerCase());
        int rows=ps.executeUpdate();
        if(rows>0){
            con.commit();
            /* Insert notification for the banned user */
            PreparedStatement psN=null;
            try{
                psN=con.prepareStatement("INSERT INTO NOTIFICATIONS(USER_EMAIL,NOTIF_TYPE,TITLE,BODY) VALUES(?,?,?,?)");
                psN.setString(1,banEmail.trim().toLowerCase()); psN.setString(2,"ban");
                psN.setString(3,"Account Suspended");
                psN.setString(4,"Your account has been suspended. Reason: "+(banReason!=null?banReason:"Suspicious activity"));
                psN.executeUpdate(); con.commit();
            }catch(Exception en){}finally{if(psN!=null)try{psN.close();}catch(Exception ig){}}
            actionMsg="User "+banEmail+" has been banned."; actionType="success";
        }else{con.rollback(); actionMsg="User not found."; actionType="warn";}
    }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
        logError("bannedUsers.jsp",e); actionMsg="Ban failed: "+e.getMessage(); actionType="danger";
    }finally{closeDB(con,ps,null);}
}

/* ── UNBAN USER ────────────────────────────────────────────── */
String unbanId=request.getParameter("unbanId");
if(unbanId!=null&&!unbanId.trim().isEmpty()){
    try{
        int uid=Integer.parseInt(unbanId.trim());
        con=getConnection(); con.setAutoCommit(false);
        ps=con.prepareStatement("UPDATE nexshohor_users SET is_banned=0,ban_reason=NULL,banned_at=NULL WHERE id=?");
        ps.setInt(1,uid); int rows=ps.executeUpdate();
        if(rows>0){con.commit(); actionMsg="User #"+uid+" has been unbanned."; actionType="success";}
        else{con.rollback(); actionMsg="User not found."; actionType="warn";}
    }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
        logError("bannedUsers.jsp",e); actionMsg="Unban failed."; actionType="danger";
    }finally{closeDB(con,ps,null);}
}

/* ── LOAD BANNED USERS ─────────────────────────────────────── */
List<Map<String,Object>> bannedUsers=new ArrayList<>();
int totalBanned=0;
String searchQ=request.getParameter("q"); if(searchQ==null)searchQ="";
try{
    con=getConnection();
    String base="FROM nexshohor_users WHERE is_banned=1"+
        (!searchQ.isEmpty()?" AND (LOWER(email) LIKE ? OR LOWER(name) LIKE ? OR LOWER(phone) LIKE ?)":"");
    ps=con.prepareStatement("SELECT COUNT(*) "+base);
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(1,lq);ps.setString(2,lq);ps.setString(3,lq);}
    rs=ps.executeQuery(); if(rs.next())totalBanned=rs.getInt(1); rs.close(); ps.close();

    ps=con.prepareStatement("SELECT id,name,email,phone,userType,ban_reason,banned_at "+base+" ORDER BY banned_at DESC");
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(1,lq);ps.setString(2,lq);ps.setString(3,lq);}
    rs=ps.executeQuery();
    SimpleDateFormat sdf=new SimpleDateFormat("dd MMM yyyy HH:mm");
    while(rs.next()){Map<String,Object> m=new HashMap<>();
        m.put("id",rs.getInt("id")); m.put("name",rs.getString("name")); m.put("email",rs.getString("email"));
        m.put("phone",rs.getString("phone")); m.put("type",rs.getString("userType"));
        m.put("reason",rs.getString("ban_reason"));
        java.sql.Timestamp bt=rs.getTimestamp("banned_at"); m.put("bannedAt",bt!=null?sdf.format(bt):"—");
        bannedUsers.add(m);}
}catch(Exception e){logError("bannedUsers.jsp",e);}finally{closeDB(con,ps,rs);}

/* ── LOAD ALL ACTIVE USERS for ban dropdown ────────────────── */
List<Map<String,String>> activeUsers=new ArrayList<>();
try{
    con=getConnection();
    ps=con.prepareStatement("SELECT name,email,userType FROM nexshohor_users WHERE is_banned=0 ORDER BY name");
    rs=ps.executeQuery();
    while(rs.next()){Map<String,String> m=new HashMap<>(); m.put("name",rs.getString("name")); m.put("email",rs.getString("email")); m.put("type",rs.getString("userType")); activeUsers.add(m);}
}catch(Exception e){logError("bannedUsers.jsp",e);}finally{closeDB(con,ps,rs);}
%>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Banned Users – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head><body>
<%@ include file="../admin/nav.jsp" %>
<div class="bv-container">
    <div class="glass bv-page-header">
        <h4>&#128683; Banned Users Management</h4>
        <p><%= totalBanned %> user<%= totalBanned==1?"":"s" %> currently banned</p>
    </div>

    <%if(!actionMsg.isEmpty()){%><div class="bv-alert bv-alert-<%=actionType%>"><%="success".equals(actionType)?"&#10003;":"&#9888;"%> <%=sanitize(actionMsg)%></div><%}%>

    <!-- BAN A USER FORM -->
    <div class="glass" style="padding:24px;margin-bottom:24px;">
        <div class="bv-section-title" style="margin-bottom:16px;">&#128683; Ban a User</div>
        <form method="post" onsubmit="return confirm('Are you sure you want to ban this user? They will lose all access.');">
            <div style="display:grid;grid-template-columns:1fr 1fr 1fr auto;gap:12px;align-items:end;flex-wrap:wrap;">
                <div class="bv-form-group" style="margin-bottom:0;">
                    <label class="bv-label">Select User <span class="bv-required">*</span></label>
                    <select name="banEmail" class="bv-select" required>
                        <option value="">— Select active user —</option>
                        <%for(Map<String,String> u:activeUsers){%>
                        <option value="<%=sanitize(u.get("email"))%>"><%=sanitize(u.get("name"))%> (<%=sanitize(u.get("type"))%>) – <%=sanitize(u.get("email"))%></option>
                        <%}%>
                    </select>
                </div>
                <div class="bv-form-group" style="margin-bottom:0;grid-column:span 2;">
                    <label class="bv-label">Ban Reason <span class="bv-required">*</span></label>
                    <input type="text" name="banReason" class="bv-input" placeholder="e.g. Scam activity, false listings, harassment..." required>
                </div>
                <div>
                    <button type="submit" class="bv-btn bv-btn-danger" style="width:100%;">&#128683; Ban User</button>
                </div>
            </div>
        </form>
    </div>

    <!-- SEARCH -->
    <form method="get" class="glass bv-filter" style="margin-bottom:20px;">
        <input type="text" name="q" class="bv-input" placeholder="&#128269; Search banned users..." value="<%=sanitize(searchQ)%>" style="flex:1;">
        <button type="submit" class="bv-btn bv-btn-primary">Search</button>
        <a href="bannedUsers.jsp" class="bv-btn bv-btn-outline">Reset</a>
    </form>

    <%if(bannedUsers.isEmpty()){%>
    <div class="glass bv-empty"><span class="bv-empty-icon">&#127881;</span><h5>No banned users</h5><p style="color:var(--text-muted);">The system is clean!</p></div>
    <%}else{%>
    <div class="glass" style="overflow:hidden;"><div class="bv-table-wrap">
    <table class="bv-table">
        <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Phone</th><th>Type</th><th>Ban Reason</th><th>Banned At</th><th>Action</th></tr></thead>
        <tbody>
        <%for(Map<String,Object> u:bannedUsers){%>
        <tr>
            <td>#<%=u.get("id")%></td>
            <td><strong><%=sanitize((String)u.get("name"))%></strong></td>
            <td style="font-size:0.82rem;"><%=sanitize((String)u.get("email"))%></td>
            <td><%=sanitize((String)u.get("phone"))%></td>
            <td><span class="bv-badge <%="Bariwala".equals(u.get("type"))?"bv-badge-pending":"bv-badge-approved"%>"><%=u.get("type")%></span></td>
            <td style="max-width:180px;color:var(--danger);font-size:0.82rem;"><%=sanitize((String)u.get("reason"))%></td>
            <td style="font-size:0.78rem;white-space:nowrap;"><%=u.get("bannedAt")%></td>
            <td>
                <a href="bannedUsers.jsp?unbanId=<%=u.get("id")%>&q=<%=sanitize(searchQ)%>"
                   class="bv-btn bv-btn-warn bv-btn-sm" onclick="return confirm('Unban this user and restore access?');">&#128275; Unban</a>
            </td>
        </tr>
        <%}%>
        </tbody>
    </table></div></div>
    <%}%>
</div>
<%@ include file="../includes/scripts.jsp" %>
</body></html>
