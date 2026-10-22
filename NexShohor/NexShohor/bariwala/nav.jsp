<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<nav class="bv-nav">
    <a class="bv-nav-brand" href="../bariwala/home.jsp">&#127961; NexShohor</a>
    <div class="bv-ham" id="bvHam"><span></span><span></span><span></span></div>
    <div class="bv-nav-links" id="bvNavLinks">
        <a href="../bariwala/home.jsp">&#127968; Dashboard</a>
        <a href="../bariwala/addProperty.jsp">&#10010; Add Property</a>
        <a href="../bariwala/manageProperties.jsp">&#127968; My Properties</a>
        <a href="../bariwala/tenantRequests.jsp">&#128203; Tenant Requests</a>
        <a href="../bariwala/complaints.jsp">&#128172; Complaints</a>
        <a href="../user/alerts.jsp">&#127758; Urban Alerts</a>
        <a href="../bariwala/home.jsp">&#127968; Dashboard</a>
        <a href="../user/logout.jsp" style="color:var(--text-muted);">
            &#128274; Logout
            <span style="font-size:0.78rem;opacity:0.7;">(<%=session.getAttribute("user")!=null?session.getAttribute("user"):""%>)</span>
        </a>
    </div>
</nav>
