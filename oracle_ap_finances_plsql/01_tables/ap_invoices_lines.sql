
--AJOUT DE LA TABLE : AP_INVOICES_LINES
-- 2025-12-24
-- =========================
-- TABLE: AP_INVOICES_LINES
-- =========================

CREATE TABLE ap_invoice_lines (
    invoice_line_id   NUMBER PRIMARY KEY,
    invoice_id        NUMBER NOT NULL,
    line_number       NUMBER NOT NULL,
    quantity          NUMBER(10,2) NOT NULL,
    unit_price        NUMBER(12,2) NOT NULL,
    line_amount       NUMBER(12,2),
    creation_date     DATE DEFAULT SYSDATE,

    CONSTRAINT fk_inv_lines_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES ap_invoices(invoice_id),

    CONSTRAINT uk_invoice_line
        UNIQUE (invoice_id, line_number)
);
