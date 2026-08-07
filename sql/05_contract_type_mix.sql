/*
   05_contract_type_mix.sql
   Air Force FY2025 contract spend analysis - how the contracts carry risk

   Contract pricing type comes down to a simple question: Who eats the cost if a program runs over. In this sql analysis, I explore this at two levels of resolution. The first analysis lists all 13 detailed pricing types fully, while the second analysis folds the pricing types into the three main families for better ingestion into future dashboards (fixed-price, cost-reimbursable, and time and materials.)

   It's important to highlight a data trap uncovered in the raw data. The data pulled from USASpending.gov unfortunately swaps columns that would muddy results if not caught. For example, the column named TYPE_OF_CONTRACT_PRICING_CODE actually holds the readable text like "FIRM FIXED PRICE", and the one named TYPE_OF_CONTRACT_PRICING holds the one-letter code like "J". I classify off the text column in both queries, which is why the text matching works. Reading the wrong column would quietly drop every row into the unclassified bucket.

   Firm-fixed-price is the biggest single type by a wide margin. The more interesting piece is the incentive-fee work. The two incentive types together carry about $21B across only ~339 awards, so the biggest and riskiest programs live in a very small number of awards. Rolled up to families, the split runs about 58% fixed-price, 41% cost-reimbursable, and 1% time and materials. Roughly even between the family where the contractor carries the overrun risk and the family where the government does, which reads like a portfolio balanced across steady production and less certain R&D.
*/


-- Query 1 - Every pricing type, ranked by dollars.
SELECT
    TYPE_OF_CONTRACT_PRICING_CODE                       AS pricing_type,   -- swapped at source, this column holds the readable text
    ROUND(SUM(FEDERAL_ACTION_OBLIGATION)/1e6, 1)        AS obligated_millions,
    COUNT(DISTINCT AWARD_ID_PIID)                       AS award_count,
    ROUND(100 * SUM(FEDERAL_ACTION_OBLIGATION)
          / SUM(SUM(FEDERAL_ACTION_OBLIGATION)) OVER (), 2)   AS pct_of_total
FROM DEFENSE_CONTRACTS.RAW.AIR_FORCE_FY2025_RAW
WHERE TYPE_OF_CONTRACT_PRICING_CODE IS NOT NULL
GROUP BY TYPE_OF_CONTRACT_PRICING_CODE
ORDER BY obligated_millions DESC;


-- Query 2 - The same dollars folded into three risk families for the dashboard.
WITH classified AS (
    SELECT
        AWARD_ID_PIID,
        FEDERAL_ACTION_OBLIGATION,
        CASE
            /*
               I check "FIXED PRICE" first on purpose. "COST PLUS FIXED FEE" has the word fixed in it yet belongs in the cost family, so the full phrase has to be tested ahead of the word cost.
            */
            WHEN TYPE_OF_CONTRACT_PRICING_CODE LIKE '%FIXED PRICE%'        THEN 'Fixed-Price'
            WHEN TYPE_OF_CONTRACT_PRICING_CODE LIKE '%COST%'               THEN 'Cost-Reimbursable'
            WHEN TYPE_OF_CONTRACT_PRICING_CODE LIKE '%TIME AND MATERIALS%'
              OR TYPE_OF_CONTRACT_PRICING_CODE LIKE '%LABOR HOURS%'        THEN 'Time & Materials'
            ELSE 'Other / Unclassified'
        END AS pricing_family
    FROM DEFENSE_CONTRACTS.RAW.AIR_FORCE_FY2025_RAW
    WHERE TYPE_OF_CONTRACT_PRICING_CODE IS NOT NULL   -- same blank filter, so both queries share one denominator
)
SELECT
    pricing_family,
    ROUND(SUM(FEDERAL_ACTION_OBLIGATION) / 1e6, 1)      AS obligated_millions,
    COUNT(DISTINCT AWARD_ID_PIID)                       AS award_count,
    /*
       inner SUM totals each family, the empty OVER () totals the whole set,
       so this column reads as each family's share of everything
    */
    ROUND(
        100 * SUM(FEDERAL_ACTION_OBLIGATION)
            / SUM(SUM(FEDERAL_ACTION_OBLIGATION)) OVER (), 2
    )                                                   AS pct_of_total
FROM classified
GROUP BY pricing_family
ORDER BY obligated_millions DESC;
