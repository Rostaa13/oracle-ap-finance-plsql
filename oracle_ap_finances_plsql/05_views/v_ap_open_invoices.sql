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
