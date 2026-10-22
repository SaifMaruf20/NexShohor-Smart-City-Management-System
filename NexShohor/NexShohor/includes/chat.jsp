<%@ page import="java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
/* ── Session check – allow both roles ─────────────────────── */
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache"); response.setDateHeader("Expires",0);

String sessionUser  = (String)session.getAttribute("user");
String sessionType  = (String)session.getAttribute("userType");
String sessionEmail = (String)session.getAttribute("userEmail");

if(sessionUser==null||sessionEmail==null){
    response.sendRedirect(request.getContextPath()../user/login.jsp"); return;
}
if(!"Bariwala".equalsIgnoreCase(sessionType)&&!"Varatia".equalsIgnoreCase(sessionType)){
    response.sendRedirect(request.getContextPath()../user/login.jsp"); return;
}

String requestIdParam=request.getParameter("rid");
if(requestIdParam==null||requestIdParam.trim().isEmpty()){
    response.sendRedirect("../user/login.jsp"); return;
}
int rid=0;
try{rid=Integer.parseInt(requestIdParam.trim());}catch(Exception ig){response.sendRedirect("../user/login.jsp");return;}

String actionMsg="",actionType="";
Connection con=null; PreparedStatement ps=null; ResultSet rs=null;

/* ── Verify access: caller must be tenant or property owner of this request ── */
String ownerEmail="", tenantEmail="", propertyAddress="", tenantName="";
boolean hasAccess=false;
try{
    con=getConnection();
    ps=con.prepareStatement(
        "SELECT tr.TENANT_EMAIL, tr.TENANT_NAME, h.OWNER_EMAIL, h.ADDRESS "+
        "FROM TENANT_REQUESTS tr JOIN HOUSE_POST h ON tr.POST_ID=h.POST_ID "+
        "WHERE tr.REQUEST_ID=?");
    ps.setInt(1,rid); rs=ps.executeQuery();
    if(rs.next()){
        tenantEmail=rs.getString("TENANT_EMAIL"); tenantName=rs.getString("TENANT_NAME");
        ownerEmail=rs.getString("OWNER_EMAIL"); propertyAddress=rs.getString("ADDRESS");
        hasAccess=sessionEmail.equalsIgnoreCase(tenantEmail)||sessionEmail.equalsIgnoreCase(ownerEmail);
    }
}catch(Exception e){logError("chat.jsp",e);}finally{closeDB(con,ps,rs);}

if(!hasAccess){
    response.sendRedirect("../user/login.jsp"); return;
}

/* Determine "other" party label (no phone shown) */
String otherLabel;
if(sessionEmail.equalsIgnoreCase(ownerEmail)){
    otherLabel="Varatia ("+tenantName.split(" ")[0]+")";
} else {
    otherLabel="Bariwala (Property Owner)";
}

/* ── SEND MESSAGE ──────────────────────────────────────────── */
if("POST".equalsIgnoreCase(request.getMethod())){
    String msgText=request.getParameter("msgText");
    if(msgText!=null&&!msgText.trim().isEmpty()){
        String trimMsg=msgText.trim().substring(0,Math.min(msgText.trim().length(),2000));
        try{
            con=getConnection(); con.setAutoCommit(false);
            ps=con.prepareStatement("INSERT INTO MESSAGES(REQUEST_ID,SENDER_EMAIL,SENDER_TYPE,MESSAGE_TEXT) VALUES(?,?,?,?)");
            ps.setInt(1,rid); ps.setString(2,sessionEmail);
            ps.setString(3,sessionType); ps.setString(4,trimMsg);
            ps.executeUpdate(); con.commit();

            /* Notify the other party */
            String recipientEmail=sessionEmail.equalsIgnoreCase(ownerEmail)?tenantEmail:ownerEmail;
            PreparedStatement psN=null;
            try{
                psN=con.prepareStatement("INSERT INTO NOTIFICATIONS(USER_EMAIL,NOTIF_TYPE,TITLE,BODY,LINK_URL) VALUES(?,?,?,?,?)");
                psN.setString(1,recipientEmail); psN.setString(2,"new_message");
                psN.setString(3,"New message from "+sessionType);
                psN.setString(4,trimMsg.substring(0,Math.min(trimMsg.length(),80))+(trimMsg.length()>80?"...":""));
                psN.setString(5,"../includes/chat.jsp?rid="+rid);
                psN.executeUpdate(); con.commit();
            }catch(Exception en){}finally{if(psN!=null)try{psN.close();}catch(Exception ig){}}
        }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
            logError("chat.jsp",e); actionMsg="Failed to send."; actionType="danger";
        }finally{closeDB(con,ps,null);}
    }
}

/* ── MARK MESSAGES AS READ ─────────────────────────────────── */
try{
    con=getConnection();
    ps=con.prepareStatement("UPDATE MESSAGES SET IS_READ=1 WHERE REQUEST_ID=? AND SENDER_EMAIL<>? AND IS_READ=0");
    ps.setInt(1,rid); ps.setString(2,sessionEmail); ps.executeUpdate();
    con.commit();
}catch(Exception e){}finally{closeDB(con,ps,null);}

/* ── LOAD MESSAGES ─────────────────────────────────────────── */
List<Map<String,Object>> messages=new ArrayList<>();
try{
    con=getConnection();
    ps=con.prepareStatement("SELECT MSG_ID,SENDER_EMAIL,SENDER_TYPE,MESSAGE_TEXT,IS_READ,SENT_AT FROM MESSAGES WHERE REQUEST_ID=? ORDER BY SENT_AT ASC");
    ps.setInt(1,rid); rs=ps.executeQuery();
    SimpleDateFormat sdf=new SimpleDateFormat("dd MMM, HH:mm");
    while(rs.next()){Map<String,Object> m=new HashMap<>();
        m.put("id",rs.getInt("MSG_ID")); m.put("sender",rs.getString("SENDER_EMAIL"));
        m.put("senderType",rs.getString("SENDER_TYPE")); m.put("text",rs.getString("MESSAGE_TEXT"));
        m.put("isMe",sessionEmail.equalsIgnoreCase(rs.getString("SENDER_EMAIL")));
        java.sql.Timestamp ts=rs.getTimestamp("SENT_AT"); m.put("time",ts!=null?sdf.format(ts):"—");
        messages.add(m);}
}catch(Exception e){logError("chat.jsp",e);}finally{closeDB(con,ps,rs);}

/* Nav include path depends on userType */
String navInclude="Bariwala".equalsIgnoreCase(sessionType)?"../bariwala/nav.jsp":"../varatiya/nav.jsp";
%>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Chat – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.chat-container{max-width:760px;margin:0 auto;}
.chat-header{padding:16px 20px;border-bottom:1px solid var(--glass-bdr);display:flex;align-items:center;gap:12px;}
.chat-avatar{width:42px;height:42px;border-radius:50%;background:linear-gradient(135deg,var(--accent-dark),var(--accent));display:flex;align-items:center;justify-content:center;font-size:1.2rem;color:#000;font-weight:800;flex-shrink:0;}
.chat-partner-name{font-weight:700;color:#fff;font-size:0.95rem;}
.chat-partner-sub{font-size:0.78rem;color:var(--text-muted);}
.chat-body{height:420px;overflow-y:auto;padding:16px;display:flex;flex-direction:column;gap:10px;scroll-behavior:smooth;}
.bubble-wrap{display:flex;flex-direction:column;}
.bubble-wrap.me{align-items:flex-end;}
.bubble-wrap.other{align-items:flex-start;}
.chat-bubble{max-width:72%;padding:10px 14px;border-radius:14px;font-size:0.88rem;line-height:1.55;word-break:break-word;}
.bubble-wrap.me .chat-bubble{background:linear-gradient(135deg,var(--accent-dark),var(--accent));color:#000;border-bottom-right-radius:4px;}
.bubble-wrap.other .chat-bubble{background:rgba(255,255,255,0.12);color:var(--text-light);border-bottom-left-radius:4px;}
.chat-time{font-size:0.7rem;color:var(--text-muted);margin-top:3px;padding:0 4px;}
.chat-footer{padding:14px 16px;border-top:1px solid var(--glass-bdr);}
.chat-input-row{display:flex;gap:8px;}
.no-phone-note{background:rgba(251,191,36,0.08);border:1px solid rgba(251,191,36,0.3);border-radius:8px;padding:10px 14px;font-size:0.82rem;color:var(--warn);margin-bottom:12px;}
</style>
</head><body>
<%@ include file="<%= navInclude %>" %>
<div class="bv-container" style="padding-top:20px;">
    <a href="javascript:history.back()" class="bv-btn bv-btn-outline bv-btn-sm" style="margin-bottom:16px;">&#8592; Back</a>

    <div class="chat-container glass" style="overflow:hidden;">
        <div class="chat-header">
            <div class="chat-avatar">&#128172;</div>
            <div>
                <div class="chat-partner-name">Chatting with: <%= sanitize(otherLabel) %></div>
                <div class="chat-partner-sub">&#128205; <%= sanitize(propertyAddress.length()>60?propertyAddress.substring(0,57)+"...":propertyAddress) %></div>
            </div>
        </div>

        <div class="no-phone-note" style="margin:12px 16px 0;">
            &#128274; Phone numbers are hidden for privacy. Finalize your deal securely through this chat.
        </div>

        <%if(!actionMsg.isEmpty()){%><div class="bv-alert bv-alert-<%=actionType%>" style="margin:10px 16px;"><%=sanitize(actionMsg)%></div><%}%>

        <div class="chat-body" id="chatBody">
            <%if(messages.isEmpty()){%>
            <div style="text-align:center;color:var(--text-muted);margin:auto;font-size:0.9rem;">&#128172; No messages yet. Start the conversation!</div>
            <%}%>
            <%for(Map<String,Object> m:messages){boolean isMe=(boolean)m.get("isMe");%>
            <div class="bubble-wrap <%=isMe?"me":"other"%>">
                <div class="chat-bubble"><%=sanitize((String)m.get("text"))%></div>
                <div class="chat-time"><%=isMe?"You":"Other"%> &bull; <%=m.get("time")%></div>
            </div>
            <%}%>
        </div>

        <div class="chat-footer">
            <form method="post" class="chat-input-row" onsubmit="return validateMsg();">
                <input type="hidden" name="rid" value="<%=rid%>">
                <input type="text" id="msgInput" name="msgText" class="bv-input" placeholder="Type your message..." maxlength="2000" autocomplete="off" style="flex:1;">
                <button type="submit" class="bv-btn bv-btn-primary" style="white-space:nowrap;">&#9992; Send</button>
            </form>
        </div>
    </div>
</div>

<script>
/* Auto-scroll to bottom */
var cb=document.getElementById('chatBody');
if(cb) cb.scrollTop=cb.scrollHeight;

function validateMsg(){
    var inp=document.getElementById('msgInput');
    if(!inp||!inp.value.trim()){alert('Please type a message.');return false;}
    return true;
}

/* Auto-refresh every 15 seconds */
setTimeout(function(){ window.location.reload(); }, 15000);
</script>
<%@ include file="../includes/scripts.jsp" %>
</body></html>
