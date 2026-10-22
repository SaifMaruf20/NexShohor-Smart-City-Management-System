<%@ page import="java.sql.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="../includes/db.jsp" %>
<%
String _requiredRole = "Bariwala";
%>
<%@ include file="../includes/sessionGuard.jsp" %>
<%
String ownerEmail = _sessionEmail;
String idParam = request.getParameter("id");
if (idParam == null || idParam.trim().isEmpty()) { response.sendRedirect("manageHouse.jsp"); return; }

int postId;
try { postId = Integer.parseInt(idParam.trim()); }
catch(NumberFormatException nfe) { response.sendRedirect("manageHouse.jsp"); return; }

String successMsg = "";
String errorMsg   = "";
String phone="", address="", description="", videoLink="";
int totalRooms=1, totalWash=0;

Connection con = null; PreparedStatement ps = null; ResultSet rs = null;

/* ── POST: update ──────────────────────────────────────────── */
if ("POST".equalsIgnoreCase(request.getMethod())) {
    phone       = request.getParameter("phone");
    address     = request.getParameter("address");
    String rStr = request.getParameter("rooms");
    String wStr = request.getParameter("washrooms");
    description = request.getParameter("description");
    videoLink   = request.getParameter("videoLink");

    if (phone   == null || !phone.trim().matches("^01[3-9]\\d{8}$")) errorMsg="Invalid phone format.";
    else if (address == null || address.trim().isEmpty()) errorMsg="Address is required.";
    else if (rStr == null || rStr.trim().isEmpty()) errorMsg="Rooms is required.";

    if (errorMsg.isEmpty()) {
        try {
            totalRooms = Integer.parseInt(rStr.trim());
            totalWash  = (wStr!=null&&!wStr.trim().isEmpty()) ? Integer.parseInt(wStr.trim()) : 0;
            if (totalRooms < 1) { errorMsg="Rooms must be at least 1."; }
            else {
                con = getConnection(); con.setAutoCommit(false);
                ps  = con.prepareStatement(
                    "UPDATE HOUSE_POST SET PHONE=?,ADDRESS=?,TOTAL_ROOMS=?,TOTAL_WASHROOMS=?," +
                    "DESCRIPTION=?,VIDEO_LINK=? WHERE POST_ID=? AND OWNER_EMAIL=?");
                ps.setString(1, phone.trim());
                ps.setString(2, address.trim());
                ps.setInt   (3, totalRooms);
                ps.setInt   (4, totalWash);
                ps.setString(5, (description!=null&&!description.trim().isEmpty())?description.trim():null);
                ps.setString(6, (videoLink  !=null&&!videoLink.trim().isEmpty())  ?videoLink.trim()  :null);
                ps.setInt   (7, postId);
                ps.setString(8, ownerEmail);
                int rows = ps.executeUpdate();
                if (rows > 0) { con.commit(); successMsg="Property updated successfully!"; }
                else { con.rollback(); errorMsg="Update failed — property not found or not yours."; }
            }
        } catch(Exception e) {
            if(con!=null) try{con.rollback();}catch(Exception ig){}
            logError("editHouse.jsp", e); errorMsg="Database error: "+e.getMessage();
        } finally { closeDB(con,ps,null); }
    }
}

/* ── GET: load current data ──────────────────────────────── */
try {
    con = getConnection();
    ps  = con.prepareStatement(
        "SELECT PHONE,ADDRESS,TOTAL_ROOMS,TOTAL_WASHROOMS,DESCRIPTION,VIDEO_LINK " +
        "FROM HOUSE_POST WHERE POST_ID=? AND OWNER_EMAIL=?");
    ps.setInt(1,postId); ps.setString(2,ownerEmail); rs=ps.executeQuery();
    if (rs.next()) {
        phone       = rs.getString("PHONE")       != null ? rs.getString("PHONE")       : "";
        address     = rs.getString("ADDRESS")     != null ? rs.getString("ADDRESS")     : "";
        totalRooms  = rs.getInt("TOTAL_ROOMS");
        totalWash   = rs.getInt("TOTAL_WASHROOMS");
        description = rs.getString("DESCRIPTION") != null ? rs.getString("DESCRIPTION") : "";
        videoLink   = rs.getString("VIDEO_LINK")  != null ? rs.getString("VIDEO_LINK")  : "";
    } else { response.sendRedirect("manageHouse.jsp"); return; }
} catch(Exception e) { logError("editHouse.jsp",e); }
finally { closeDB(con,ps,rs); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Edit House #<%= postId %> – NexShohor</title>
<%@ include file="../includes/styles.jsp" %>
</head>
<body>
<%@ include file="../includes/bwNav.jsp" %>

<div class="bv-container">
<div class="glass bv-form-card" style="max-width:640px;">

    <div style="margin-bottom:22px;">
        <h4 style="color:#fff; font-weight:800;">&#9998; Edit Property <span style="color:var(--accent);">#<%= postId %></span></h4>
    </div>

    <% if (!successMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-success">&#10003; <%= sanitize(successMsg) %></div>
    <% } %>
    <% if (!errorMsg.isEmpty()) { %>
    <div class="bv-alert bv-alert-danger">&#9888; <%= sanitize(errorMsg) %></div>
    <% } %>

    <form method="post" action="editHouse.jsp?id=<%= postId %>" onsubmit="return bvValidate(this);" novalidate>

        <div class="bv-form-group">
            <label class="bv-label">Contact Phone <span class="bv-required">*</span></label>
            <input type="text" name="phone" class="bv-input" value="<%= sanitize(phone) %>"
                   data-required data-phone maxlength="11">
            <div class="bv-field-error">Enter valid BD phone (01XXXXXXXXX).</div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Property Address <span class="bv-required">*</span></label>
            <input type="text" name="address" class="bv-input" value="<%= sanitize(address) %>"
                   data-required maxlength="255">
            <div class="bv-field-error">Address is required.</div>
        </div>

        <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
            <div class="bv-form-group">
                <label class="bv-label">Total Rooms <span class="bv-required">*</span></label>
                <input type="number" name="rooms" class="bv-input" value="<%= totalRooms %>" min="1" data-required>
            </div>
            <div class="bv-form-group">
                <label class="bv-label">Washrooms</label>
                <input type="number" name="washrooms" class="bv-input" value="<%= totalWash %>" min="0">
            </div>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">Description</label>
            <textarea name="description" class="bv-textarea" rows="4"><%= sanitize(description) %></textarea>
        </div>

        <div class="bv-form-group">
            <label class="bv-label">YouTube Video Link</label>
            <input type="text" name="videoLink" class="bv-input" value="<%= sanitize(videoLink) %>">
        </div>

        <div style="display:flex;gap:12px;margin-top:4px;">
            <button type="submit" class="bv-btn bv-btn-primary" style="flex:2;">&#128190; Save Changes</button>
            <a href="manageHouse.jsp" class="bv-btn bv-btn-outline" style="flex:1;text-align:center;">&#8592; Back</a>
        </div>

    </form>
</div>
</div>
<%@ include file="../includes/scripts.jsp" %>
</body>
</html>
