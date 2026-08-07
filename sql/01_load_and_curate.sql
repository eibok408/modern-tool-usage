/*
   01_load_and_curate.sql
   Air Force FY2025 contract spend analysis

   I pulled a full fiscal year of Air Force prime contract transactions from USASpending.gov and built one clean table to run everything else against. The raw export is 297 columns of federal reporting fields, most of which I never touch. This file lands the raw file, carves out the nine columns the analysis actually needs, and confirms the totals came in whole.

   The data came from USASpending.gov Award Search, filtered down to Contracts, Department of Defense, Department of the Air Force, fiscal year 2025, in CSV format. Everything runs in Snowflake, from Snowsight worksheets.
*/

USE WAREHOUSE COMPUTE_WH;
USE DATABASE DEFENSE_CONTRACTS;

/*
   Step 1 - Load the raw file.

   I loaded the massive 240MB csv through the Snowsight "Load Data into Table" wizard and let it infer the schema. The setting that mattered was fields optionally enclosed by " , because several free-text columns carry commas and line breaks inside them that would otherwise split a row in the wrong place. I set on-error to continue so a few messy rows could not stall the whole load. A handful of columns had names Snowflake would not accept, and I dropped those at load since the analysis never uses them.
*/

-- confirm the load actually loaded properly

SELECT COUNT(*) AS raw_row_count
FROM DEFENSE_CONTRACTS.RAW.AIR_FORCE_FY2025_RAW;


/*
   Step 2 - Keep the raw and working layers apart.

   I leave the untouched raw table in its own schema and build the curated table in a second one. That way any number traces back to the original file, and anyone reading this can see exactly what I changed.
*/
CREATE SCHEMA IF NOT EXISTS DEFENSE_CONTRACTS.ANALYTICS;


/*
   Step 3 - Build the curated table, nine columns out of the original 297. Who was paid, how much, when, where the work happens, how the contract prices risk, and what was bought.
*/
CREATE OR REPLACE TABLE DEFENSE_CONTRACTS.ANALYTICS.AIR_FORCE_CONTRACT_TRANSACTIONS AS
SELECT
    AWARD_ID_PIID,                              -- one award carries many transactions
    ACTION_DATE,
    RECIPIENT_NAME,
    FEDERAL_ACTION_OBLIGATION,                  -- the dollars, every analysis leans on this
    PRIMARY_PLACE_OF_PERFORMANCE_STATE_CODE,
    PRIMARY_PLACE_OF_PERFORMANCE_STATE_NAME,
    TYPE_OF_CONTRACT_PRICING,
    PRODUCT_OR_SERVICE_CODE,
    PRODUCT_OR_SERVICE_CODE_DESCRIPTION
FROM DEFENSE_CONTRACTS.RAW.AIR_FORCE_FY2025_RAW;


/*
   Step 4 - Sanity-check the totals.

   This is the baseline I hold every later number against, 105,344 transactions, 56,581 distinct awards, $98.38B obligated. The dollar figure is net. Federal data records money pulled back off contracts as negative obligations, and I let those net out on purpose, so this reflects what the Air Force truly committed for the year.
*/
SELECT
    COUNT(*)                                     AS transactions,
    COUNT(DISTINCT AWARD_ID_PIID)                AS distinct_awards,
    ROUND(SUM(FEDERAL_ACTION_OBLIGATION)/1e9, 2) AS total_obligated_billions
FROM DEFENSE_CONTRACTS.ANALYTICS.AIR_FORCE_CONTRACT_TRANSACTIONS;
