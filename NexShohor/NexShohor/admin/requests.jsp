<%@ page import="java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache"); response.setDateHeader("Expires",0);

String actionMsg="",actionType="";
Connection con=null; PreparedStatement ps=null; ResultSet rs=null;

/* ── DELETE REQUEST ────────────────────────────────────────── */
String delId=request.getParameter("deleteId");
if(delId!=null&&!delId.trim().isEmpty()){
    try{
        int did=Integer.parseInt(delId.trim());
        con=getConnection(); con.setAutoCommit(false);
        ps=con.prepareStatement("DELETE FROM TENANT_REQUESTS WHERE REQUEST_ID=?");
        ps.setInt(1,did); int rows=ps.executeUpdate();
        if(rows>0){con.commit();actionMsg="Request #"+did+" removed.";actionType="success";}
        else{con.rollback();actionMsg="Request not found.";actionType="warn";}
    }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
        logError("requests.jsp",e);actionMsg="Delete failed.";actionType="danger";
    }finally{closeDB(con,ps,null);}
}

/* ── UPDATE STATUS ─────────────────────────────────────────── */
String updId=request.getParameter("updateId"), updStatus=request.getParameter("newStatus");
if(updId!=null&&updStatus!=null&&!updId.isEmpty()&&!updStatus.isEmpty()){
    String[] allowed={"Pending","Approved","Rejected","Cancelled"};
    boolean ok=false; for(String s:allowed) if(s.equals(updStatus)){ok=true;break;}
    if(ok){
        try{
            con=getConnection(); con.setAutoCommit(false);
            ps=con.prepareStatement("UPDATE TENANT_REQUESTS SET STATUS=? WHERE REQUEST_ID=?");
            ps.setString(1,updStatus); ps.setInt(2,Integer.parseInt(updId.trim()));
            int rows=ps.executeUpdate();
            if(rows>0){con.commit();actionMsg="Request #"+updId+" updated to "+updStatus+".";actionType="success";}
            else{con.rollback();actionMsg="Request not found.";actionType="warn";}
        }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
            logError("requests.jsp",e);actionMsg="Update failed.";actionType="danger";
        }finally{closeDB(con,ps,null);}
    }
}

/* ── PAGINATION & FILTER ───────────────────────────────────── */
int pageSize=12,currentPage=1;
try{currentPage=Integer.parseInt(request.getParameter("page"));}catch(Exception ig){}
if(currentPage<1)currentPage=1;
int offset=(currentPage-1)*pageSize;
String filterStatus=request.getParameter("status"); if(filterStatus==null)filterStatus="";
String searchQ=request.getParameter("q"); if(searchQ==null)searchQ="";

