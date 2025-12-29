
-- =========================
-- TABLE: AP_PAYMENTS
-- =========================
CREATE TABLE ap_payments (
    payment_id       NUMBER PRIMARY KEY,
    invoice_id       NUMBER NOT NULL,
    payment_date     DATE DEFAULT SYSDATE,
    amount           NUMBER(12,2) NOT NULL,
    CONSTRAINT fk_payment_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES ap_invoices(invoice_id)
);

--MODIFICATION TABLE AP_PAYMENTS : AJOUT DE 3 COLONNES ET 1 CONTRAINTE )

ALTER TABLE ap_payments 
ADD (   payment_status   VARCHAR2(20) DEFAULT 'CREATED',
        last_update_date DATE,
        end_date         DATE
);

ALTER TABLE ap_payments
ADD CONSTRAINT chk_payment_status
CHECK (payment_status IN ('CREATED', 'VALIDATED', 'PAID', 'CLOSED'));
