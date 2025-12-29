
-- =========================
-- TABLE: AP_INVOICES
-- =========================
CREATE TABLE ap_invoices (
    invoice_id       NUMBER PRIMARY KEY,
    supplier_id      NUMBER NOT NULL,
    invoice_number   VARCHAR2(50) NOT NULL,
    invoice_date     DATE NOT NULL,
    amount           NUMBER(12,2) NOT NULL,
    status           VARCHAR2(20) DEFAULT 'CREATED',
    creation_date    DATE DEFAULT SYSDATE,
    CONSTRAINT fk_invoice_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES ap_suppliers(supplier_id)
);


-- Modification de la table ap_invoices
-- 2025-12-24

alter table ap_invoices
ADD ( last_update_date DATE,
      end_date         DATE
);
