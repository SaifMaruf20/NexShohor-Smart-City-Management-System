<%-- ============================================================
     includes/styles.jsp  –  Shared CSS (no Bootstrap, no frameworks)
     ============================================================ --%>
<style>
/* ── RESET & BASE ─────────────────────────────────────────────── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
    --accent:      #20c997;
    --accent-dark: #17a589;
    --blue:        #60a5fa;
    --warn:        #fbbf24;
    --danger:      #f87171;
    --success:     #34d399;
    --text-light:  rgba(255,255,255,0.85);
    --text-muted:  rgba(255,255,255,0.50);
    --glass-bg:    rgba(255,255,255,0.10);
    --glass-bdr:   rgba(255,255,255,0.16);
    --radius:      14px;
    --shadow:      0 12px 36px rgba(0,0,0,0.40);
}

body {
    font-family: 'Segoe UI', system-ui, sans-serif;
    background:
        linear-gradient(rgba(8,12,22,0.82), rgba(8,12,22,0.90)),
        url("https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80")
        no-repeat center center fixed;
    background-size: cover;
    min-height: 100vh;
    color: var(--text-light);
}

/* ── GLASS CARD ───────────────────────────────────────────────── */
.glass {
    background: var(--glass-bg);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    border: 1px solid var(--glass-bdr);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
}

