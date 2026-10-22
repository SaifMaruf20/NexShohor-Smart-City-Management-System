<%@ page import="java.sql.*,java.security.MessageDigest" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
response.setHeader("Cache-Control","no-cache, no-store, must-revalidate");
response.setHeader("Pragma","no-cache");
response.setDateHeader("Expires",0);

String errorMsg  = "";
String typeVal   = "";
String nameVal   = "";
String phoneVal  = "";
String emailVal  = "";
String bdateVal  = "";

if ("POST".equalsIgnoreCase(request.getMethod())) {

    typeVal  = request.getParameter("userType");
    nameVal  = request.getParameter("name");
    phoneVal = request.getParameter("phone");
    emailVal = request.getParameter("email");
    bdateVal = request.getParameter("birthdate");
    String rawPw  = request.getParameter("password");
    String confPw = request.getParameter("confirmPassword");

    /* ── Server-side validation ───────────────────────── */
    if (typeVal  == null || typeVal.trim().isEmpty())  errorMsg = "Select user type.";
    else if (nameVal  == null || nameVal.trim().isEmpty()) errorMsg = "Full name is required.";
    else if (phoneVal == null || !phoneVal.trim().matches("^01[3-9]\\d{8}$")) errorMsg = "Enter a valid BD phone (01XXXXXXXXX).";
    else if (emailVal == null || !emailVal.trim().matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) errorMsg = "Enter a valid email.";
    else if (bdateVal == null || bdateVal.trim().isEmpty()) errorMsg = "Birthdate is required.";
    else if (rawPw    == null || rawPw.length() < 6) errorMsg = "Password must be at least 6 characters.";
    else if (!rawPw.equals(confPw)) errorMsg = "Passwords do not match.";

    if (errorMsg.isEmpty()) {
        /* ── Hash password SHA-256 ────────────────────── */
        String hashedPw = "";
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hb = md.digest(rawPw.getBytes("UTF-8"));
            StringBuilder sb = new StringBuilder();
            for (byte b : hb) sb.append(String.format("%02x", b));
            hashedPw = sb.toString();
        } catch (Exception ex) {
            logError("Register.jsp", ex);
            errorMsg = "Server error. Please try again.";
        }

        if (errorMsg.isEmpty()) {
            Connection con = null; PreparedStatement ps = null;
            try {
                con = getConnection();
                ps  = con.prepareStatement(
                    "INSERT INTO nexshohor_users(userType,name,phone,email,birthdate,password) " +
                    "VALUES(?,?,?,?,?,?)");
                ps.setString(1, typeVal.trim());
                ps.setString(2, nameVal.trim());
                ps.setString(3, phoneVal.trim());
                ps.setString(4, emailVal.trim().toLowerCase());
                ps.setDate  (5, java.sql.Date.valueOf(bdateVal.trim()));
                ps.setString(6, hashedPw);
                ps.executeUpdate();
                response.sendRedirect("login.jsp?msg=success");
                return;
            } catch (SQLException e) {
                if (e.getErrorCode() == 1) errorMsg = "This email is already registered. Try logging in.";
                else if (e.getErrorCode() == 2290) errorMsg = "Invalid phone format. Must be 01XXXXXXXXX.";
                else { logError("Register.jsp", e); errorMsg = "Registration failed: " + e.getMessage(); }
            } catch (Exception e) {
                logError("Register.jsp", e);
                errorMsg = "Server error. Please try again.";
            } finally {
                closeDB(con, ps, null);
            }
        }
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NexShohor · Register</title>
<%@ include file="../includes/styles.jsp" %>
<style>
body { display:flex; align-items:center; justify-content:center; min-height:100vh; padding:24px 20px; }
.reg-logo { text-align:center; margin-bottom:22px; }
.reg-logo h2 { font-size:1.8rem; font-weight:900; color:#fff; }
.reg-logo span { color:var(--accent); }
.reg-logo p { color:var(--text-muted); font-size:0.86rem; margin-top:4px; }
</style>
</head>
<body>
<div class="glass bv-form-card" style="width:100%;max-width:480px;margin:0;">

    <div class="reg-logo">
        <h2>Basa<span>Vara</span></h2>
        <p>Create your account</p>
    </div>

    <% if (!errorMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-danger">&#9888; <%= sanitize(errorMsg) %></div>
    <% } %>

    <form method="post" onsubmit="return bvValidate(this);" novalidate>

        <div class="bv-form-group">
            <label class="bv-label">User Type <span class="bv-required">*</span></label>
            <select name="userType" class="bv-select" data-required>
                <option value="">— Select type —</option>
                <option value="Bariwala" <%= "Bariwala".equals(typeVal)?"selected":"" %>>Bariwala (Landlord)</option>
                <option value="Varatia"  <%= "Varatia".equals(typeVal) ?"selected":"" %>>Varatia (Tenant)</option>
            </select>
            <div class="bv-field-error">Select user type.</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Full Name <span class="bv-required">*</span></label>
            <input type="text" name="name" class="bv-input" placeholder="Your full name"
                   value="<%= sanitize(nameVal) %>" data-required maxlength="100">
            <div class="bv-field-error">Name is required.</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Phone Number <span class="bv-required">*</span></label>
            <input type="text" name="phone" class="bv-input" placeholder="01XXXXXXXXX"
                   value="<%= sanitize(phoneVal) %>" data-required data-phone maxlength="11">
            <div class="bv-field-error">Enter valid BD phone (01XXXXXXXXX).</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Email <span class="bv-required">*</span></label>
            <input type="email" name="email" class="bv-input" placeholder="you@example.com"
                   value="<%= sanitize(emailVal) %>" data-required data-email maxlength="100">
            <div class="bv-field-error">Enter a valid email.</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Date of Birth <span class="bv-required">*</span></label>
            <input type="date" name="birthdate" class="bv-input"
                   value="<%= sanitize(bdateVal) %>" data-required>
            <div class="bv-field-error">Birthdate is required.</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Password <span class="bv-required">*</span> <small style="color:var(--text-muted)">(min 6 chars)</small></label>
            <div class="bv-input-group">
                <input type="password" name="password" id="bvPw" class="bv-input"
                       placeholder="Min 6 characters" data-required data-pw>
                <button type="button" class="bv-eye-btn" onclick="bvTogglePw('bvPw')">&#128065;</button>
            </div>
            <div class="bv-field-error">Password must be at least 6 characters.</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Confirm Password <span class="bv-required">*</span></label>
            <input type="password" name="confirmPassword" id="bvCpw" class="bv-input"
                   placeholder="Repeat password" data-required data-cpw>
            <div class="bv-field-error">Passwords do not match.</div>
        </div>

        <button type="submit" class="bv-btn bv-btn-primary bv-btn-w100" style="margin-top:6px;">
            &#128100; Create Account
        </button>
    </form>

    <p style="text-align:center; margin-top:18px; color:var(--text-muted); font-size:0.87rem;">
        Already have an account?
        <a href="login.jsp" style="color:var(--accent);">Login here</a>
    </p>

</div>
<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
