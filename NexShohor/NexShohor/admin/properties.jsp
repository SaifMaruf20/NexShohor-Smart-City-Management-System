<%@ page import="java.sql.*,java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache");
response.setDateHeader("Expires",0);

String actionMsg="", actionType="";
Connection con=null; PreparedStatement ps=null; ResultSet rs=null;

/* ── DELETE ─────────────────────────────────────────────── */
String deleteId=request.getParameter("deleteId");
if(deleteId!=null&&!deleteId.trim().isEmpty()){
    try{
        int did=Integer.parseInt(deleteId.trim());
        con=getConnection();con.setAutoCommit(false);
        ps=con.prepareStatement("DELETE FROM HOUSE_POST WHERE POST_ID=?");
        ps.setInt(1,did);int rows=ps.executeUpdate();
        if(rows>0){con.commit();actionMsg="Property #"+did+" deleted.";actionType="success";}
        else{con.rollback();actionMsg="Property not found.";actionType="warn";}
    }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
        logError("properties.jsp",e);actionMsg="Delete failed: "+e.getMessage();actionType="danger";
    }finally{closeDB(con,ps,null);}
}

/* ── TOGGLE STATUS ──────────────────────────────────────── */
String toggleId=request.getParameter("toggleId"), toggleStatus=request.getParameter("toggleStatus");
if(toggleId!=null&&toggleStatus!=null&&!toggleId.trim().isEmpty()){
    String newSt="Available".equals(toggleStatus)?"Rented":"Available";
    try{
        int tid=Integer.parseInt(toggleId.trim());
        con=getConnection(); con.setAutoCommit(false);
        ps=con.prepareStatement("UPDATE HOUSE_POST SET STATUS=? WHERE POST_ID=?");
        ps.setString(1,newSt); ps.setInt(2,tid); int rows=ps.executeUpdate();
        if(rows>0){con.commit();actionMsg="Property #"+tid+" status set to "+newSt+".";actionType="success";}
        else{con.rollback();actionMsg="Property not found.";actionType="warn";}
    }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
        logError("properties.jsp",e);actionMsg="Status update failed.";actionType="danger";
    }finally{closeDB(con,ps,null);}
}

/* ── Pagination & Filter ─────────────────────────────────── */
int pageSize=12,currentPage=1;
try{currentPage=Integer.parseInt(request.getParameter("page"));}catch(Exception ig){}
if(currentPage<1)currentPage=1;
int offset=(currentPage-1)*pageSize;
String filterStatus=request.getParameter("status");if(filterStatus==null)filterStatus="";
String searchQ=request.getParameter("q");if(searchQ==null)searchQ="";

List<Map<String,Object>> props=new ArrayList<>();int totalCount=0;
try{
    con=getConnection();
    String base="FROM HOUSE_POST WHERE 1=1"+
        (!filterStatus.isEmpty()?" AND STATUS=?":"")+
        (!searchQ.isEmpty()?" AND (LOWER(ADDRESS) LIKE ? OR LOWER(OWNER_EMAIL) LIKE ?)":"");

    ps=con.prepareStatement("SELECT COUNT(*) "+base);
    int idx=1;
    if(!filterStatus.isEmpty())ps.setString(idx++,filterStatus);
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(idx++,lq);ps.setString(idx++,lq);}
    rs=ps.executeQuery();if(rs.next())totalCount=rs.getInt(1);rs.close();ps.close();

    ps=con.prepareStatement("SELECT POST_ID,ADDRESS,OWNER_EMAIL,PHONE,TOTAL_ROOMS,TOTAL_WASHROOMS,STATUS,CREATED_AT "+base+
        " ORDER BY CREATED_AT DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
    idx=1;
    if(!filterStatus.isEmpty())ps.setString(idx++,filterStatus);
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(idx++,lq);ps.setString(idx++,lq);}
    ps.setInt(idx++,offset);ps.setInt(idx++,pageSize);rs=ps.executeQuery();
    java.text.SimpleDateFormat sdf=new java.text.SimpleDateFormat("dd MMM yyyy");
    while(rs.next()){Map<String,Object> m=new HashMap<>();
        m.put("id",      rs.getInt("POST_ID"));
        m.put("address", rs.getString("ADDRESS"));
        m.put("owner",   rs.getString("OWNER_EMAIL"));
        m.put("phone",   rs.getString("PHONE"));
        m.put("rooms",   rs.getInt("TOTAL_ROOMS"));
        m.put("wash",    rs.getInt("TOTAL_WASHROOMS"));
        String st=rs.getString("STATUS");m.put("status",st!=null?st:"Available");
        java.sql.Timestamp ts=rs.getTimestamp("CREATED_AT");
        m.put("date",ts!=null?sdf.format(ts):"—");
        props.add(m);}
}catch(Exception e){logError("properties.jsp",e);}
finally{closeDB(con,ps,rs);}
int totalPages=(int)Math.ceil((double)totalCount/pageSize);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Properties Management – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head>
<body>
<%@ include file="../admin/nav.jsp" %>

