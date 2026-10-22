<%@ page import="java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache"); response.setDateHeader("Expires",0);

String sessionUser=(String)session.getAttribute("user");
String sessionType=(String)session.getAttribute("userType");
String sessionEmail=(String)session.getAttribute("userEmail");
if(sessionUser==null||sessionEmail==null){
    response.sendRedirect(request.getContextPath()../user/login.jsp"); return;
}

Connection con=null; PreparedStatement ps=null; ResultSet rs=null;

/* ── MARK ALL READ ─────────────────────────────────────────── */
if("markall".equals(request.getParameter("action"))){
    try{
        con=getConnection();
        ps=con.prepareStatement("UPDATE NOTIFICATIONS SET IS_READ=1 WHERE USER_EMAIL=? AND IS_READ=0");
        ps.setString(1,sessionEmail); ps.executeUpdate(); con.commit();
    }catch(Exception e){}finally{closeDB(con,ps,null);}
    response.sendRedirect("notifications.jsp"); return;
}

/* ── MARK ONE READ ─────────────────────────────────────────── */
String readId=request.getParameter("readId");
if(readId!=null&&!readId.trim().isEmpty()){
    try{
        con=getConnection();
        ps=con.prepareStatement("UPDATE NOTIFICATIONS SET IS_READ=1 WHERE NOTIF_ID=? AND USER_EMAIL=?");
        ps.setInt(1,Integer.parseInt(readId.trim())); ps.setString(2,sessionEmail);
        ps.executeUpdate(); con.commit();
    }catch(Exception e){}finally{closeDB(con,ps,null);}
}

/* ── LOAD NOTIFICATIONS ────────────────────────────────────── */
List<Map<String,Object>> notifs=new ArrayList<>();
int unreadCount=0;
try{
    con=getConnection();
    ps=con.prepareStatement("SELECT NOTIF_ID,NOTIF_TYPE,TITLE,BODY,LINK_URL,IS_READ,CREATED_AT FROM NOTIFICATIONS WHERE USER_EMAIL=? ORDER BY CREATED_AT DESC FETCH FIRST 50 ROWS ONLY");
    ps.setString(1,sessionEmail); rs=ps.executeQuery();
    SimpleDateFormat sdf=new SimpleDateFormat("dd MMM yyyy, HH:mm");
    while(rs.next()){Map<String,Object> m=new HashMap<>();
        m.put("id",rs.getInt("NOTIF_ID")); m.put("type",rs.getString("NOTIF_TYPE"));
        m.put("title",rs.getString("TITLE")); m.put("body",rs.getString("BODY"));
        m.put("link",rs.getString("LINK_URL")); m.put("isRead",rs.getInt("IS_READ")==1);
        java.sql.Timestamp ts=rs.getTimestamp("CREATED_AT"); m.put("time",ts!=null?sdf.format(ts):"—");
        if(rs.getInt("IS_READ")==0)unreadCount++;
        notifs.add(m);}
}catch(Exception e){logError("notifications.jsp",e);}finally{closeDB(con,ps,rs);}

String navInclude="Bariwala".equalsIgnoreCase(sessionType)?"../bariwala/nav.jsp":"../varatiya/nav.jsp";
%>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Notifications – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.notif-card{padding:16px 20px;border-bottom:1px solid var(--glass-bdr);display:flex;gap:14px;align-items:flex-start;transition:background 0.2s;}
.notif-card:last-child{border-bottom:none;}
.notif-card.unread{background:rgba(96,165,250,0.06);}
.notif-card:hover{background:rgba(255,255,255,0.06);}
.notif-icon{font-size:1.5rem;flex-shrink:0;width:40px;text-align:center;}
.notif-title{font-weight:700;color:#fff;font-size:0.9rem;}
.notif-body{font-size:0.82rem;color:var(--text-muted);margin-top:3px;}
.notif-time{font-size:0.72rem;color:var(--text-muted);margin-top:5px;}
.notif-unread-dot{width:8px;height:8px;border-radius:50%;background:var(--blue);flex-shrink:0;margin-top:6px;}
</style>
</head><body>
<%@ include file="<%= navInclude %>" %>
<div class="bv-container">
    <div class="glass bv-page-header" style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px;">
        <div>
            <h4>&#128276; Notifications</h4>
            <p><%= unreadCount %> unread notification<%= unreadCount==1?"":"s" %></p>
        </div>
        <%if(unreadCount>0){%>
        <a href="notifications.jsp?action=markall" class="bv-btn bv-btn-outline bv-btn-sm">&#10003; Mark all read</a>
        <%}%>
    </div>

    <%if(notifs.isEmpty()){%>
    <div class="glass bv-empty"><span class="bv-empty-icon">&#128276;</span><h5>No notifications</h5><p style="color:var(--text-muted);">You're all caught up!</p></div>
    <%}else{%>
    <div class="glass" style="overflow:hidden;">
    <%for(Map<String,Object> n:notifs){
        boolean isRead=(boolean)n.get("isRead");
        String ntype=(String)n.get("type");
        String icon="&#128276;";
        if("new_message".equals(ntype))icon="&#128172;";
        else if("request_status".equals(ntype))icon="&#128203;";
        else if("complaint_update".equals(ntype))icon="&#128226;";
        else if("ban".equals(ntype))icon="&#128683;";
        String link=(String)n.get("link");
    %>
    <div class="notif-card <%=isRead?"":"unread"%>">
        <div class="notif-icon"><%=icon%></div>
        <div style="flex:1;">
            <div class="notif-title"><%=sanitize((String)n.get("title"))%></div>
            <%String body=(String)n.get("body"); if(body!=null&&!body.isEmpty()){%>
            <div class="notif-body"><%=sanitize(body)%></div><%}%>
            <div class="notif-time">&#128337; <%=n.get("time")%></div>
            <%if(link!=null&&!link.isEmpty()){%>
            <a href="<%=sanitize(link)%>?readId=<%=n.get("id")%>" class="bv-btn bv-btn-outline bv-btn-sm" style="margin-top:8px;font-size:0.75rem;">&#128279; View</a>
            <%}%>
        </div>
        <%if(!isRead){%><div class="notif-unread-dot"></div><%}%>
    </div>
    <%}%>
    </div>
    <%}%>
</div>
<%@ include file="../includes/scripts.jsp" %>
</body></html>
