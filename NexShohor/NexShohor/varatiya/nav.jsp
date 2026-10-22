<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<nav class="bv-nav">
    <a class="bv-nav-brand" href="../varatiya/home.jsp">&#127961; NexShohor</a>
    <div class="bv-ham" id="bvHam"><span></span><span></span><span></span></div>
    <div class="bv-nav-links" id="bvNavLinks">
        <a href="../varatiya/browse.jsp">&#127968; Browse</a>
        <a href="../varatiya/submitRequest.jsp">&#128203; Request</a>
        <a href="../varatiya/myRequests.jsp">&#128193; My Requests</a>
        <a href="../varatiya/complaints.jsp">&#128172; Complaints</a>
        <a href="../user/transport.jsp">&#128652; Transport</a>
        <a href="../user/sos.jsp">&#128721; Emergency</a>
        <a href="../user/alerts.jsp">&#127758; Alerts</a>
        <a href="../varatiya/dashboard.jsp">&#128202; Dashboard</a>
        <a href="../varatiya/profile.jsp">&#128100; Profile</a>
        <a href="../user/logout.jsp" style="color:var(--text-muted);">
            &#128274; Logout
            <span style="font-size:0.78rem;opacity:0.7;">(<%=session.getAttribute("user")!=null?session.getAttribute("user"):""%>)</span>
        </a>
    </div>
</nav>
