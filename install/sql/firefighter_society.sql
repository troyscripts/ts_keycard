-- Brandweerrekening voor de bestaande job firefighter.
-- Uitvoeren in de gameserverdatabase terwijl de server uit staat.
-- Bestaande saldi, jobs en job_grades blijven behouden. Herhaald uitvoeren is veilig.
START TRANSACTION;
INSERT INTO addon_account (name, label, shared)
SELECT 'society_firefighter', 'Brandweer', 1
WHERE NOT EXISTS (SELECT 1 FROM addon_account WHERE name = 'society_firefighter');
INSERT INTO addon_account_data (account_name, money, owner)
SELECT 'society_firefighter', 0, NULL
WHERE NOT EXISTS (
    SELECT 1 FROM addon_account_data
    WHERE account_name = 'society_firefighter' AND owner IS NULL
);
COMMIT;
-- Controle: shared moet 1 zijn; precies één gedeelde saldoregel (owner NULL).
SELECT name, label, shared FROM addon_account WHERE name = 'society_firefighter';
SELECT account_name, money, owner FROM addon_account_data WHERE account_name = 'society_firefighter';