/* ── NAVBAR ───────────────────────────────────────────────────── */
.bv-nav {
    background: rgba(14,18,30,0.92);
    backdrop-filter: blur(12px);
    border-bottom: 1px solid var(--glass-bdr);
    padding: 0 24px;
    height: 60px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    position: sticky;
    top: 0;
    z-index: 100;
}
.bv-nav-brand {
    font-weight: 800;
    font-size: 1.2rem;
    color: var(--accent);
    text-decoration: none;
    letter-spacing: 0.4px;
}
.bv-nav-links { display: flex; align-items: center; gap: 6px; }
.bv-nav-links a {
    color: var(--text-light);
    text-decoration: none;
    padding: 7px 14px;
    border-radius: 8px;
    font-size: 0.88rem;
    font-weight: 500;
    transition: background 0.2s;
}
.bv-nav-links a:hover, .bv-nav-links a.active {
    background: rgba(255,255,255,0.10);
    color: #fff;
}
.bv-nav-links .nav-icon { color: var(--accent); margin-right: 5px; }
.bv-nav-logout {
    border: 1px solid var(--accent);
    color: var(--accent) !important;
    border-radius: 20px !important;
    padding: 5px 16px !important;
    font-size: 0.84rem !important;
    margin-left: 6px;
}
.bv-nav-logout:hover { background: var(--accent) !important; color: #000 !important; }

/* Mobile nav */
.bv-ham { display: none; flex-direction: column; gap: 5px; cursor: pointer; padding: 4px; }
.bv-ham span { display: block; width: 24px; height: 2px; background: var(--accent); border-radius: 2px; transition: 0.3s; }
@media (max-width: 768px) {
    .bv-nav-links { display: none; flex-direction: column; position: absolute; top: 60px; left: 0; right: 0; background: rgba(14,18,30,0.97); padding: 12px; border-bottom: 1px solid var(--glass-bdr); }
    .bv-nav-links.open { display: flex; }
    .bv-ham { display: flex; }
}

/* ── LAYOUT ───────────────────────────────────────────────────── */
.bv-container { max-width: 1200px; margin: 0 auto; padding: 28px 20px; }

/* ── PAGE HEADER ──────────────────────────────────────────────── */
.bv-page-header { padding: 22px 26px; margin-bottom: 24px; }
.bv-page-header h4 { font-weight: 800; color: #fff; margin-bottom: 4px; }
.bv-page-header p  { color: var(--text-muted); font-size: 0.9rem; }

/* ── SECTION TITLE ────────────────────────────────────────────── */
.bv-section-title {
    font-weight: 700; color: #fff;
    border-left: 4px solid var(--blue);
    padding-left: 12px;
    margin-bottom: 16px;
    font-size: 1rem;
}

/* ── STAT CARD ────────────────────────────────────────────────── */
.bv-stat { padding: 20px; text-align: center; }
.bv-stat-icon { font-size: 2rem; margin-bottom: 6px; }
.bv-stat-num  { font-size: 2rem; font-weight: 800; line-height: 1.1; }
.bv-stat-lbl  { font-size: 0.78rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; }

/* ── FORM STYLES ──────────────────────────────────────────────── */
.bv-form-card { max-width: 600px; margin: 32px auto; padding: 32px; }
.bv-label { display: block; font-size: 0.88rem; font-weight: 600; color: var(--text-light); margin-bottom: 6px; }
.bv-input, .bv-select, .bv-textarea {
    width: 100%;
    background: rgba(255,255,255,0.10);
    border: 1px solid rgba(255,255,255,0.18);
    color: #fff;
    border-radius: 8px;
    padding: 10px 14px;
    font-size: 0.9rem;
    outline: none;
    transition: border-color 0.2s;
    font-family: inherit;
}
.bv-input::placeholder, .bv-textarea::placeholder { color: rgba(255,255,255,0.35); }
.bv-input:focus, .bv-select:focus, .bv-textarea:focus {
    border-color: var(--accent);
    background: rgba(255,255,255,0.14);
}
.bv-select option { background: #1f2937; color: #fff; }
.bv-textarea { resize: vertical; min-height: 100px; }
.bv-form-group { margin-bottom: 18px; }
.bv-input-group { display: flex; }
.bv-input-group .bv-input { border-radius: 8px 0 0 8px; }
.bv-input-group .bv-eye-btn {
    background: rgba(255,255,255,0.10); border: 1px solid rgba(255,255,255,0.18);
    border-left: none; color: var(--text-light); padding: 0 14px; cursor: pointer;
    border-radius: 0 8px 8px 0; font-size: 0.95rem;
}

/* ── BUTTONS ──────────────────────────────────────────────────── */
.bv-btn {
    padding: 10px 22px; border: none; border-radius: 8px;
    font-size: 0.9rem; font-weight: 600; cursor: pointer;
    text-decoration: none; display: inline-block; text-align: center;
    transition: opacity 0.2s, transform 0.1s;
}
.bv-btn:hover { opacity: 0.88; transform: translateY(-1px); }
.bv-btn-primary { background: linear-gradient(135deg, var(--accent-dark), var(--accent)); color: #000; }
.bv-btn-blue    { background: linear-gradient(135deg, #2563eb, var(--blue)); color: #fff; }
.bv-btn-danger  { background: rgba(248,113,113,0.18); border: 1px solid var(--danger); color: var(--danger); }
.bv-btn-danger:hover  { background: var(--danger); color: #000; }
.bv-btn-warn    { background: rgba(251,191,36,0.18); border: 1px solid var(--warn); color: var(--warn); }
.bv-btn-warn:hover    { background: var(--warn); color: #000; }
.bv-btn-outline { background: transparent; border: 1px solid var(--text-muted); color: var(--text-light); }
.bv-btn-outline:hover { background: rgba(255,255,255,0.10); }
.bv-btn-w100 { width: 100%; }
.bv-btn-sm { padding: 4px 12px; font-size: 0.78rem; }

/* ── ALERTS ───────────────────────────────────────────────────── */
.bv-alert {
    padding: 12px 16px; border-radius: 8px; margin-bottom: 16px;
    font-size: 0.9rem; font-weight: 500;
}
.bv-alert-success { background: rgba(52,211,153,0.15); border: 1px solid var(--success); color: var(--success); }
.bv-alert-danger  { background: rgba(248,113,113,0.15); border: 1px solid var(--danger);  color: var(--danger); }
.bv-alert-warn    { background: rgba(251,191,36,0.15);  border: 1px solid var(--warn);    color: var(--warn); }

/* ── BADGES ───────────────────────────────────────────────────── */
.bv-badge { padding: 4px 10px; border-radius: 20px; font-size: 0.75rem; font-weight: 600; display: inline-block; }
.bv-badge-pending   { background: rgba(251,191,36,0.18);  color: #fcd34d; }
.bv-badge-approved  { background: rgba(52,211,153,0.18);  color: #6ee7b7; }
.bv-badge-rejected  { background: rgba(248,113,113,0.18); color: #fda4af; }
.bv-badge-cancelled { background: rgba(107,114,128,0.20); color: #9ca3af; }
.bv-badge-available { background: rgba(52,211,153,0.18);  color: #6ee7b7; }
.bv-badge-rented    { background: rgba(248,113,113,0.18); color: #fda4af; }

/* ── TABLE ────────────────────────────────────────────────────── */
.bv-table-wrap { overflow-x: auto; }
.bv-table { width: 100%; border-collapse: collapse; }
.bv-table th {
    background: rgba(255,255,255,0.10); color: #fff;
    padding: 12px 14px; font-size: 0.78rem; text-transform: uppercase;
    letter-spacing: 0.5px; font-weight: 600; border: none;
    white-space: nowrap;
}
.bv-table td {
    padding: 12px 14px; color: var(--text-light);
    border-top: 1px solid rgba(255,255,255,0.06);
    font-size: 0.87rem; vertical-align: middle;
}
.bv-table tbody tr:hover { background: rgba(255,255,255,0.05); }

/* ── PROPERTY CARD ────────────────────────────────────────────── */
.bv-prop-card { overflow: hidden; transition: transform 0.25s; }
.bv-prop-card:hover { transform: translateY(-5px); }
.bv-prop-thumb { width: 100%; height: 180px; object-fit: cover; border: none; }
.bv-prop-placeholder {
    width: 100%; height: 180px; display: flex;
    align-items: center; justify-content: center;
    background: rgba(255,255,255,0.05); font-size: 3rem;
    color: rgba(255,255,255,0.25);
}
.bv-prop-body { padding: 14px; }
.bv-prop-address { font-weight: 700; color: #fff; margin-bottom: 8px; font-size: 0.92rem; }
.bv-prop-detail  { font-size: 0.82rem; color: var(--text-muted); margin-bottom: 4px; }

/* ── GRID ─────────────────────────────────────────────────────── */
.bv-grid { display: grid; gap: 20px; }
.bv-grid-2 { grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); }
.bv-grid-3 { grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); }
.bv-grid-4 { grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); }

/* ── EMPTY STATE ──────────────────────────────────────────────── */
.bv-empty { text-align: center; padding: 56px 20px; }
.bv-empty-icon { font-size: 3.5rem; opacity: 0.3; display: block; margin-bottom: 14px; }

/* ── PAGINATION ───────────────────────────────────────────────── */
.bv-pagination { display: flex; gap: 6px; align-items: center; margin-top: 20px; flex-wrap: wrap; }
.bv-page-btn {
    padding: 6px 12px; border-radius: 6px; font-size: 0.82rem;
    border: 1px solid var(--glass-bdr); color: var(--text-light);
    text-decoration: none; transition: 0.2s;
    background: rgba(255,255,255,0.08);
}
.bv-page-btn:hover, .bv-page-btn.active {
    background: var(--accent); color: #000; border-color: var(--accent);
}

/* ── FILTER BAR ───────────────────────────────────────────────── */
.bv-filter { display: flex; gap: 10px; flex-wrap: wrap; padding: 14px 16px; margin-bottom: 18px; align-items: center; }
.bv-filter .bv-input, .bv-filter .bv-select { width: auto; flex: 1; min-width: 150px; }

/* ── VALIDATION HINTS ─────────────────────────────────────────── */
.bv-field-error { color: var(--danger); font-size: 0.78rem; margin-top: 4px; display: none; }
.bv-input.invalid, .bv-select.invalid { border-color: var(--danger); }
.bv-required { color: var(--danger); }


/* ── BAN BADGE ────────────────────────────────────────────────── */
.bv-badge-banned  { background: rgba(248,113,113,0.25); color: #f87171; border: 1px solid var(--danger); }
.bv-badge-active  { background: rgba(52,211,153,0.18);  color: #34d399; }

/* ── CHAT / MESSAGING ─────────────────────────────────────────── */
.chat-wrap        { display:flex; flex-direction:column; height:420px; overflow-y:auto; gap:10px; padding:16px; }
.chat-bubble      { max-width:70%; padding:10px 14px; border-radius:14px; font-size:0.88rem; line-height:1.5; word-break:break-word; }
.chat-me          { align-self:flex-end; background:linear-gradient(135deg,var(--accent-dark),var(--accent)); color:#000; border-bottom-right-radius:4px; }
.chat-other       { align-self:flex-start; background:rgba(255,255,255,0.12); color:var(--text-light); border-bottom-left-radius:4px; }
.chat-meta        { font-size:0.72rem; color:var(--text-muted); margin-top:4px; }
.chat-input-row   { display:flex; gap:8px; padding:12px 16px; border-top:1px solid var(--glass-bdr); }
.chat-input-row .bv-input { flex:1; }

/* ── NOTIFICATION BELL ────────────────────────────────────────── */
.bv-notif-bell    { position:relative; display:inline-flex; align-items:center; cursor:pointer; padding:7px 10px; border-radius:8px; color:var(--text-light); text-decoration:none; font-size:1.15rem; transition:background 0.2s; }
.bv-notif-bell:hover { background:rgba(255,255,255,0.10); }
.bv-notif-count   { position:absolute; top:2px; right:2px; background:var(--danger); color:#fff; font-size:0.6rem; font-weight:800; min-width:16px; height:16px; border-radius:50%; display:flex; align-items:center; justify-content:center; line-height:1; }

/* ── COMPLAINT STATUS ─────────────────────────────────────────── */
.bv-badge-open      { background:rgba(96,165,250,0.18);  color:#93c5fd; }
.bv-badge-inreview  { background:rgba(251,191,36,0.18);  color:#fcd34d; }
.bv-badge-resolved  { background:rgba(52,211,153,0.18);  color:#6ee7b7; }
.bv-badge-closed    { background:rgba(107,114,128,0.20); color:#9ca3af; }

/* ── STATUS TOGGLE BUTTON ─────────────────────────────────────── */
.bv-btn-toggle-avail { background:rgba(52,211,153,0.15); border:1px solid var(--success); color:var(--success); }
.bv-btn-toggle-avail:hover { background:var(--success); color:#000; }
.bv-btn-toggle-rent  { background:rgba(251,191,36,0.15); border:1px solid var(--warn); color:var(--warn); }
.bv-btn-toggle-rent:hover  { background:var(--warn); color:#000; }



</style>