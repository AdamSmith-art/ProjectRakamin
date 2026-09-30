-- Daily Transaction
CREATE OR REPLACE FUNCTION DailyTransaction(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    "Date" DATE,
    "TotalTransactions" BIGINT,
    "TotalAmount" NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(transactiondate),
        COUNT(*),
        SUM(amount)
    FROM facttransaction
    WHERE DATE(transactiondate) BETWEEN start_date AND end_date
    GROUP BY DATE(transactiondate)
    ORDER BY DATE(transactiondate);
END;
$$ LANGUAGE plpgsql;

-- Call DT
SELECT *
FROM DailyTransaction(
    DATE '2024-01-18',
    DATE '2024-01-20'
);


-- BalancePerCustomer
CREATE OR REPLACE FUNCTION BalancePerCustomer(
    name VARCHAR
)
RETURNS TABLE (
    "CustomerName" VARCHAR,
    "AccountType" VARCHAR,
    "Balance" NUMERIC,
    "CurrentBalance" NUMERIC
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.customername,
        a.accounttype,
        a.balance,
        a.balance +
        COALESCE(
            SUM(
                CASE
                    WHEN t.transactiontype = 'Deposit'
                    THEN t.amount
                    ELSE -t.amount
                END
            ), 0
        )
    FROM dimcustomer c
    JOIN dimaccount a
        ON c.customerid = a.customerid
    LEFT JOIN facttransaction t
        ON a.accountid = t.accountid
    WHERE c.customername ILIKE '%' || name || '%'
      AND a.status = 'active'
    GROUP BY
        c.customername,
        a.accounttype,
        a.balance,
        a.accountid;
END;
$$ LANGUAGE plpgsql;


-- Call BPC
SELECT *
FROM BalancePerCustomer('Shelly');
