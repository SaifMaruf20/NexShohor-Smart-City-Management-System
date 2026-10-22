<%@ page import="java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache"); response.setDateHeader("Expires",0);

String actionMsg="",actionType="";
Connection con=null; PreparedStatement ps=null; ResultSet rs=null;

/* ── UPDATE COMPLAINT STATUS ───────────────────────────────── */
String updId=request.getParameter("updateId"), updStatus=request.getParameter("newStatus"), adminNote=request.getParameter("adminNote");
if(updId!=null&&updStatus!=null&&!updId.isEmpty()&&!updStatus.isEmpty()){
    String[] allowed={"Open","In Review","Resolved","Closed"};
    boolean ok=false; for(String s:allowed) if(s.equals(updStatus)){ok=true;break;}
    if(ok){
        try{
            int cid=Integer.parseInt(updId.trim());
            con=getConnection(); con.setAutoCommit(false);
            ps=con.prepareStatement("UPDATE COMPLAINTS SET STATUS=?,ADMIN_NOTE=?,UPDATED_AT=CURRENT_TIMESTAMP WHERE COMPLAINT_ID=?");
            ps.setString(1,updStatus); ps.setString(2,adminNote!=null?adminNote.trim():null); ps.setInt(3,cid);
            int rows=ps.executeUpdate();
            if(rows>0){
                con.commit();
                /* Notify user */
                String userEmail="";
                PreparedStatement psQ=null; ResultSet rsQ=null;
                try{
                    psQ=con.prepareStatement("SELECT USER_EMAIL FROM COMPLAINTS WHERE COMPLAINT_ID=?");
                    psQ.setInt(1,cid); rsQ=psQ.executeQuery(); if(rsQ.next())userEmail=rsQ.getString(1);
                }catch(Exception ig){}finally{if(rsQ!=null)try{rsQ.close();}catch(Exception ig){}if(psQ!=null)try{psQ.close();}catch(Exception ig){}}
                if(!userEmail.isEmpty()){
                    PreparedStatement psN=null;
                    try{
                        psN=con.prepareStatement("INSERT INTO NOTIFICATIONS(USER_EMAIL,NOTIF_TYPE,TITLE,BODY,LINK_URL) VALUES(?,?,?,?,?)");
                        psN.setString(1,userEmail); psN.setString(2,"complaint_update");
                        psN.setString(3,"Complaint #"+cid+" Updated");
                        psN.setString(4,"Your complaint status is now: "+updStatus);
                        psN.setString(5,"../bariwala/complaints.jsp");
                        psN.executeUpdate(); con.commit();
                    }catch(Exception en){}finally{if(psN!=null)try{psN.close();}catch(Exception ig){}}
                }
                actionMsg="Complaint #"+cid+" updated to '"+updStatus+"'."; actionType="success";
            }else{con.rollback(); actionMsg="Complaint not found."; actionType="warn";}
        }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
            logError("complaints.jsp",e); actionMsg="Update failed."; actionType="danger";
        }finally{closeDB(con,ps,null);}
    }
}

/* ── DELETE COMPLAINT ──────────────────────────────────────── */
String delId=request.getParameter("deleteId");
if(delId!=null&&!delId.trim().isEmpty()){
    try{
        con=getConnection(); con.setAutoCommit(false);
        ps=con.prepareStatement("DELETE FROM COMPLAINTS WHERE COMPLAINT_ID=?");
        ps.setInt(1,Integer.parseInt(delId.trim())); int rows=ps.executeUpdate();
        if(rows>0){con.commit(); actionMsg="Complaint deleted."; actionType="success";}
        else{con.rollback(); actionMsg="Not found."; actionType="warn";}
    }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
        logError("complaints.jsp",e); actionMsg="Delete failed."; actionType="danger";
    }finally{closeDB(con,ps,null);}
}

/* ── PAGINATION & FILTER ───────────────────────────────────── */
int pageSize=10,currentPage=1;
try{currentPage=Integer.parseInt(request.getParameter("page"));}catch(Exception ig){}
if(currentPage<1)currentPage=1;
int offset=(currentPage-1)*pageSize;
String filterStatus=request.getParameter("status"); if(filterStatus==null)filterStatus="";
String searchQ=request.getParameter("q"); if(searchQ==null)searchQ="";

