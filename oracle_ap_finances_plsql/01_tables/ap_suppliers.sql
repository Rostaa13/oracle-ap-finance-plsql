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
