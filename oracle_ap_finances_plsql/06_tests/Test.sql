-- ETAPE 1 : Test rapide pour insertion

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


-- TEST DU REPORTING VIEW

SELECT * FROM v_ap_open_invoices
ORDER BY invoice_date;