<div class="bv-container">

    <div class="glass bv-page-header">
        <h4>&#127963; Properties Management</h4>
        <p><%= totalCount %> propert<%= totalCount==1?"y":"ies" %> found</p>
    </div>

    <% if(!actionMsg.isEmpty()){ %>
    <div class="bv-alert bv-alert-<%= actionType %>">
        <%= "success".equals(actionType)?"&#10003;":"&#9888;" %> <%= sanitize(actionMsg) %>
    </div>
    <% } %>

    <form method="get" class="glass bv-filter" style="margin-bottom:20px;">
        <input type="text" name="q" class="bv-input" placeholder="&#128269; Search by address or owner..."
               value="<%= sanitize(searchQ) %>" style="flex:2;">
        <select name="status" class="bv-select" style="flex:1;min-width:120px;">
            <option value="">All Status</option>
            <option value="Available" <%= "Available".equals(filterStatus)?"selected":"" %>>Available</option>
            <option value="Rented"    <%= "Rented".equals(filterStatus)   ?"selected":"" %>>Rented</option>
        </select>
        <button type="submit" class="bv-btn bv-btn-primary">Filter</button>
        <a href="properties.jsp" class="bv-btn bv-btn-outline">Reset</a>
    </form>

    <% if(props.isEmpty()){ %>
    <div class="glass bv-empty"><span class="bv-empty-icon">&#127963;</span><h5>No properties found</h5></div>
    <% }else{ %>
    <div class="glass" style="overflow:hidden;">
    <div class="bv-table-wrap">
    <table class="bv-table">
        <thead>
        <tr><th>ID</th><th>Address</th><th>Owner</th><th>Phone</th><th>Rooms</th><th>Wash</th><th>Status</th><th>Listed</th><th>Action</th></tr>
        </thead>
        <tbody>
        <% for(Map<String,Object> p:props){ String st=(String)p.get("status"); %>
        <tr>
            <td>#<%= p.get("id") %></td>
            <td style="max-width:160px;word-break:break-word;">&#128205; <%= sanitize((String)p.get("address")) %></td>
            <td style="font-size:0.8rem;"><%= sanitize((String)p.get("owner")) %></td>
            <td><%= sanitize((String)p.get("phone")) %></td>
            <td><%= p.get("rooms") %></td>
            <td><%= p.get("wash") %></td>
            <td>
                <% if("Rented".equalsIgnoreCase(st)){ %>
                    <span class="bv-badge bv-badge-rented">&#128308; Rented</span>
                <% }else{ %>
                    <span class="bv-badge bv-badge-available">&#128994; Available</span>
                <% } %>
            </td>
            <td style="white-space:nowrap;font-size:0.8rem;"><%= p.get("date") %></td>
            <td>
                <a href="properties.jsp?toggleId=<%= p.get("id") %>&toggleStatus=<%= st %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>&page=<%= currentPage %>"
                   class="bv-btn bv-btn-sm <%= "Rented".equalsIgnoreCase(st)?"bv-btn-toggle-avail":"bv-btn-toggle-rent" %>"
                   onclick="return bvConfirm('Toggle property #<%= p.get("id") %> to <%= "Rented".equalsIgnoreCase(st)?"Available":"Rented" %>?');">
                   <%= "Rented".equalsIgnoreCase(st)?"&#128994; Set Available":"&#128308; Set Rented" %>
                </a>
                <a href="properties.jsp?deleteId=<%= p.get("id") %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>&page=<%= currentPage %>"
                   class="bv-btn bv-btn-danger bv-btn-sm"
                   onclick="return bvConfirm('Delete property #<%= p.get("id") %>?');">&#128465; Delete</a>
            </td>
        </tr>
        <% } %>
        </tbody>
    </table>
    </div>
    </div>
    <% if(totalPages>1){ %>
    <div class="bv-pagination" style="justify-content:center;margin-top:16px;">
        <% if(currentPage>1){ %><a href="properties.jsp?page=<%= currentPage-1 %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>" class="bv-page-btn">&#8249; Prev</a><% } %>
        <% for(int i=1;i<=totalPages;i++){ %><a href="properties.jsp?page=<%= i %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>" class="bv-page-btn <%= i==currentPage?"active":"" %>"><%= i %></a><% } %>
        <% if(currentPage<totalPages){ %><a href="properties.jsp?page=<%= currentPage+1 %>&q=<%= sanitize(searchQ) %>&status=<%= sanitize(filterStatus) %>" class="bv-page-btn">Next &#8250;</a><% } %>
    </div>
    <% } %>
    <% } %>

</div>
<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
