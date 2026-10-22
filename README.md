# NexShohor 🌆 — Where City Life Gets Smarter

A smart-city web platform that combines **house rental management** with **emergency SOS, incident reporting, urban alerts and public transport updates**. Built with classic JSP and Oracle Database.

## Features
**Rental module** (evolved from [BasaVaraa](../basavaraa))
- Owners list and manage properties; tenants browse and request them
- Private chat per request, complaints, notifications
- Admin can ban users, manage requests and toggle property status

**Smart-city module**
- 🚨 **SOS:** users send emergency requests and track their status; admin monitors SOS logs
- 📍 **Incident and crowd reports:** report incidents, view details
- 🏥 **Emergency services directory:** hospital, police, fire, ambulance, pharmacy
- 📢 **Urban alerts:** admin-issued alerts by area, bookmarkable by users
- 🚌 **Transport updates and alerts**
- ⚙️ Admin settings and system log

## Tech Stack
JSP / Java (JDK 17+, Jakarta EE 9+) · Apache Tomcat 10+ · Oracle Database 21c XE · HTML, CSS, vanilla JavaScript

## Project Structure
```
NexShohor/
├── admin/      dashboard, alerts, SOS, emergency, transport, users, settings
├── bariwala/   property owner pages
├── varatiya/   tenant pages
├── user/       login, register, SOS, incidents, alerts, transport
├── includes/   db, session guard, chat, notifications, styles
├── sql/        schema.sql
└── WEB-INF/    web.xml
```

## Getting Started
1. Run `sql/schema.sql` on Oracle 21c XE.
2. Add the Oracle JDBC driver to `WEB-INF/lib/` or Tomcat's `lib/`.
3. Configure the connection in `includes/db.jsp`.
4. Deploy to Tomcat and open `http://localhost:8080/NexShohor/` (welcome page is `user/login.jsp`).
