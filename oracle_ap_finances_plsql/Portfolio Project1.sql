/* Début de projet : Mini ERP Finances Oracle
creer par : Taha Rostoume
date : 2025-12-17
*/

-- 1) Création des tables et Séquences

-- =========================
-- TABLE: AP_SUPPLIERS
-- =========================

CREATE TABLE ap_suppliers (
    supplier_id      NUMBER PRIMARY KEY,
    supplier_name    VARCHAR2(100) NOT NULL,
    email            VARCHAR2(100),
    status           VARCHAR2(20) DEFAULT 'ACTIVE',
    creation_date    DATE DEFAULT SYSDATE
);


-- Modification de la table ap_suppliers 
-- 2025-12-24
alter table ap_suppliers
MODIFY supplier_type varchar2(20) NOT NULL;

alter table ap_suppliers
ADD CONSTRAINT chk_supplier_type CHECK (supplier_type IN ('PERSO_PHY', 'ENTREP'));

alter table ap_suppliers
ADD ( end_date DATE DEFAULT SYSDATE);

alter table ap_suppliers
MODIFY end_date DATE;

ALTER TABLE ap_suppliers
ADD CONSTRAINT chk_nas_neq
CHECK (
    (supplier_type = 'PERSO_PHY' AND NAS IS NOT NULL AND NEQ IS NULL)
 OR (supplier_type = 'ENTREP' AND NEQ IS NOT NULL AND NAS IS NULL)
);

UPDATE ap_suppliers
SET nas = 999999999
WHERE supplier_type = 'PERSO_PHY'
  AND nas IS NULL;

UPDATE ap_suppliers
SET neq = 888888888
WHERE supplier_type = 'ENTREP'
  AND neq IS NULL;

alter table ap_suppliers
ADD ( NEQ NUMBER);

alter table ap_suppliers
MODIFY last_update_date DATE;

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

-- =========================
-- TABLE: AP_AUDIT_LOG
-- =========================
CREATE TABLE ap_audit_log (
    log_id           NUMBER PRIMARY KEY,
    action_name      VARCHAR2(100),
    action_date      DATE DEFAULT SYSDATE,
    details          VARCHAR2(4000)
);


CREATE SEQUENCE seq_suppliers START WITH 1;
CREATE SEQUENCE seq_invoices  START WITH 1;
CREATE SEQUENCE seq_payments  START WITH 1;
CREATE SEQUENCE seq_audit     START WITH 1;

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

-- ETAPE 3 : Test rapide pour insertion

INSERT INTO ap_suppliers
values (seq_suppliers.NEXTVAL, 
        'HOHO RORO',
        'HOHORORO@YAHOO.CA',
        'ACTIVE', 
        SYSDATE,
        'PERSO_PHY',
        SYSDATE+10,
        12345,
        NULL,
        SYSDATE
        );

SELECT * FROM ap_suppliers;

/* ETAPE 4 : CREATION DU PAKCAGE SUPPLIERS
OBJECTIF : CREER, MODIFIER UN FOURNISSEUR
VALIDER DES DONNEES
AUDIT DES ACTIONS/TRANSACTIONS
*/

-- MODIFICATION DU PACKAGE
-- 2025-12-24

CREATE OR REPLACE PACKAGE supplier_pkg AS

    PROCEDURE create_supplier(
    p_supplier_name IN VARCHAR2,
    p_supplier_type IN VARCHAR2,
    p_email         IN VARCHAR2,
    p_nas           IN NUMBER,
    p_neq           IN NUMBER
    );
    
    PROCEDURE update_supplier(
     p_supplier_id      IN NUMBER,
     p_supplier_name    IN VARCHAR2,
     p_supplier_type    IN VARCHAR2,
     p_email            IN VARCHAR2,
     p_status           IN VARCHAR2,
     p_nas              IN NUMBER,
     p_neq              IN NUMBER
    );

    PROCEDURE end_supplier (
        p_supplier_id   IN NUMBER
    );

end supplier_pkg;
/

CREATE OR REPLACE PACKAGE BODY supplier_pkg AS

    PROCEDURE log_action (
        p_action  IN VARCHAR2,
        p_details IN VARCHAR2
    ) IS
    BEGIN
        INSERT INTO ap_audit_log
        VALUES (seq_audit.NEXTVAL,
                p_action, 
                SYSDATE,
                p_details
            );
END log_action;
    
    PROCEDURE create_supplier(
        p_supplier_name IN VARCHAR2,
        p_supplier_type IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_nas           IN NUMBER,
        p_neq           IN Number
    ) IS
    BEGIN
        IF p_supplier_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Supplier name is mandatory');
        END IF;
        
    INSERT INTO ap_suppliers (
        supplier_id,
        supplier_name,
        supplier_type,
        email,
        status,
        nas,
        neq,
        creation_date
    )
    VALUES (
        seq_suppliers.NEXTVAL,
        p_supplier_name,
        p_supplier_type,
        p_email,
        'ACTIVE',
        p_nas,
        p_neq,
        SYSDATE
    );
    
    log_action (
        'CREATE_SUPPLIER',
        'Supplier created: ' || p_supplier_name
    );
        
    COMMIT;
