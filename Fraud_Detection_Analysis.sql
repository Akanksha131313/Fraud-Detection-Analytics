use bank;
select * from transactions;

-- 1. Detecting Recursive Fraudulent Transactions

WITH fraud_chain AS
(
    SELECT
        nameOrig AS initial_account,
        nameDest AS next_account,
        step,
        amount,
        newbalanceOrig
    FROM transactions
    WHERE isFraud = 1
      AND type = 'TRANSFER'

    UNION ALL

    SELECT
        fc.initial_account,
        t.nameDest,
        t.step,
        t.amount,
        t.newbalanceOrig
    FROM fraud_chain fc
    JOIN transactions t
        ON fc.next_account = t.nameOrig
       AND fc.step < t.step
    WHERE t.isFraud = 1
      AND t.type = 'TRANSFER'
)
SELECT *
FROM fraud_chain
OPTION (MAXRECURSION 100);

--2. Analyzing Fraduelent Activity over time - 
WITH rolling_fraud AS
(
    SELECT
        nameOrig,
        step,
        SUM(isFraud) OVER
        (
            PARTITION BY nameOrig
            ORDER BY step
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS fraud_rolling
    FROM transactions
)

SELECT *
FROM rolling_fraud
WHERE fraud_rolling > 0;

-- 3. Complex Fraud Detection Using Multiple CTEs -
-- Question:
-- Use multiple CTEs to identify accounts with suspicious activity, including large transfers, consecutive transactions 
-- without balance change, and flagged transactions.

WITH large_transfers AS
(
    SELECT
        nameOrig,
        step,
        amount
    FROM transactions
    WHERE type = 'TRANSFER'
      AND amount > 500000
),
no_balance_change AS
(
    SELECT
        nameOrig,
        step,
        oldbalanceOrg,
        newbalanceOrig
    FROM transactions
    WHERE oldbalanceOrg = newbalanceOrig
),
flagged_transactions AS
(
    SELECT
        nameOrig,
        step
    FROM transactions
    WHERE isFlaggedFraud = 1
)

SELECT
    lt.nameOrig
FROM large_transfers lt
JOIN no_balance_change nbc
    ON lt.nameOrig = nbc.nameOrig
   AND lt.step = nbc.step
JOIN flagged_transactions ft
    ON lt.nameOrig = ft.nameOrig
   AND lt.step = ft.step;


