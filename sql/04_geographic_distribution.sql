/*
   04_geographic_distribution.sql
   Air Force FY2025 contract spend analysis - where the work lands

   This ranks states by the dollars performed there and adds a running share, the same way the contractor view does, so you can read how spread out or
   pooled the work is.

   I ran a data-quality check first to ensure the data made sense, and from there turned it into real findings. About 8% of transactions have no state associated with them, which checks out. Digging deeper shows that these transactions contain overseas work, foreign military sales, and classified programs that report no domestic location. I purposefully scoped non-states out of the domestic spend analysis, which ensures the percentages are true.

   Domestically, the top five states (CA, TX, VA, FL, CO) hold about 47% of the spend, and the top ten about 68%. The work pools less tightly by state than by contractor, because one big prime spreads its work across many states. The award count also highlights the flavor of a state. Texas is broad activity across roughly 4,900 awards, while Missouri is a few large programs (707 awards, $4.8B of Boeing work around St. Louis, MO) and Colorado leans heavily on space programs (where Space Force is located).
*/


-- Step 1 - Size the gap. COUNT(*) counts every row, COUNT(column) skips the blanks, and the difference is how many transactions carry no state.

SELECT
    COUNT(*)                                                   AS transactions,
    COUNT(PRIMARY_PLACE_OF_PERFORMANCE_STATE_CODE)             AS with_state,
    COUNT(*) - COUNT(PRIMARY_PLACE_OF_PERFORMANCE_STATE_CODE)  AS missing_state
FROM DEFENSE_CONTRACTS.ANALYTICS.AIR_FORCE_CONTRACT_TRANSACTIONS;
-- 105,344 rows, 96,676 carry a state, 8,668 do not (about 8%)

-- Step 2 - Rank domestic spend by state. 
SELECT
    PRIMARY_PLACE_OF_PERFORMANCE_STATE_CODE              AS state_code,
    PRIMARY_PLACE_OF_PERFORMANCE_STATE_NAME             AS state_name,
    ROUND(SUM(FEDERAL_ACTION_OBLIGATION)/1e6, 1)        AS obligated_millions,
    COUNT(DISTINCT AWARD_ID_PIID)                       AS award_count,
    ROUND(100 * SUM(FEDERAL_ACTION_OBLIGATION)
          / SUM(SUM(FEDERAL_ACTION_OBLIGATION)) OVER (), 2)   AS pct_of_total,
    ROUND(100 * SUM(SUM(FEDERAL_ACTION_OBLIGATION))
                    OVER (ORDER BY SUM(FEDERAL_ACTION_OBLIGATION) DESC)
          / SUM(SUM(FEDERAL_ACTION_OBLIGATION)) OVER (), 2)   AS cumulative_pct
FROM DEFENSE_CONTRACTS.ANALYTICS.AIR_FORCE_CONTRACT_TRANSACTIONS
WHERE PRIMARY_PLACE_OF_PERFORMANCE_STATE_CODE IS NOT NULL     -- keep domestic rows, set the blanks aside
GROUP BY PRIMARY_PLACE_OF_PERFORMANCE_STATE_CODE, PRIMARY_PLACE_OF_PERFORMANCE_STATE_NAME
ORDER BY obligated_millions DESC
LIMIT 25;

/* NOTE: I considered displaying federal action as billions, but in the end opted to keep it as millions and display it differently in Snowflake! */