List<Map<String,Object>> complaints=new ArrayList<>(); int totalCount=0;
try{
    con=getConnection();
    String base="FROM COMPLAINTS WHERE 1=1"+
        (!filterStatus.isEmpty()?" AND STATUS=?":"")+
        (!searchQ.isEmpty()?" AND (LOWER(USER_EMAIL) LIKE ? OR LOWER(SUBJECT) LIKE ?)":"");
    ps=con.prepareStatement("SELECT COUNT(*) "+base);
    int idx=1;
    if(!filterStatus.isEmpty())ps.setString(idx++,filterStatus);
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(idx++,lq);ps.setString(idx++,lq);}
    rs=ps.executeQuery(); if(rs.next())totalCount=rs.getInt(1); rs.close(); ps.close();

    ps=con.prepareStatement("SELECT COMPLAINT_ID,USER_EMAIL,USER_TYPE,SUBJECT,DESCRIPTION,STATUS,ADMIN_NOTE,CREATED_AT "+base+
        " ORDER BY CREATED_AT DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
    idx=1;
    if(!filterStatus.isEmpty())ps.setString(idx++,filterStatus);
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(idx++,lq);ps.setString(idx++,lq);}
    ps.setInt(idx++,offset); ps.setInt(idx++,pageSize); rs=ps.executeQuery();
    SimpleDateFormat sdf=new SimpleDateFormat("dd MMM yyyy HH:mm");
    while(rs.next()){Map<String,Object> m=new HashMap<>();
        m.put("id",rs.getInt("COMPLAINT_ID")); m.put("email",rs.getString("USER_EMAIL"));
        m.put("userType",rs.getString("USER_TYPE")); m.put("subject",rs.getString("SUBJECT"));
        Clob cl=rs.getClob("DESCRIPTION"); m.put("desc",cl!=null?cl.getSubString(1,(int)Math.min(cl.length(),300)):"");
        m.put("status",rs.getString("STATUS")); m.put("adminNote",rs.getString("ADMIN_NOTE"));
        java.sql.Timestamp ts=rs.getTimestamp("CREATED_AT"); m.put("date",ts!=null?sdf.format(ts):"—");
        complaints.add(m);}
}catch(Exception e){logError("complaints.jsp",e);}finally{closeDB(con,ps,rs);}
int totalPages=(int)Math.ceil((double)totalCount/pageSize);

