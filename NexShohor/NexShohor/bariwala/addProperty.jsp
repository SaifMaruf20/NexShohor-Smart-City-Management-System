<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
String _requiredRole = "Bariwala";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String ownerEmail = _sessionEmail;
String ownerPhone = "";
String successMsg = "";
String errorMsg   = "";

// Pre-fill owner phone from DB
Connection con = null; PreparedStatement ps = null; ResultSet rs = null;
try {
    con = getConnection();
    ps  = con.prepareStatement("SELECT phone FROM nexshohor_users WHERE email=?");
    ps.setString(1, ownerEmail); rs = ps.executeQuery();
    if (rs.next()) ownerPhone = rs.getString("phone") != null ? rs.getString("phone") : "";
} catch(Exception e) { logError("AddHouse.jsp", e); }
finally { closeDB(con, ps, rs); }

/* ── POST: insert new house ───────────────────────────────── */
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String phone    = request.getParameter("phone");
    String address  = request.getParameter("address");
    String roomsStr = request.getParameter("rooms");
    String washStr  = request.getParameter("washrooms");
    String desc     = request.getParameter("description");
    String video    = request.getParameter("videoLink");

    // Validation
    if (phone   == null || phone.trim().isEmpty())   errorMsg = "Phone is required.";
    else if (!phone.trim().matches("^01[3-9]\\d{8}$")) errorMsg = "Invalid phone (01XXXXXXXXX).";
    else if (address == null || address.trim().isEmpty()) errorMsg = "Address is required.";
    else if (roomsStr == null || roomsStr.trim().isEmpty()) errorMsg = "Total rooms is required.";

    if (errorMsg.isEmpty()) {
        try {
            int rooms = Integer.parseInt(roomsStr.trim());
            int wash  = (washStr != null && !washStr.trim().isEmpty()) ? Integer.parseInt(washStr.trim()) : 0;
            if (rooms < 1) { errorMsg = "Rooms must be at least 1."; }
            else {
                con = getConnection();
                con.setAutoCommit(false);
                ps  = con.prepareStatement(
                    "INSERT INTO HOUSE_POST(OWNER_EMAIL,PHONE,ADDRESS,TOTAL_ROOMS,TOTAL_WASHROOMS,DESCRIPTION,VIDEO_LINK) " +
                    "VALUES(?,?,?,?,?,?,?)");
                ps.setString(1, ownerEmail);
                ps.setString(2, phone.trim());
                ps.setString(3, address.trim());
                ps.setInt   (4, rooms);
                ps.setInt   (5, wash);
                ps.setString(6, (desc != null && !desc.trim().isEmpty()) ? desc.trim() : null);
                ps.setString(7, (video!= null && !video.trim().isEmpty()) ? video.trim() : null);
                ps.executeUpdate();
                con.commit();
                successMsg = "House posted successfully!";
            }
        } catch(NumberFormatException nfe) {
            errorMsg = "Rooms/Washrooms must be valid numbers.";
        } catch(Exception e) {
            if (con != null) try { con.rollback(); } catch(Exception ig){}
            logError("AddHouse.jsp", e);
            errorMsg = "Database error. Please try again.";
        } finally { closeDB(con, ps, null); }
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Add House – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head>
<body>
<%@ include file="../bariwala/nav.jsp" %>

<div class="bv-container">
<div class="glass bv-form-card" style="max-width:640px;">

    <div style="margin-bottom:22px;">
        <h4 style="color:#fff; font-weight:800;">&#127968; Post a New Property</h4>
        <p style="color:var(--text-muted); font-size:0.88rem;">Fill in the details to list your property.</p>
    </div>

    <% if (!successMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-success">&#10003; <%= sanitize(successMsg) %>
        <span style="float:right;"><a href="manageHouse.jsp" style="color:inherit;">View listings &#8594;</a></span>
    </div>
    <% } %>
    <% if (!errorMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-danger">&#9888; <%= sanitize(errorMsg) %></div>
    <% } %>

    <form method="post" onsubmit="return bvValidate(this);" novalidate>

        <div class="bv-form-group">
            <label class="bv-label">Owner Email</label>
            <input type="email" class="bv-input" value="<%= sanitize(ownerEmail) %>" readonly
                   style="opacity:0.6; cursor:not-allowed;">
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Contact Phone <span class="bv-required">*</span></label>
            <input type="text" name="phone" class="bv-input" placeholder="01XXXXXXXXX"
                   value="<%= sanitize(ownerPhone) %>" data-required data-phone maxlength="11">
            <div class="bv-field-error">Enter valid BD phone (01XXXXXXXXX).</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Property Address <span class="bv-required">*</span></label>
            <input type="text" name="address" class="bv-input" placeholder="e.g. House 12, Road 3, Dhanmondi, Dhaka"
                   data-required maxlength="255">
            <div class="bv-field-error">Address is required.</div>
        </div>

        <div style="display:grid; grid-template-columns:1fr 1fr; gap:14px;">
            <div class="bv-form-group">
                <label class="bv-label">Total Rooms <span class="bv-required">*</span></label>
                <input type="number" name="rooms" class="bv-input" placeholder="e.g. 3" min="1" data-required>
                <div class="bv-field-error">Enter rooms count.</div>
            </div>
            <div class="bv-form-group">
                <label class="bv-label">Total Washrooms</label>
                <input type="number" name="washrooms" class="bv-input" placeholder="e.g. 2" min="0">
            </div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Description</label>
            <textarea name="description" class="bv-textarea" rows="4"
                      placeholder="Describe the property — floor, furnishing, nearby areas..."></textarea>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">YouTube Video Link <small style="color:var(--text-muted)">(optional)</small></label>
            <input type="text" name="videoLink" class="bv-input" placeholder="https://youtube.com/...">
        </div>

        <div style="display:flex; gap:12px; margin-top:4px;">
            <button type="submit" class="bv-btn bv-btn-primary" style="flex:2;">&#128228; Post Property</button>
            <a href="BaBody.jsp" class="bv-btn bv-btn-outline" style="flex:1;text-align:center;">&#8592; Back</a>
        </div>

    </form>
</div>
</div>

<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