END create_supplier;

    PROCEDURE update_supplier (
        p_supplier_id   IN NUMBER,
        p_supplier_name IN VARCHAR2,
        p_supplier_type IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_status        IN VARCHAR2,
        p_nas           IN NUMBER,
        p_neq           IN NUMBER
    ) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        from ap_suppliers
        where supplier_id = p_supplier_id;
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Supplier not found');
        END IF;
        
        UPDATE ap_suppliers
        SET supplier_name    = p_supplier_name,
            supplier_type    = p_supplier_type,
            email            = p_email,
            status           = p_status,
            nas              = p_nas,
            neq              = p_neq,
            last_update_date = SYSDATE
        WHERE supplier_id = p_supplier_id;
        
        log_action(
            'UPDATED_SUPPLIER',
            'Supplier updated ID= ' || p_supplier_id
        );
        
        COMMIT;
    END update_supplier;
    
    PROCEDURE end_supplier (
        p_supplier_id IN NUMBER
    ) IS
    BEGIN
        UPDATE ap_suppliers
        SET status           = 'INACTIVE',
            end_date         = SYSDATE,
            last_update_date = SYSDATE
        WHERE supplier_id = p_supplier_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20043,
                'Impossible de terminer le supplier (ID=' || p_supplier_id || ')'
            );
        END IF;

        log_action(
            'END_SUPPLIER',
            'Supplier ended ID=' || p_supplier_id
        );
    END end_supplier; 

END  supplier_pkg;
/

-- zone de test pour supplier package

BEGIN
    supplier_pkg.create_supplier(
        p_supplier_name => 'ALLO',
        p_supplier_type => 'PERSO_PHY',
        p_email         => 'ALLO@abc.com',
        p_nas           => 123454,
        p_neq           => null
    );
END;
/
    
SELECT * FROM ap_suppliers;
SELECT * FROM ap_audit_log;

/* CREATTION DU PACKAGE INVOICE
OBJECTIF : CREER UNE FACTURE
GERER STATUT
AUDIT AUTOMATIQUE
VALIDE REGLES METIERS
*/

CREATE OR REPLACE PACKAGE invoice_pkg AS
    
    PROCEDURE create_invoice(
        p_supplier_id       IN NUMBER,
        p_invoice_number    IN VARCHAR2,
        p_invoice_date      IN DATE,
        p_amount            IN NUMBER
    );
    
    PROCEDURE validate_invoice(
        p_invoice_id    IN NUMBER
    );
    
    PROCEDURE end_invoice(
        p_invoice_id    IN NUMBER
    );
    
end invoice_pkg;
/

CREATE OR REPLACE PACKAGE BODY invoice_pkg AS

    PROCEDURE log_action (
    p_action    IN VARCHAR2,
    p_details   IN VARCHAR2
    ) IS
    BEGIN
        INSERT INTO ap_audit_log
        VALUES (seq_audit.NEXTVAL, 
                p_action,
                SYSDATE,
                p_details);
    END log_action;
    
    PROCEDURE create_invoice (
        p_supplier_id       IN NUMBER,
        p_invoice_number    IN VARCHAR2,
        p_invoice_date      IN DATE,
        p_amount            IN NUMBER
    ) IS
        v_status ap_suppliers.status%TYPE;
    BEGIN
        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'INVOICE AMOUNT MUST BE GREATER THAN ZERO');
        END IF;

        SELECT status
        INTO v_status
        FROM ap_suppliers
        WHERE supplier_id = p_supplier_id;
    
        IF v_status <> 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(-20011, 'Supplier is not active');
        END IF;
        
        INSERT INTO ap_invoices (
            invoice_id,
            supplier_id,
            invoice_number,
            invoice_date,
            amount,
            status,
            creation_date
    )
    
    VALUES (
        seq_invoices.NEXTVAL,
        p_supplier_id,
        p_invoice_number,
        p_invoice_date,
        p_amount,
        'CREATED',
        SYSDATE
    );
    
    log_action(
        'CREATED_INVOICE',
        'Invoice ' || p_invoice_number || ' created'
    );
    
    /*COMMIT;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Supplier not found');
    */
    END create_invoice;
    
    PROCEDURE validate_invoice (
        p_invoice_id    IN NUMBER
    ) IS
        v_status ap_invoices.status%TYPE;
    
    BEGIN
            
        SELECT status
        INTO v_status
        FROM ap_invoices
        where invoice_id = p_invoice_id;
        
        IF v_status <> 'CREATED' THEN
            RAISE_APPLICATION_ERROR(-20013, 'Only CREATED invoice can be validated');
        END IF;
        
        UPDATE ap_invoices
        SET status = 'VALIDATED',
            last_update_date = SYSDATE
        WHERE invoice_id = p_invoice_id;
        
        log_action(
            'VALIDATE_INVOICE',
            'Invoice validated ID= ' || p_invoice_id
        );
        
        /*
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20014, 'Invoice not found');
            */
        END validate_invoice;
        
        PROCEDURE end_invoice (
        p_invoice_id IN NUMBER
    ) IS
        v_status ap_invoices.status%TYPE;
    BEGIN
        SELECT status
        INTO v_status
        FROM ap_invoices
        WHERE invoice_id = p_invoice_id;

        IF v_status = 'CLOSED' THEN
            RAISE_APPLICATION_ERROR(-20015, 'Invoice already closed');
        END IF;

        UPDATE ap_invoices
        SET status           = 'CLOSED',
            end_date         = SYSDATE,
            last_update_date = SYSDATE
        WHERE invoice_id = p_invoice_id;

        log_action(
            'END_INVOICE',
            'Invoice ended ID=' || p_invoice_id
        );

