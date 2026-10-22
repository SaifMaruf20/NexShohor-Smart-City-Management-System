<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
String _requiredRole = "Varatia";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String tenantName  = _sessionUser;
String tenantEmail = _sessionEmail;

/* ── Validate postId parameter ───────────────────────────── */
String postIdParam = request.getParameter("postId");
String address     = request.getParameter("address");
if (address == null) address = "";

if (postIdParam == null || postIdParam.trim().isEmpty()) {
    response.sendRedirect("browseProperties.jsp"); return;
}
int postId;
try { postId = Integer.parseInt(postIdParam.trim()); }
catch(NumberFormatException nfe) { response.sendRedirect("browseProperties.jsp"); return; }

/* ── Pre-fill tenant phone from DB ───────────────────────── */
String tenantPhone = "";
Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    ps  = con.prepareStatement("SELECT phone FROM nexshohor_users WHERE email=?");
    ps.setString(1, tenantEmail); rs = ps.executeQuery();
    if (rs.next()) tenantPhone = rs.getString("phone") != null ? rs.getString("phone") : "";
} catch(Exception e) { logError("submitRequest.jsp", e); }
finally { closeDB(con, ps, rs); }

String successMsg = "";
String errorMsg   = "";

/* ── Handle POST ─────────────────────────────────────────── */
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String reqType  = request.getParameter("requestType");
    String desc     = request.getParameter("description");
    String phoneIn  = request.getParameter("phone");

    // Server-side validation
    if (reqType == null || reqType.trim().isEmpty())  errorMsg = "Please select a request type.";
    else if (phoneIn == null || !phoneIn.trim().matches("^01[3-9]\\d{8}$")) errorMsg = "Invalid phone number (01XXXXXXXXX).";

    if (errorMsg.isEmpty()) {
        try {
            con = getConnection();
            con.setAutoCommit(false);

            // 1. Verify property is still Available
            ps = con.prepareStatement(
                "SELECT STATUS FROM HOUSE_POST WHERE POST_ID=?");
            ps.setInt(1, postId); rs = ps.executeQuery();
            boolean available = false;
            if (rs.next()) available = "Available".equalsIgnoreCase(rs.getString("STATUS"));
            else errorMsg = "Property not found.";
            rs.close(); ps.close();

            // 2. Check for duplicate pending request
            if (errorMsg.isEmpty() && available) {
                ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM TENANT_REQUESTS " +
                    "WHERE POST_ID=? AND TENANT_EMAIL=? AND STATUS='Pending'");
                ps.setInt(1, postId); ps.setString(2, tenantEmail);
                rs = ps.executeQuery();
                if (rs.next() && rs.getInt(1) > 0)
                    errorMsg = "You already have a pending request for this property.";
                rs.close(); ps.close();
            } else if (!available && errorMsg.isEmpty()) {
                errorMsg = "Sorry, this property has already been rented.";
            }

            // 3. Insert request
            if (errorMsg.isEmpty()) {
                ps = con.prepareStatement(
                    "INSERT INTO TENANT_REQUESTS(POST_ID,TENANT_EMAIL,TENANT_NAME,TENANT_PHONE,REQUEST_TYPE,DESCRIPTION) " +
                    "VALUES(?,?,?,?,?,?)");
                ps.setInt   (1, postId);
                ps.setString(2, tenantEmail);
                ps.setString(3, tenantName);
                ps.setString(4, phoneIn.trim());
                ps.setString(5, reqType.trim());
                ps.setString(6, (desc != null && !desc.trim().isEmpty()) ? desc.trim() : null);
                ps.executeUpdate();
                con.commit();
                successMsg = "Your request has been submitted successfully!";
            } else {
                con.rollback();
            }

        } catch(Exception e) {
            if (con!=null) try{con.rollback();}catch(Exception ig){}
            logError("submitRequest.jsp", e);
            errorMsg = "Server error. Please try again.";
        } finally {
            closeDB(con, ps, rs);
        }
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Submit Request – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
<style>
.readonly-fld { opacity:0.55; cursor:not-allowed; }
</style>
</head>
<body>
<%@ include file="../varatiya/nav.jsp" %>

<div class="bv-container">
<div class="glass bv-form-card" style="max-width:600px;">

    <div style="background:linear-gradient(135deg,var(--accent-dark),var(--accent));
                border-radius:10px; padding:18px 22px; margin-bottom:24px;">
        <h5 style="color:#000;font-weight:700;margin:0;">&#128228; Submit Rental Request</h5>
        <% if (!address.isEmpty()) { %>
        <p style="color:rgba(0,0,0,0.75);font-size:0.88rem;margin-top:4px;margin-bottom:0;">
            &#128205; <%= sanitize(address) %>
        </p>
        <% } %>
    </div>

    <% if (!successMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-success">
        &#10003; <%= sanitize(successMsg) %>
        <div style="margin-top:10px;display:flex;gap:10px;">
            <a href="myRequests.jsp"      class="bv-btn bv-btn-primary bv-btn-sm">View My Requests</a>
            <a href="browse.jsp" class="bv-btn bv-btn-outline bv-btn-sm">Browse More</a>
        </div>
    </div>
    <% } %>

    <% if (!errorMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-danger">&#9888; <%= sanitize(errorMsg) %></div>
    <% } %>

    <% if (successMsg.isEmpty()) { %>
    <form method="post" onsubmit="return bvValidate(this);" novalidate>
        <input type="hidden" name="postId" value="<%= postId %>">

        <div class="bv-form-group">
            <label class="bv-label">Your Name</label>
            <input type="text" class="bv-input readonly-fld" value="<%= sanitize(tenantName) %>" readonly>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Your Email</label>
            <input type="email" class="bv-input readonly-fld" value="<%= sanitize(tenantEmail) %>" readonly>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Phone Number <span class="bv-required">*</span></label>
            <input type="text" name="phone" class="bv-input" placeholder="01XXXXXXXXX"
                   value="<%= sanitize(tenantPhone) %>" data-required data-phone maxlength="11">
            <div class="bv-field-error">Enter valid BD phone (01XXXXXXXXX).</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Request Type <span class="bv-required">*</span></label>
            <select name="requestType" class="bv-select" data-required>
                <option value="">— Select Type —</option>
                <option value="Rent Application">Rent Application</option>
                <option value="Rent Inquiry">Rent Inquiry</option>
                <option value="Visit Request">Visit Request</option>
                <option value="Negotiation">Negotiation</option>
            </select>
            <div class="bv-field-error">Select a request type.</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Message / Description <small style="color:var(--text-muted)">(optional)</small></label>
            <textarea name="description" class="bv-textarea" rows="4"
                      placeholder="Any additional details or requirements..."></textarea>
        </div>

        <div style="display:flex;gap:12px;margin-top:4px;">
            <button type="submit" class="bv-btn bv-btn-primary" style="flex:2;">&#128228; Submit Request</button>
            <a href="browse.jsp" class="bv-btn bv-btn-outline" style="flex:1;text-align:center;">&#8592; Back</a>
        </div>

    </form>
    <% } %>

</div>
</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