String editId=request.getParameter("editId");
%>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Complaints – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.complaint-desc{font-size:0.82rem;color:var(--text-muted);margin-top:4px;max-width:220px;word-break:break-word;}
.edit-panel{background:rgba(255,255,255,0.06);border-radius:10px;padding:16px;margin-top:10px;}
</style>
</head><body>
<%@ include file="../admin/nav.jsp" %>
<div class="bv-container">
    <div class="glass bv-page-header">
        <h4>&#128226; Complaints Management</h4>
        <p>Total: <%= totalCount %> complaint<%= totalCount==1?"":"s" %></p>
    </div>

    <%if(!actionMsg.isEmpty()){%><div class="bv-alert bv-alert-<%=actionType%>"><%="success".equals(actionType)?"&#10003;":"&#9888;"%> <%=sanitize(actionMsg)%></div><%}%>

    <form method="get" class="glass bv-filter" style="margin-bottom:20px;flex-wrap:wrap;gap:10px;">
        <input type="text" name="q" class="bv-input" placeholder="&#128269; Search by email or subject..." value="<%=sanitize(searchQ)%>" style="flex:2;min-width:180px;">
        <select name="status" class="bv-select" style="flex:1;min-width:130px;">
            <option value="">All Status</option>
            <option value="Open"      <%="Open".equals(filterStatus)?"selected":""%>>Open</option>
            <option value="In Review" <%="In Review".equals(filterStatus)?"selected":""%>>In Review</option>
            <option value="Resolved"  <%="Resolved".equals(filterStatus)?"selected":""%>>Resolved</option>
            <option value="Closed"    <%="Closed".equals(filterStatus)?"selected":""%>>Closed</option>
        </select>
        <button type="submit" class="bv-btn bv-btn-primary">Filter</button>
        <a href="complaints.jsp" class="bv-btn bv-btn-outline">Reset</a>
    </form>

    <%if(complaints.isEmpty()){%>
    <div class="glass bv-empty"><span class="bv-empty-icon">&#128226;</span><h5>No complaints found</h5></div>
    <%}else{%>
    <div style="display:flex;flex-direction:column;gap:16px;">
    <%for(Map<String,Object> c:complaints){
        String st=(String)c.get("status");
        String badgeCls="bv-badge-open";
        if("In Review".equals(st))badgeCls="bv-badge-inreview";
        else if("Resolved".equals(st))badgeCls="bv-badge-resolved";
        else if("Closed".equals(st))badgeCls="bv-badge-closed";
        boolean isEditing=String.valueOf(c.get("id")).equals(editId);
    %>
    <div class="glass" style="padding:20px;">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:10px;">
            <div>
                <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
                    <span style="font-weight:700;color:#fff;">&#128226; #<%=c.get("id")%> – <%=sanitize((String)c.get("subject"))%></span>
                    <span class="bv-badge <%=badgeCls%>"><%=st%></span>
                    <span class="bv-badge <%="Bariwala".equals(c.get("userType"))?"bv-badge-pending":"bv-badge-approved"%>" style="font-size:0.7rem;"><%=c.get("userType")%></span>
                </div>
                <div style="font-size:0.8rem;color:var(--text-muted);margin-top:4px;">&#128100; <%=sanitize((String)c.get("email"))%> &nbsp;|&nbsp; &#128337; <%=c.get("date")%></div>
                <div class="complaint-desc"><%=sanitize((String)c.get("desc"))%><%=((String)c.get("desc")).length()>=300?"...":""%></div>
               <%String cAdminNote=(String)c.get("adminNote"); if(cAdminNote!=null&&!cAdminNote.isEmpty()){%>
                <div style="margin-top:8px;padding:8px 12px;background:rgba(96,165,250,0.1);border-left:3px solid var(--blue);border-radius:0 6px 6px 0;font-size:0.82rem;color:var(--blue);">
                    &#128221; Admin note: <%=sanitize(cAdminNote)%>
                </div><%}%>
            </div>
            <div style="display:flex;gap:8px;flex-shrink:0;">
                <a href="complaints.jsp?editId=<%=c.get("id")%>&q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>&page=<%=currentPage%>"
                   class="bv-btn bv-btn-warn bv-btn-sm">&#9998; Manage</a>
                <a href="complaints.jsp?deleteId=<%=c.get("id")%>&q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>&page=<%=currentPage%>"
                   class="bv-btn bv-btn-danger bv-btn-sm" onclick="return bvConfirm('Delete complaint #<%=c.get("id")%>?');">&#128465;</a>
            </div>
        </div>
        <%if(isEditing){%>
        <div class="edit-panel" style="margin-top:14px;">
            <form method="post">
                <input type="hidden" name="updateId" value="<%=c.get("id")%>">
                <input type="hidden" name="q" value="<%=sanitize(searchQ)%>">
                <input type="hidden" name="status" value="<%=sanitize(filterStatus)%>">
                <input type="hidden" name="page" value="<%=currentPage%>">
                <div style="display:grid;grid-template-columns:1fr 2fr;gap:12px;align-items:end;">
                    <div class="bv-form-group" style="margin-bottom:0;">
                        <label class="bv-label">Update Status</label>
                        <select name="newStatus" class="bv-select">
                            <option value="Open"      <%="Open".equals(st)?"selected":""%>>Open</option>
                            <option value="In Review" <%="In Review".equals(st)?"selected":""%>>In Review</option>
                            <option value="Resolved"  <%="Resolved".equals(st)?"selected":""%>>Resolved</option>
                            <option value="Closed"    <%="Closed".equals(st)?"selected":""%>>Closed</option>
                        </select>
                    </div>
                    <div class="bv-form-group" style="margin-bottom:0;">
                        <label class="bv-label">Admin Note (visible to user)</label>
                        <input type="text" name="adminNote" class="bv-input" placeholder="Add a response or note..."
                               value="<%=cAdminNote!=null?sanitize(cAdminNote):""%>">
                    </div>
                </div>
                <div style="display:flex;gap:8px;margin-top:12px;">
                    <button type="submit" class="bv-btn bv-btn-primary bv-btn-sm">&#128190; Save</button>
                    <a href="complaints.jsp?q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>&page=<%=currentPage%>" class="bv-btn bv-btn-outline bv-btn-sm">&#10005; Cancel</a>
                </div>
            </form>
        </div>
        <%}%>
    </div>
    <%}%>
    </div>
    <%if(totalPages>1){%>
    <div class="bv-pagination" style="justify-content:center;margin-top:16px;">
        <%if(currentPage>1){%><a href="complaints.jsp?page=<%=currentPage-1%>&q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>" class="bv-page-btn">&#8249; Prev</a><%}%>
        <%for(int i=1;i<=totalPages;i++){%><a href="complaints.jsp?page=<%=i%>&q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>" class="bv-page-btn <%=i==currentPage?"active":""%>"><%=i%></a><%}%>
        <%if(currentPage<totalPages){%><a href="complaints.jsp?page=<%=currentPage+1%>&q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>" class="bv-page-btn">Next &#8250;</a><%}%>
    </div><%}%>
    <%}%>
</div>
<%@ include file="../includes/scripts.jsp" %>
</body></html>
