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
    