/*
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20016, 'Invoice not found');
            */
    END end_invoice;
        
END invoice_pkg;
/
        
-- test express (package invoice)
set serveroutput on;
BEGIN
  invoice_pkg.create_invoice(
      p_supplier_id    => 1,
      p_invoice_number => 'INV-010',
      p_invoice_date   => SYSDATE,
      p_amount         => 1000
  );
END;
/

BEGIN
  invoice_pkg.validate_invoice(p_invoice_id => 6);
END;
/
  
SELECT * FROM ap_invoices;
SELECT * FROM ap_audit_log;
    
    
    
 -- ETAPE 5 : CREATION DU PACKAGE PAYMENT
 
CREATE OR REPLACE PACKAGE payment_pkg AS
 
    PROCEDURE pay_invoice (
        p_invoice_id    IN NUMBER,
        p_amount        IN NUMBER
    );
    
END payment_pkg;
/
    
CREATE OR REPLACE PACKAGE BODY payment_pkg AS
    
    PROCEDURE log_action(
        p_action    IN VARCHAR2,
        p_details   IN VARCHAR2
    ) IS
    
    BEGIN
        INSERT INTO ap_audit_log
        VALUES (seq_audit.NEXTVAL, p_action, SYSDATE, p_details);
    END log_action;
    
    
    PROCEDURE pay_invoice (
        p_invoice_id    IN NUMBER,
        p_amount        IN NUMBER
    ) IS
        v_status ap_invoices.status%TYPE;
        v_amount ap_invoices.amount%TYPE;
    
    BEGIN
        SELECT status, amount
        INTO v_status, v_amount
        FROM ap_invoices
        WHERE invoice_id = p_invoice_id;

        IF v_status <> 'VALIDATED' THEN
            RAISE_APPLICATION_ERROR(-20020, 'ONLY VALIDATED INVOICES CAN BE PAID');
        END IF;
        
        
        IF p_amount <> v_amount THEN
            RAISE_APPLICATION_ERROR(-20021, 'PAYMENT AMOUNT MUST BE EQUAL TO INVOICE AMOUNT');
        END IF;
        
        
        INSERT INTO ap_payments (
            payment_id,
            invoice_id,
            payment_date,
            amount,
            payment_status
        )
        
        VALUES (
            seq_payments.NEXTVAL,
            p_invoice_id,
            SYSDATE,
            p_amount,
            'PAID'
        );
    
        UPDATE ap_invoices
        SET status = 'PAID',
        last_update_date = SYSDATE,
        end_date = SYSDATE
        WHERE invoice_id = p_invoice_id;
        
        log_action (
            'PAY_INVOICE',
            'Invoice paid ID= ' || p_invoice_id
        );
        /*
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20022, 'Invoice not found');
            */
        END pay_invoice;
END payment_pkg;
/

-- test package payment

BEGIN
  payment_pkg.pay_invoice(
      p_invoice_id => 4,
      p_amount     => 1500
  );
END;
/

SELECT * FROM ap_payments;
SELECT * FROM ap_invoices;
SELECT * FROM ap_audit_log;

-- ETAPE 6 : REPORTING (CREATION DES VIEWS)

CREATE OR REPLACE VIEW v_ap_open_invoices AS
    SELECT
        s.supplier_name,
        i.invoice_number,
        i.invoice_date,
        i.amount,
        i.status
    FROM ap_invoices i
    JOIN ap_suppliers s ON s.supplier_id = i.supplier_id
    WHERE i.status NOT IN ('PAID','CLOSED');

-- TEST DU REPORTING VIEW

SELECT * FROM v_ap_open_invoices
ORDER BY invoice_date;




