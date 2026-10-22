<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<nav class="bv-nav" style="border-bottom:1px solid rgba(248,113,113,0.4);">
    <a class="bv-nav-brand" href="../admin/home.jsp" style="color:var(--danger);">&#9881; NexShohor Admin</a>
    <div class="bv-ham" id="bvHam"><span></span><span></span><span></span></div>
    <div class="bv-nav-links" id="bvNavLinks">
        <a href="../admin/home.jsp">&#127968; Dashboard</a>
        <a href="../admin/bariwala.jsp">&#127968; BariWala</a>
        <a href="../admin/varatia.jsp">&#128101; Varatiya</a>
        <a href="../admin/properties.jsp">&#127968; Properties</a>
        <a href="../admin/requests.jsp">&#128203; Requests</a>
        <a href="../admin/complaints.jsp">&#128172; Complaints</a>
        <a href="../admin/bannedUsers.jsp">&#128683; Banned</a>
        <a href="../admin/transport.jsp">&#128652; Transport</a>
        <a href="../admin/emergency.jsp">&#128657; Emergency</a>
        <a href="../admin/sos.jsp">&#128721; SOS</a>
        <a href="../admin/alerts.jsp">&#127758; Alerts</a>
        <a href="../admin/settings.jsp">&#9881; Settings</a>
        <a href="../user/logout.jsp" style="color:var(--danger);">
            &#128274; Logout
            <span style="font-size:0.78rem;opacity:0.7;">(<%=session.getAttribute("user")!=null?session.getAttribute("user"):""%>)</span>
        </a>
    </div>
</nav>
