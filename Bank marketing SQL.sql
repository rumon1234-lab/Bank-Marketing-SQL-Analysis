CREATE DATABASE bank_marketing_db1;
DROP TABLE IF EXISTS bank_data;

CREATE TABLE bank_data (
    row_index INTEGER,
    age INTEGER,
    job VARCHAR(50),
    marital VARCHAR(20),
    education VARCHAR(30),
    is_default VARCHAR(10),
    balance INTEGER,
    housing VARCHAR(10),
    loan VARCHAR(10),
    contact VARCHAR(20),
    day INTEGER,
    month VARCHAR(10),
    duration INTEGER,
    campaign INTEGER,
    pdays INTEGER,
    previous INTEGER,
    poutcome VARCHAR(20),
    y VARCHAR(10)
);

SELECT COUNT(*) AS total_rows FROM bank_data;
SELECT * FROM bank_data LIMIT 5;
UPDATE bank_data
SET
    job = TRIM(job),
    marital = TRIM(marital),
    education = TRIM(education),
    is_default = TRIM(is_default),
    housing = TRIM(housing),
    loan = TRIM(loan),
    contact = TRIM(contact),
    month = LOWER(TRIM(month)),
    poutcome = TRIM(poutcome),
    y = LOWER(TRIM(y));
SELECT
    COUNT(*) FILTER (WHERE age IS NULL) AS null_age,
    COUNT(*) FILTER (WHERE job IS NULL OR job = '') AS null_job,
    COUNT(*) FILTER (WHERE marital IS NULL OR marital = '') AS null_marital,
    COUNT(*) FILTER (WHERE education IS NULL OR education = '') AS null_education,
    COUNT(*) FILTER (WHERE balance IS NULL) AS null_balance,
    COUNT(*) FILTER (WHERE contact IS NULL OR contact = '') AS null_contact,
    COUNT(*) FILTER (WHERE poutcome IS NULL OR poutcome = '') AS null_poutcome,
    COUNT(*) FILTER (WHERE y IS NULL OR y = '') AS null_y
FROM bank_data;

SELECT
    age, job, marital, education, balance, housing, loan, contact, day, month, duration, campaign, y,
    COUNT(*) AS dup_count
FROM bank_data
GROUP BY age, job, marital, education, balance, housing, loan, contact, day, month, duration, campaign, y
HAVING COUNT(*) > 1;

SELECT
    MIN(age) AS min_age, MAX(age) AS max_age, ROUND(AVG(age), 2) AS avg_age,
    MIN(balance) AS min_balance, MAX(balance) AS max_balance, ROUND(AVG(balance), 2) AS avg_balance,
    COUNT(*) FILTER (WHERE balance < 0) AS negative_balance_count,
    COUNT(*) FILTER (WHERE pdays = -1) AS never_contacted_before_count,
    MIN(duration) AS min_duration, MAX(duration) AS max_duration,
    MAX(campaign) AS max_campaign
FROM bank_data;

SELECT
    y,
    COUNT(*) AS total_clients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM bank_data
GROUP BY y
ORDER BY total_clients DESC;

SELECT
    job,
    COUNT(*) AS total_clients,
    ROUND(AVG(balance), 2) AS avg_balance,
    COUNT(*) FILTER (WHERE y = 'yes') AS subscribed_yes,
    ROUND(COUNT(*) FILTER (WHERE y = 'yes') * 100.0 / COUNT(*), 2) AS conversion_rate_pct
FROM bank_data
GROUP BY job
ORDER BY conversion_rate_pct DESC, total_clients DESC;


SELECT
    education,
    marital,
    COUNT(*) AS total_clients,
    ROUND(AVG(balance), 2) AS avg_balance,
    COUNT(*) FILTER (WHERE y = 'yes') AS subscribed_yes,
    ROUND(COUNT(*) FILTER (WHERE y = 'yes') * 100.0 / COUNT(*), 2) AS conversion_rate_pct
FROM bank_data
GROUP BY education, marital
ORDER BY conversion_rate_pct DESC;

