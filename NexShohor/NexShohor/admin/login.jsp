<%-- Admin/adminLogin.jsp — Session guard + login form --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
if ("admin".equalsIgnoreCase((String) session.getAttribute("userType"))) {
    response.sendRedirect(request.getContextPath() + "/NexShohor/admin/home.jsp"); return;
}
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache"); response.setDateHeader("Expires", 0);
String msg = ""; String msgType = "";
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String email = request.getParameter("email");
    String password = request.getParameter("password");
    if (email==null||email.trim().isEmpty()||password==null||password.trim().isEmpty()) {
        msg="Email and password are required."; msgType="danger";
    } else {
        Connection con=null; PreparedStatement ps=null; ResultSet rs=null;
        try {
            con=getConnection();
            ps=con.prepareStatement(
                "SELECT name, email, userType, is_banned FROM nexshohor_users " +
                "WHERE email=? AND password=? AND LOWER(userType)='admin'"
            );
            ps.setString(1,email.trim()); ps.setString(2,password);
            rs=ps.executeQuery();
            if (rs.next()) {
                if (rs.getInt("is_banned")==1) { msg="This admin account has been suspended."; msgType="danger"; }
                else {
                    session.setAttribute("user",      rs.getString("name"));
                    session.setAttribute("userEmail", rs.getString("email"));
                    session.setAttribute("userType",  "admin");
                    response.sendRedirect(request.getContextPath() + "/NexShohor/admin/home.jsp"); return;
                }
            } else { msg="Invalid credentials or insufficient privileges."; msgType="danger"; }
        } catch(Exception e) { logError("Admin/adminlogin.jsp",e); msg="Login error."; msgType="danger"; }
        finally { closeDB(con,ps,rs); }
    }
}
if (msg.isEmpty()) {
    String urlMsg=request.getParameter("msg");
    if ("timeout".equals(urlMsg))  { msg="Session expired. Please log in again."; msgType="warn"; }
    if ("noaccess".equals(urlMsg)) { msg="Admin access required."; msgType="danger"; }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Admin Login — NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.login-wrap { min-height:100vh; display:flex; align-items:center; justify-content:center; padding:24px; }
.login-card { width:100%; max-width:420px; padding:40px 36px; }
.login-brand { text-align:center; margin-bottom:28px; }
.login-brand .icon { font-size:3rem; display:block; margin-bottom:8px; }
.login-brand h2 { font-weight:900; font-size:1.6rem; color:#fff; }
.login-brand p  { color:var(--text-muted); font-size:0.88rem; margin-top:4px; }
.admin-badge {
    display:inline-flex; align-items:center; gap:6px; padding:5px 14px;
    border-radius:20px; font-size:0.78rem; font-weight:700;
    background:rgba(248,113,113,0.12); border:1px solid rgba(248,113,113,0.30);
    color:var(--danger); margin-bottom:20px;
}
.login-divider { text-align:center; color:var(--text-muted); font-size:0.8rem; margin:20px 0; position:relative; }
.login-divider::before,.login-divider::after { content:''; position:absolute; top:50%; width:42%; height:1px; background:var(--glass-bdr); }
.login-divider::before{left:0;} .login-divider::after{right:0;}
</style>
</head>
<body>
<div class="login-wrap">
    <div class="glass login-card">
        <div class="login-brand">
            <span class="icon">&#9881;</span>
            <h2>NexShohor Admin</h2>
            <p>Urban Platform Control Center</p>
        </div>
        <div style="text-align:center;"><span class="admin-badge">&#128274; Admin Access Only</span></div>
        <% if (!msg.isEmpty()) { %><div class="bv-alert bv-alert-<%=msgType%>"><%=sanitize(msg)%></div><% } %>
        <form method="post" id="adminLoginForm" novalidate>
            <div class="bv-form-group">
                <label class="bv-label" for="email">&#128231; Admin Email</label>
                <input type="email" name="email" id="email" class="bv-input" placeholder="admin@basavaraa.com" required>
                <div class="bv-field-error" id="emailErr" style="display:none;">Enter a valid email.</div>
            </div>
            <div class="bv-form-group">
                <label class="bv-label" for="password">&#128274; Password</label>
                <div class="bv-input-group">
                    <input type="password" name="password" id="password" class="bv-input" placeholder="••••••••" required>
                    <button type="button" class="bv-eye-btn" onclick="togglePass()">&#128065;</button>
                </div>
                <div class="bv-field-error" id="passErr" style="display:none;">Password is required.</div>
            </div>
            <button type="submit" class="bv-btn bv-btn-danger bv-btn-w100" style="margin-top:6px;">&#128274; Sign In to Admin Panel</button>
        </form>
        <div class="login-divider">or</div>
        <div style="text-align:center;">
            <a href="../user/login.jsp" class="bv-btn bv-btn-outline bv-btn-sm">&#128100; Regular User Login</a>
        </div>
        <p style="text-align:center;color:var(--text-muted);font-size:0.76rem;margin-top:24px;">&#128272; Unauthorised access is prohibited and logged.</p>
    </div>
</div>
<%@ include file="../includes/scripts.jsp" %>
<script>
function togglePass() {
    const p=document.getElementById('password');
    p.type = p.type==='password' ? 'text' : 'password';
}
document.getElementById('adminLoginForm').addEventListener('submit',function(e){
    let ok=true;
    const em=document.getElementById('email'), pa=document.getElementById('password');
    if (!em.value.trim()||!/\S+@\S+\.\S+/.test(em.value)) {
        em.classList.add('invalid'); document.getElementById('emailErr').style.display='block'; ok=false;
    } else { em.classList.remove('invalid'); document.getElementById('emailErr').style.display='none'; }
    if (!pa.value.trim()) {
        pa.classList.add('invalid'); document.getElementById('passErr').style.display='block'; ok=false;
    } else { pa.classList.remove('invalid'); document.getElementById('passErr').style.display='none'; }
    if (!ok) e.preventDefault();
});
</script>
</body>
</html>
