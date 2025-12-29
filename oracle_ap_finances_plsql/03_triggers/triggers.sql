-- ETAPE 2 : CREATION DES TRIGGERS AUDIT AUTOMATIQUE + BLOCK MODIFICATION INVOICE

-- AJOUT D'UN TRIGGER POUR UPDATE ET UN TRIGGER POUR CALCUL AUTOMATIQUE MONTANT PAR LIGNE
-- 2025-12-24

CREATE OR REPLACE TRIGGER trg_ap_invoice_lines_amt
BEFORE INSERT OR UPDATE ON ap_invoice_lines
FOR EACH ROW
BEGIN
    :NEW.line_amount := :NEW.quantity * :NEW.unit_price;
END;
/

CREATE OR REPLACE TRIGGER trg_ap_suppliers_upd
BEFORE UPDATE ON ap_suppliers
FOR EACH ROW
BEGIN
    :NEW.last_update_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_ap_invoices_upd
BEFORE UPDATE ON ap_invoices
FOR EACH ROW
BEGIN
    :NEW.last_update_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_ai_ap_invoices
AFTER INSERT OR UPDATE OR DELETE ON ap_invoices
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO ap_audit_log
        VALUES (
            seq_audit.NEXTVAL,
            'INSERT_INVOICE',
            SYSDATE,
            'Invoice ID=' || :NEW.invoice_id
        );
        
    ELSIF UPDATING THEN
        INSERT INTO ap_audit_log
        VALUES (
            seq_audit.NEXTVAL,
            'UPDATE_INVOICE',
            SYSDATE,
            'Invoice ID=' || :NEW.invoice_id ||
            'status=' || :OLD.status || ' is now ' || :NEW.status
        );
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_no_update_paid_invoice
BEFORE UPDATE ON ap_invoices
FOR EACH ROW
BEGIN
    IF :OLD.status = 'PAID' THEN
        RAISE_APPLICATION_ERROR(-20030, 'PAID INVOICE CANT BE MODIFY');
    END IF;
END;
/
        
CREATE OR REPLACE TRIGGER trg_ap_payments_upd
BEFORE UPDATE ON ap_payments
FOR EACH ROW
BEGIN
    :NEW.last_update_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_ap_payments_close
BEFORE UPDATE OF payment_status ON ap_payments
FOR EACH ROW
BEGIN
    IF :NEW.payment_status = 'CLOSED'
       AND :OLD.payment_status <> 'CLOSED' THEN
        :NEW.end_date := SYSDATE;
    END IF;
END;
/

-- AJOUT TRIGGER POUR BLOQUER DELETE AP_INVOICES
CREATE OR REPLACE TRIGGER trg_bd_ap_invoices
BEFORE DELETE ON ap_invoices
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20031, 'DELETE INTERDIT SUR AP_INVOICES. UTILISER END_DATE.'
    );
END;
/
