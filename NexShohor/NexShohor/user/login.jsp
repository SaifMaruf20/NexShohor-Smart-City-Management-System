<%@ page import="java.sql.*,java.security.MessageDigest" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
if (session.getAttribute("user") != null) {
    String t = (String) session.getAttribute("userType");
    if ("Bariwala".equalsIgnoreCase(t))  { response.sendRedirect("../bariwala/home.jsp"); return; }
    if ("Varatia".equalsIgnoreCase(t))   { response.sendRedirect("../varatiya/home.jsp");  return; }
}
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache");
response.setDateHeader("Expires",0);
String errorMsg="",emailVal="",typeVal="";
if ("POST".equalsIgnoreCase(request.getMethod())) {
    typeVal=request.getParameter("userType"); emailVal=request.getParameter("email");
    String rawPw=request.getParameter("password");
    if(typeVal==null||typeVal.trim().isEmpty()) errorMsg="Please select user type.";
    else if(emailVal==null||emailVal.trim().isEmpty()) errorMsg="Email is required.";
    else if(rawPw==null||rawPw.trim().isEmpty()) errorMsg="Password is required.";
    else if(!emailVal.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) errorMsg="Enter a valid email.";
    if(errorMsg.isEmpty()){
        String hashedPw="";
        try{ MessageDigest md=MessageDigest.getInstance("SHA-256"); byte[] hb=md.digest(rawPw.getBytes("UTF-8"));
             StringBuilder sb=new StringBuilder(); for(byte b:hb) sb.append(String.format("%02x",b)); hashedPw=sb.toString();
        }catch(Exception ex){ logError("Login.jsp",ex); errorMsg="Server error."; }
        if(errorMsg.isEmpty()){
            Connection con=null; PreparedStatement ps=null; ResultSet rs=null;
            try{
                con=getConnection();
                ps=con.prepareStatement("SELECT id,name,userType,email,is_banned,ban_reason FROM nexshohor_users WHERE email=? AND password=? AND userType=?");
                ps.setString(1,emailVal.trim().toLowerCase()); ps.setString(2,hashedPw); ps.setString(3,typeVal.trim());
                rs=ps.executeQuery();
                if(rs.next()){
                    int isBanned=rs.getInt("is_banned");
                    if(isBanned==1){
                        String br=rs.getString("ban_reason");
                        errorMsg="Your account has been suspended. Reason: "+(br!=null&&!br.isEmpty()?br:"Violation of terms.");
                    } else {
                        session.invalidate(); session=request.getSession(true); session.setMaxInactiveInterval(1800);
                        session.setAttribute("userId",rs.getInt("id")); session.setAttribute("user",rs.getString("name"));
                        session.setAttribute("userType",rs.getString("userType")); session.setAttribute("userEmail",rs.getString("email"));
                        if("Bariwala".equalsIgnoreCase(typeVal)){response.sendRedirect("../bariwala/home.jsp");return;}
                        else{response.sendRedirect("../varatiya/home.jsp");return;}
                    }
                } else { errorMsg="Invalid email, password, or user type."; }
            }catch(Exception e){ logError("Login.jsp",e); errorMsg="A server error occurred."; }
            finally{ closeDB(con,ps,rs); }
        }
    }
}
%>
<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NexShohor · Login</title>
<%@ include file="../includes/styles.jsp" %>
<style>body{display:flex;align-items:center;justify-content:center;min-height:100vh;padding:20px;}
.login-card{width:100%;max-width:420px;} .login-logo{text-align:center;margin-bottom:24px;}
.login-logo h2{font-size:1.9rem;font-weight:900;color:#fff;} .login-logo span{color:var(--accent);}
.login-logo p{color:var(--text-muted);font-size:0.88rem;margin-top:4px;}</style>
</head><body>
<div class="glass bv-form-card login-card" style="margin:0;">
    <div class="login-logo"><h2>Basa<span>Vara</span></h2><p>House Rental Management System</p></div>
    <%if(!errorMsg.isEmpty()){%><div class="bv-alert bv-alert-danger">&#9888; <%=sanitize(errorMsg)%></div><%}%>
    <%String regMsg=request.getParameter("msg"); if("success".equals(regMsg)){%>
    <div class="bv-alert bv-alert-success">&#10003; Registration successful! Please log in.</div><%}%>
    <%if("1".equals(request.getParameter("banned"))){%>
    <div class="bv-alert bv-alert-danger">&#128683; Your account has been suspended. Contact admin for support.</div><%}%>
    <form method="post" onsubmit="return bvValidate(this);" novalidate>
        <div class="bv-form-group"><label class="bv-label">User Type <span class="bv-required">*</span></label>
            <select name="userType" class="bv-select" data-required>
                <option value="">— Select type —</option>
                <option value="Bariwala" <%="Bariwala".equals(typeVal)?"selected":""%>>Bariwala (Landlord)</option>
                <option value="Varatia"  <%="Varatia".equals(typeVal) ?"selected":""%>>Varatia (Tenant)</option>
            </select><div class="bv-field-error">Please select user type.</div></div>
        <div class="bv-form-group"><label class="bv-label">Email <span class="bv-required">*</span></label>
            <input type="email" name="email" class="bv-input" placeholder="you@example.com" value="<%=sanitize(emailVal)%>" data-required data-email>
            <div class="bv-field-error">Enter a valid email.</div></div>
        <div class="bv-form-group"><label class="bv-label">Password <span class="bv-required">*</span></label>
            <div class="bv-input-group">
                <input type="password" name="password" id="bvPw" class="bv-input" placeholder="••••••" data-required>
                <button type="button" class="bv-eye-btn" onclick="bvTogglePw('bvPw')">&#128065;</button>
            </div><div class="bv-field-error">Password is required.</div></div>
        <button type="submit" class="bv-btn bv-btn-blue bv-btn-w100" style="margin-top:8px;">&#128682; Login</button>
    </form>
    <p style="text-align:center;margin-top:20px;color:var(--text-muted);font-size:0.88rem;">
        Don't have an account? <a href="register.jsp" style="color:var(--accent);">Register here</a></p>
</div>
<%@ include file="../includes/scripts.jsp" %>
</body></html>