SELECT
    housing AS housing_loan,
    loan AS personal_loan,
    COUNT(*) AS total_clients,
    COUNT(*) FILTER (WHERE y = 'yes') AS subscribed_yes,
    ROUND(COUNT(*) FILTER (WHERE y = 'yes') * 100.0 / COUNT(*), 2) AS conversion_rate_pct
FROM bank_data
GROUP BY housing, loan
ORDER BY conversion_rate_pct DESC;

SELECT
    month,
    COUNT(*) AS total_contacts,
    COUNT(*) FILTER (WHERE y = 'yes') AS subscribed_yes,
    ROUND(COUNT(*) FILTER (WHERE y = 'yes') * 100.0 / COUNT(*), 2) AS conversion_rate_pct
FROM bank_data
GROUP BY month
ORDER BY conversion_rate_pct DESC;

WITH segmented_clients AS (
    SELECT
        *,
        CASE
            WHEN age < 30 THEN '18-29'
            WHEN age BETWEEN 30 AND 44 THEN '30-44'
            WHEN age BETWEEN 45 AND 59 THEN '45-59'
            ELSE '60+'
        END AS age_group,
        CASE
            WHEN balance < 0 THEN 'Negative'
            WHEN balance <= 500 THEN 'Low (0-500)'
            WHEN balance <= 2000 THEN 'Medium (501-2000)'
            ELSE 'High (2000+)'
        END AS balance_tier
    FROM bank_data
)
SELECT
    age_group,
    balance_tier,
    COUNT(*) AS total_clients,
    COUNT(*) FILTER (WHERE y = 'yes') AS subscribed_yes,
    ROUND(COUNT(*) FILTER (WHERE y = 'yes') * 100.0 / NULLIF(COUNT(*), 0), 2) AS conversion_rate_pct
FROM segmented_clients
GROUP BY age_group, balance_tier
ORDER BY age_group, conversion_rate_pct DESC;




WITH job_stats AS (
    SELECT
        job,
        COUNT(*) AS total_clients,
        COUNT(*) FILTER (WHERE y = 'yes') AS subscribed_yes,
        ROUND(COUNT(*) FILTER (WHERE y = 'yes') * 100.0 / NULLIF(COUNT(*), 0), 2) AS conversion_rate_pct
    FROM bank_data
    GROUP BY job
)
SELECT
    job,
    total_clients,
    subscribed_yes,
    conversion_rate_pct,
    RANK() OVER (ORDER BY conversion_rate_pct DESC) AS conv_rate_rank,
    RANK() OVER (ORDER BY subscribed_yes DESC) AS yes_volume_rank,
    SUM(subscribed_yes) OVER (ORDER BY subscribed_yes DESC) AS running_total_yes
FROM job_stats
ORDER BY conv_rate_rank, total_clients DESC;
CREATE OR REPLACE VIEW vw_campaign_summary AS
SELECT
    row_index,
    age,
    CASE
        WHEN age < 30 THEN '18-29'
        WHEN age BETWEEN 30 AND 44 THEN '30-44'
        WHEN age BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60+'
    END AS age_group,
    job,
    marital,
    education,
    balance,
    housing,
    loan,
    contact,
    month,
    duration,
    campaign,
    pdays,
    previous,
    poutcome,
    y,
    CASE WHEN y = 'yes' THEN 1 ELSE 0 END AS is_subscribed
FROM bank_data;

SELECT * FROM vw_campaign_summary LIMIT 10;



WITH job_stats AS (
    SELECT
        job,
        COUNT(*) AS total_clients,
        COUNT(*) FILTER (WHERE y = 'yes') AS subscribed_yes,
        ROUND(COUNT(*) FILTER (WHERE y = 'yes') * 100.0 / NULLIF(COUNT(*), 0), 2) AS conversion_rate_pct
    FROM bank_data
    GROUP BY job
)
SELECT
    job,
    total_clients,
    subscribed_yes,
    conversion_rate_pct,
    RANK() OVER (ORDER BY conversion_rate_pct DESC) AS conv_rate_rank,
    RANK() OVER (ORDER BY subscribed_yes DESC) AS yes_volume_rank
FROM job_stats
ORDER BY conv_rate_rank, total_clients DESC


