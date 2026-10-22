<%@ page import="java.sql.*,java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache");
response.setDateHeader("Expires",0);

String actionMsg="", actionType="";
Connection con=null; PreparedStatement ps=null; ResultSet rs=null;

/* ── DELETE ───────────────────────────────────────────────── */
String deleteId=request.getParameter("deleteId");
if(deleteId!=null&&!deleteId.trim().isEmpty()){
    try{
        int did=Integer.parseInt(deleteId.trim());
        con=getConnection(); con.setAutoCommit(false);
        ps=con.prepareStatement("DELETE FROM nexshohor_users WHERE id=? AND userType='Varatia'");
        ps.setInt(1,did); int rows=ps.executeUpdate();
        if(rows>0){con.commit();actionMsg="User #"+did+" deleted.";actionType="success";}
        else{con.rollback();actionMsg="User not found.";actionType="warn";}
    }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
        logError("varatia.jsp",e);actionMsg="Delete failed.";actionType="danger";
    }finally{closeDB(con,ps,null);}
}

/* ── UPDATE ───────────────────────────────────────────────── */
String updateId=request.getParameter("updateId");
if(updateId!=null&&request.getParameter("name")!=null){
    String nm=request.getParameter("name"),ph=request.getParameter("phone"),em=request.getParameter("email");
    if(nm==null||nm.trim().isEmpty()){actionMsg="Name required.";actionType="danger";}
    else if(ph==null||!ph.trim().matches("^01[3-9]\\d{8}$")){actionMsg="Invalid phone.";actionType="danger";}
    else if(em==null||!em.trim().matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")){actionMsg="Invalid email.";actionType="danger";}
    else{
        try{
            int uid=Integer.parseInt(updateId.trim());
            con=getConnection();con.setAutoCommit(false);
            ps=con.prepareStatement("UPDATE nexshohor_users SET name=?,phone=?,email=? WHERE id=? AND userType='Varatia'");
            ps.setString(1,nm.trim());ps.setString(2,ph.trim());ps.setString(3,em.trim().toLowerCase());ps.setInt(4,uid);
            int rows=ps.executeUpdate();
            if(rows>0){con.commit();actionMsg="User #"+uid+" updated.";actionType="success";}
            else{con.rollback();actionMsg="User not found.";actionType="warn";}
        }catch(Exception e){if(con!=null)try{con.rollback();}catch(Exception ig){}
            logError("varatia.jsp",e);actionMsg="Update failed: "+e.getMessage();actionType="danger";
        }finally{closeDB(con,ps,null);}
    }
}

/* ── Pagination & Search ─────────────────────────────────── */
int pageSize=10,currentPage=1;
try{currentPage=Integer.parseInt(request.getParameter("page"));}catch(Exception ig){}
if(currentPage<1)currentPage=1;
int offset=(currentPage-1)*pageSize;
String searchQ=request.getParameter("q");if(searchQ==null)searchQ="";
List<Map<String,Object>> users=new ArrayList<>();int totalCount=0;

try{
    con=getConnection();
    String base="FROM nexshohor_users WHERE userType='Varatia'"+
        (!searchQ.isEmpty()?" AND (LOWER(name) LIKE ? OR LOWER(email) LIKE ?)":"");
    ps=con.prepareStatement("SELECT COUNT(*) "+base);
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(1,lq);ps.setString(2,lq);}
    rs=ps.executeQuery();if(rs.next())totalCount=rs.getInt(1);rs.close();ps.close();

    ps=con.prepareStatement("SELECT id,name,phone,email,TO_CHAR(birthdate,'DD Mon YYYY') AS bdate "+base+
        " ORDER BY id DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
    int idx=1;
    if(!searchQ.isEmpty()){String lq="%"+searchQ.toLowerCase()+"%";ps.setString(idx++,lq);ps.setString(idx++,lq);}
    ps.setInt(idx++,offset);ps.setInt(idx++,pageSize);rs=ps.executeQuery();
    while(rs.next()){Map<String,Object> m=new HashMap<>();
        m.put("id",rs.getInt("id"));m.put("name",rs.getString("name"));
        m.put("phone",rs.getString("phone"));m.put("email",rs.getString("email"));m.put("bdate",rs.getString("bdate"));
        users.add(m);}
}catch(Exception e){logError("varatia.jsp",e);}
finally{closeDB(con,ps,rs);}
int totalPages=(int)Math.ceil((double)totalCount/pageSize);

String editId=request.getParameter("editId");
Map<String,Object> editUser=null;
if(editId!=null&&!editId.trim().isEmpty()){
    try{con=getConnection();ps=con.prepareStatement("SELECT id,name,phone,email FROM nexshohor_users WHERE id=? AND userType='Varatia'");
        ps.setInt(1,Integer.parseInt(editId.trim()));rs=ps.executeQuery();
        if(rs.next()){editUser=new HashMap<>();editUser.put("id",rs.getInt("id"));editUser.put("name",rs.getString("name"));
            editUser.put("phone",rs.getString("phone"));editUser.put("email",rs.getString("email"));}
    }catch(Exception e){logError("varatia.jsp",e);}finally{closeDB(con,ps,rs);}
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Varatia Management – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head>
<body>
<%@ include file="../admin/nav.jsp" %>

<div class="bv-container">

    <div class="glass bv-page-header">
        <h4>&#128101; Varatia Management</h4>
        <p><%= totalCount %> tenant<%= totalCount==1?"":"s" %> registered</p>
    </div>

    <% if(!actionMsg.isEmpty()){ %>
    <div class="bv-alert bv-alert-<%= actionType %>">
        <%= "success".equals(actionType)?"&#10003;":"&#9888;" %> <%= sanitize(actionMsg) %>
    </div>
    <% } %>

    <form method="get" class="glass bv-filter" style="margin-bottom:20px;">
        <input type="text" name="q" class="bv-input" placeholder="&#128269; Search..."
               value="<%= sanitize(searchQ) %>" style="flex:1;">
        <button type="submit" class="bv-btn bv-btn-primary">Search</button>
        <a href="varatia.jsp" class="bv-btn bv-btn-outline">Reset</a>
    </form>

    <% if(editUser!=null){ %>
    <div class="glass" style="padding:24px;margin-bottom:24px;">
        <h5 style="color:#fff;font-weight:700;margin-bottom:16px;">&#9998; Edit Varatia #<%= editUser.get("id") %></h5>
        <form method="post" onsubmit="return bvValidate(this);" novalidate>
            <input type="hidden" name="updateId" value="<%= editUser.get("id") %>">
            <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;">
                <div class="bv-form-group">
                    <label class="bv-label">Name <span class="bv-required">*</span></label>
                    <input type="text" name="name" class="bv-input" value="<%= sanitize((String)editUser.get("name")) %>" data-required>
                    <div class="bv-field-error">Name required.</div>
                </div>
                <div class="bv-form-group">
                    <label class="bv-label">Phone <span class="bv-required">*</span></label>
                    <input type="text" name="phone" class="bv-input" value="<%= sanitize((String)editUser.get("phone")) %>" data-required data-phone>
                    <div class="bv-field-error">Invalid phone.</div>
                </div>
                <div class="bv-form-group">
                    <label class="bv-label">Email <span class="bv-required">*</span></label>
                    <input type="email" name="email" class="bv-input" value="<%= sanitize((String)editUser.get("email")) %>" data-required data-email>
                    <div class="bv-field-error">Invalid email.</div>
                </div>
            </div>
            <div style="display:flex;gap:10px;">
                <button type="submit" class="bv-btn bv-btn-primary">&#128190; Save</button>
                <a href="varatia.jsp" class="bv-btn bv-btn-outline">&#10005; Cancel</a>
            </div>
        </form>
    </div>
    <% } %>

    <% if(users.isEmpty()){ %>
    <div class="glass bv-empty"><span class="bv-empty-icon">&#128101;</span><h5>No Varatia users found</h5></div>
    <% }else{ %>
    <div class="glass" style="overflow:hidden;">
    <div class="bv-table-wrap">
    <table class="bv-table">
        <thead><tr><th>ID</th><th>Name</th><th>Phone</th><th>Email</th><th>Birthdate</th><th>Actions</th></tr></thead>
        <tbody>
        <% for(Map<String,Object> u:users){ %>
        <tr>
            <td>#<%= u.get("id") %></td>
            <td><%= sanitize((String)u.get("name")) %></td>
            <td><%= sanitize((String)u.get("phone")) %></td>
            <td><%= sanitize((String)u.get("email")) %></td>
            <td><%= u.get("bdate") %></td>
            <td>
                <a href="varatia.jsp?editId=<%= u.get("id") %>&q=<%= sanitize(searchQ) %>&page=<%= currentPage %>" class="bv-btn bv-btn-warn bv-btn-sm">&#9998; Edit</a>
                <a href="varatia.jsp?deleteId=<%= u.get("id") %>&q=<%= sanitize(searchQ) %>&page=<%= currentPage %>"
                   class="bv-btn bv-btn-danger bv-btn-sm" onclick="return bvConfirm('Delete user #<%= u.get("id") %>?');">&#128465; Delete</a>
                <a href="bannedUsers.jsp" class="bv-btn bv-btn-sm" style="background:rgba(248,113,113,0.25);border:1px solid var(--danger);color:var(--danger);">&#128683; Ban</a>
            </td>
        </tr>
        <% } %>
        </tbody>
    </table>
    </div>
    </div>
    <% if(totalPages>1){ %>
    <div class="bv-pagination" style="justify-content:center;margin-top:16px;">
        <% if(currentPage>1){ %><a href="varatia.jsp?page=<%= currentPage-1 %>&q=<%= sanitize(searchQ) %>" class="bv-page-btn">&#8249;</a><% } %>
        <% for(int i=1;i<=totalPages;i++){ %><a href="varatia.jsp?page=<%= i %>&q=<%= sanitize(searchQ) %>" class="bv-page-btn <%= i==currentPage?"active":"" %>"><%= i %></a><% } %>
        <% if(currentPage<totalPages){ %><a href="varatia.jsp?page=<%= currentPage+1 %>&q=<%= sanitize(searchQ) %>" class="bv-page-btn">&#8250;</a><% } %>
    </div>
    <% } %>
    <% } %>

</div>
<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
