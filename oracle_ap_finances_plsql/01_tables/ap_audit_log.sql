
-- =========================
-- TABLE: AP_AUDIT_LOG
-- =========================
CREATE TABLE ap_audit_log (
    log_id           NUMBER PRIMARY KEY,
    action_name      VARCHAR2(100),
    action_date      DATE DEFAULT SYSDATE,
    details          VARCHAR2(4000)
);