List<Map<String,Object>> reqs=new ArrayList<>(); int totalCount=0;
try{
    con=getConnection();
    String base="FROM TENANT_REQUESTS tr JOIN HOUSE_POST h ON tr.POST_ID=h.POST_ID WHERE 1=1"+
        (!filterStatus.isEmpty()?" AND tr.STATUS=?":"")+
        (!searchQ.isEmpty()?" AND (LOWER(tr.TENANT_EMAIL) LIKE ? OR LOWER(h.ADDRESS) LIKE ?)":"");
    ps=con.prepareStatement("SELECT COUNT(*) "+base);
    int idx=1;
    if(!filterStatus.isEmpty()) ps.setString(idx++,filterStatus);
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(idx++,lq);ps.setString(idx++,lq);}
    rs=ps.executeQuery(); if(rs.next())totalCount=rs.getInt(1); rs.close(); ps.close();

    ps=con.prepareStatement("SELECT tr.REQUEST_ID,tr.TENANT_EMAIL,tr.TENANT_NAME,tr.STATUS,tr.CREATED_AT,"+
        "h.ADDRESS,h.OWNER_EMAIL,tr.POST_ID "+base+
        " ORDER BY tr.CREATED_AT DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
    idx=1;
    if(!filterStatus.isEmpty()) ps.setString(idx++,filterStatus);
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(idx++,lq);ps.setString(idx++,lq);}
    ps.setInt(idx++,offset); ps.setInt(idx++,pageSize); rs=ps.executeQuery();
    SimpleDateFormat sdf=new SimpleDateFormat("dd MMM yyyy");
    while(rs.next()){Map<String,Object> m=new HashMap<>();
        m.put("id",rs.getInt("REQUEST_ID")); m.put("tenant",rs.getString("TENANT_EMAIL"));
        m.put("tenantName",rs.getString("TENANT_NAME")); m.put("status",rs.getString("STATUS"));
        java.sql.Timestamp ts=rs.getTimestamp("CREATED_AT"); m.put("date",ts!=null?sdf.format(ts):"—");
        m.put("address",rs.getString("ADDRESS")); m.put("owner",rs.getString("OWNER_EMAIL"));
        m.put("postId",rs.getInt("POST_ID")); reqs.add(m);}
}catch(Exception e){logError("requests.jsp",e);}finally{closeDB(con,ps,rs);}
int totalPages=(int)Math.ceil((double)totalCount/pageSize);
%>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Requests Management – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head><body>
<%@ include file="../admin/nav.jsp" %>
<div class="bv-container">
    <div class="glass bv-page-header">
        <h4>&#128203; Tenant Requests Management</h4>
        <p>Total: <%= totalCount %> request<%= totalCount==1?"":"s" %></p>
    </div>
    <%if(!actionMsg.isEmpty()){%><div class="bv-alert bv-alert-<%=actionType%>"><%="success".equals(actionType)?"&#10003;":"&#9888;"%> <%=sanitize(actionMsg)%></div><%}%>

    <form method="get" class="glass bv-filter" style="margin-bottom:20px;flex-wrap:wrap;gap:10px;">
        <input type="text" name="q" class="bv-input" placeholder="&#128269; Search tenant or address..." value="<%=sanitize(searchQ)%>" style="flex:2;min-width:180px;">
        <select name="status" class="bv-select" style="flex:1;min-width:130px;">
            <option value="">All Status</option>
            <option value="Pending"   <%="Pending".equals(filterStatus)?"selected":""%>>Pending</option>
            <option value="Approved"  <%="Approved".equals(filterStatus)?"selected":""%>>Approved</option>
            <option value="Rejected"  <%="Rejected".equals(filterStatus)?"selected":""%>>Rejected</option>
            <option value="Cancelled" <%="Cancelled".equals(filterStatus)?"selected":""%>>Cancelled</option>
        </select>
        <button type="submit" class="bv-btn bv-btn-primary">Filter</button>
        <a href="requests.jsp" class="bv-btn bv-btn-outline">Reset</a>
    </form>

    <%if(reqs.isEmpty()){%>
    <div class="glass bv-empty"><span class="bv-empty-icon">&#128203;</span><h5>No requests found</h5></div>
    <%}else{%>
    <div class="glass" style="overflow:hidden;"><div class="bv-table-wrap">
    <table class="bv-table">
        <thead><tr><th>ID</th><th>Tenant</th><th>Property</th><th>Owner</th><th>Status</th><th>Date</th><th>Actions</th></tr></thead>
        <tbody>
        <%for(Map<String,Object> r:reqs){String st=(String)r.get("status");%>
        <tr>
            <td>#<%=r.get("id")%></td>
            <td style="font-size:0.82rem;"><%=sanitize((String)r.get("tenantName"))%><br><span style="color:var(--text-muted);font-size:0.75rem;"><%=sanitize((String)r.get("tenant"))%></span></td>
            <td style="max-width:140px;word-break:break-word;font-size:0.82rem;">&#128205; <%=sanitize((String)r.get("address"))%></td>
            <td style="font-size:0.78rem;color:var(--text-muted);"><%=sanitize((String)r.get("owner"))%></td>
            <td>
                <%if("Approved".equalsIgnoreCase(st)){%><span class="bv-badge bv-badge-approved">&#10003; Approved</span>
                <%}else if("Rejected".equalsIgnoreCase(st)){%><span class="bv-badge bv-badge-rejected">&#10005; Rejected</span>
                <%}else if("Cancelled".equalsIgnoreCase(st)){%><span class="bv-badge bv-badge-cancelled">Cancelled</span>
                <%}else{%><span class="bv-badge bv-badge-pending">&#8987; Pending</span><%}%>
            </td>
            <td style="font-size:0.8rem;white-space:nowrap;"><%=r.get("date")%></td>
            <td style="white-space:nowrap;">
                <form method="post" style="display:inline;">
                    <input type="hidden" name="updateId" value="<%=r.get("id")%>">
                    <input type="hidden" name="q" value="<%=sanitize(searchQ)%>">
                    <input type="hidden" name="status" value="<%=sanitize(filterStatus)%>">
                    <input type="hidden" name="page" value="<%=currentPage%>">
                    <select name="newStatus" class="bv-select" style="padding:3px 6px;font-size:0.78rem;width:100px;display:inline-block;">
                        <option value="Pending"   <%="Pending".equals(st)?"selected":""%>>Pending</option>
                        <option value="Approved"  <%="Approved".equals(st)?"selected":""%>>Approved</option>
                        <option value="Rejected"  <%="Rejected".equals(st)?"selected":""%>>Rejected</option>
                        <option value="Cancelled" <%="Cancelled".equals(st)?"selected":""%>>Cancelled</option>
                    </select>
                    <button type="submit" class="bv-btn bv-btn-warn bv-btn-sm">&#128190;</button>
                </form>
                <a href="requests.jsp?deleteId=<%=r.get("id")%>&q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>&page=<%=currentPage%>"
                   class="bv-btn bv-btn-danger bv-btn-sm" onclick="return bvConfirm('Remove request #<%=r.get("id")%>?');">&#128465;</a>
            </td>
        </tr>
        <%}%>
        </tbody>
    </table></div></div>
    <%if(totalPages>1){%>
    <div class="bv-pagination" style="justify-content:center;margin-top:16px;">
        <%if(currentPage>1){%><a href="requests.jsp?page=<%=currentPage-1%>&q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>" class="bv-page-btn">&#8249; Prev</a><%}%>
        <%for(int i=1;i<=totalPages;i++){%><a href="requests.jsp?page=<%=i%>&q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>" class="bv-page-btn <%=i==currentPage?"active":""%>"><%=i%></a><%}%>
        <%if(currentPage<totalPages){%><a href="requests.jsp?page=<%=currentPage+1%>&q=<%=sanitize(searchQ)%>&status=<%=sanitize(filterStatus)%>" class="bv-page-btn">Next &#8250;</a><%}%>
    </div><%}%>
    <%}%>
</div>
<%@ include file="../includes/scripts.jsp" %>
</body></html>
