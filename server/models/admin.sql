DELIMITER $$

/*
 zRecomputeEntityMap

 Abolishes and recomputes the entity_map from the base tables in the system.  This is
 useful in case of database corruption in which references get out of sync.
*/
CREATE PROCEDURE zRecomputeEntityMap()
BEGIN
  DELETE FROM entity_map;

  -- patient
  INSERT INTO entity_map
    SELECT patient.uuid, CONCAT_WS('.', 'PA', project.abbr, patient.reference)
    FROM patient JOIN project ON patient.project_id = project.id;

  -- patient debtor
  INSERT INTO entity_map
    SELECT patient.debtor_uuid, CONCAT_WS('.', 'PA', project.abbr, patient.reference)
    FROM patient JOIN project ON patient.project_id = project.id;

  -- employee
  INSERT INTO entity_map
    SELECT employee.creditor_uuid, CONCAT_WS('.', 'EM', enterprise.abbr, employee.reference)
    FROM employee
    JOIN patient ON patient.uuid = employee.patient_uuid
    JOIN project ON project.id = patient.project_id
    JOIN enterprise ON enterprise.id = project.enterprise_id;

  -- supplier
  INSERT INTO entity_map
    SELECT supplier.creditor_uuid, CONCAT_WS('.', 'FO', supplier.reference) FROM supplier;
END $$

/*
 zRecomputeDocumentMap

 Abolishes and recomputes the document_map entries from the base tables in the
 database.  This is useful in case of data corruption.
*/
CREATE PROCEDURE zRecomputeDocumentMap()
BEGIN
  DELETE FROM document_map;

  -- cash payments
  INSERT INTO document_map
    SELECT cash.uuid, CONCAT_WS('.', 'CP', project.abbr, cash.reference)
    FROM cash JOIN project where project.id = cash.project_id;

  -- invoices
  INSERT INTO document_map
    SELECT invoice.uuid, CONCAT_WS('.', 'IV', project.abbr, invoice.reference)
    FROM invoice JOIN project where project.id = invoice.project_id;

  -- purchases
  INSERT INTO document_map
    SELECT purchase.uuid, CONCAT_WS('.', 'PO', project.abbr, purchase.reference)
    FROM purchase JOIN project where project.id = purchase.project_id;

  -- vouchers
  INSERT INTO document_map
    SELECT voucher.uuid, CONCAT_WS('.', 'VO', project.abbr, voucher.reference)
    FROM voucher JOIN project where project.id = voucher.project_id;
END $$

/*
 zRepostVoucher

 Removes the voucher record from the posting_journal and calls the PostVoucher() method on
 the record in the voucher table to re-post it to the journal.
*/
CREATE PROCEDURE zRepostVoucher(
  IN vUuid BINARY(16)
)
BEGIN
  DELETE FROM posting_journal WHERE posting_journal.record_uuid = vUuid;
  CALL PostVoucher(vUuid);
END $$

/*
 zRepostInvoice

 Removes the invoice record from the posting_journal and calls the PostInvoice() method on
 the record in the invoice table to re-post it to the journal.
*/
CREATE PROCEDURE zRepostInvoice(
  IN iUuid BINARY(16)
)
BEGIN
  DELETE FROM posting_journal WHERE posting_journal.record_uuid = iUuid;
  CALL PostInvoice(iUuid);
END $$

/*
 zRepostCash

 Removes the cash record from the posting_journal and calls the PostCash() method on
 the record in the cash table to re-post it to the journal.
*/
CREATE PROCEDURE zRepostCash(
  IN cUuid BINARY(16)
)
BEGIN
  DELETE FROM posting_journal WHERE posting_journal.record_uuid = cUuid;
  CALL VerifyCashTemporaryTables();
  CALL PostCash(cUuid);
END $$

/*
 zRecalculatePeriodTotals

 Removes all data from the period_total table and rebuilds it.
*/
CREATE PROCEDURE zRecalculatePeriodTotals()
BEGIN

  -- wipe the period total table
  DELETE FROM  period_total
  WHERE period_id IN (
    SELECT id
    FROM period
    WHERE number <> 0
  );

  INSERT INTO period_total (enterprise_id, fiscal_year_id, period_id, account_id, credit, debit)
    SELECT project.enterprise_id, period.fiscal_year_id, period_id, account_id, SUM(credit_equiv) AS credit, SUM(debit_equiv) AS debit
    FROM general_ledger
      JOIN period ON general_ledger.period_id = period.id
      JOIN project ON general_ledger.project_id = project.id
    GROUP BY account_id, period_id, fiscal_year_id, enterprise_id;

END $$


CREATE PROCEDURE zUpdatePatientText()
BEGIN
  UPDATE `debtor` JOIN `patient` ON debtor.uuid = patient.debtor_uuid
    SET debtor.text = CONCAT('Patient/', patient.display_name);
END $$

/*
CALL zMergeServices(fromId, toId);

DESCRIPTION
Merges two services by changing the service_id pointers to the new service and
then removing the previous service.
*/
DROP PROCEDURE IF EXISTS zMergeServices$$
CREATE PROCEDURE zMergeServices(
  IN from_service_id INTEGER,
  IN to_service_id INTEGER
) BEGIN

  UPDATE invoice SET service_id = to_service_id WHERE service_id = from_service_id;
  UPDATE employee SET service_id = to_service_id WHERE service_id = from_service_id;
  UPDATE patient_visit_service SET service_id = to_service_id WHERE service_id = from_service_id;
  UPDATE ward SET service_id = to_service_id WHERE service_id = from_service_id;
  UPDATE service_fee_center SET service_id = to_service_id WHERE service_id = from_service_id;
  UPDATE indicator SET service_id = to_service_id WHERE service_id = from_service_id;
  DELETE FROM service WHERE id = from_service_id;
END $$

/*
CALL zMergeAccounts(fromId, toId);

DESCRIPTION
Merges two accounts by changing the account_id pointers to the new account and removing
the old one.  NOTE - you must call zRecalculatePeriodTotals() when all done with these
operations.  It isn't called here to allow operations to be batched for performance, then
committed.
*/
DROP PROCEDURE IF EXISTS zMergeAccounts
CREATE PROCEDURE zMergeAccounts(
  IN from_account_number TEXT,
  IN to_account_number TEXT
) BEGIN
  DECLARE from_account_id MEDIUMINT;
  DECLARE to_account_id MEDIUMINT;

  SET from_account_id = (SELECT id FROM account WHERE number = from_account_number);
  SET to_account_id = (SELECT id FROM account WHERE number = to_account_number);

  UPDATE general_ledger SET account_id = to_account_id WHERE account_id = from_account_id;
  UPDATE posting_journal SET account_id = to_account_id WHERE account_id = from_account_id;
  UPDATE voucher_item SET account_id = to_account_id WHERE account_id = from_account_id;
  DELETE FROM period_total where account_id = from_account_id;
  DELETE FROM account WHERE id = from_account_id;
END $$



