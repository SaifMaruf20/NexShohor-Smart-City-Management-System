<%-- includes/scripts.jsp - Shared vanilla JS utilities --%>
<script>
/* ── MOBILE NAV TOGGLE ──────────────────────────────────── */
(function(){
    const ham  = document.getElementById("bvHam");
    const menu = document.getElementById("bvNavLinks");
    if (ham && menu) {
        ham.addEventListener("click", function(){
            menu.classList.toggle("open");
        });
    }
})();

/* ── FORM VALIDATION HELPERS ────────────────────────────── */
function bvValidate(form) {
    let ok = true;
    form.querySelectorAll("[data-required]").forEach(function(el) {
        const err = el.parentElement.querySelector(".bv-field-error");
        if (!el.value.trim()) {
            el.classList.add("invalid");
            if (err) err.style.display = "block";
            ok = false;
        } else {
            el.classList.remove("invalid");
            if (err) err.style.display = "none";
        }
    });
    // Email check
    form.querySelectorAll("[data-email]").forEach(function(el) {
        const err = el.parentElement.querySelector(".bv-field-error");
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (el.value.trim() && !re.test(el.value.trim())) {
            el.classList.add("invalid");
            if (err) { err.textContent = "Enter a valid email."; err.style.display = "block"; }
            ok = false;
        }
    });
    // Phone check (BD format: 01XXXXXXXXX)
    form.querySelectorAll("[data-phone]").forEach(function(el) {
        const err = el.parentElement.querySelector(".bv-field-error");
        const re = /^01[3-9]\d{8}$/;
        if (el.value.trim() && !re.test(el.value.trim())) {
            el.classList.add("invalid");
            if (err) { err.textContent = "Enter a valid BD phone (01XXXXXXXXX)."; err.style.display = "block"; }
            ok = false;
        }
    });
    // Password match
    const pw  = form.querySelector("[data-pw]");
    const cpw = form.querySelector("[data-cpw]");
    if (pw && cpw && pw.value !== cpw.value) {
        cpw.classList.add("invalid");
        const err = cpw.parentElement.querySelector(".bv-field-error");
        if (err) { err.textContent = "Passwords do not match."; err.style.display = "block"; }
        ok = false;
    }
    return ok;
}

/* ── TOGGLE PASSWORD ────────────────────────────────────── */
function bvTogglePw(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.type = (el.type === "password") ? "text" : "password";
}

/* ── CONFIRM BEFORE ACTION ──────────────────────────────── */
function bvConfirm(msg) { return window.confirm(msg || "Are you sure?"); }

/* ── AUTO-DISMISS ALERTS ────────────────────────────────── */
setTimeout(function(){
    document.querySelectorAll(".bv-alert-success").forEach(function(el){
        el.style.transition = "opacity 0.8s";
        el.style.opacity = "0";
        setTimeout(function(){ el.remove(); }, 800);
    });
}, 4000);
</script>
