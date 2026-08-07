/*
   03_award_trends.sql
   Air Force FY2025 contract spend analysis - when the money moves

   In this analysis, I ask whether Air Force spending runs steady through the year or comes in waves. I roll the daily transactions up to monthly totals so the yearly rhythm shows, and carry a running total alongside it.

   Most months sit around $7B and look calm, then two months experience a large spike. July climbs on a small number of very large awards while the transaction count stays normal, so it reads as a size effect. September climbs a different way, on roughly double the usual transaction count, which lines up with the federal fiscal year ending September 30 and money being committed before it expires ("use it or lose it"). Two spikes that look alike on the chart, driven by two different forces underneath.

   Federal FY2025 runs October 2024 through September 2025.
*/

SELECT
    DATE_TRUNC('MONTH', ACTION_DATE)                     AS action_month,   -- snap each date back to the 1st of its month
    ROUND(SUM(FEDERAL_ACTION_OBLIGATION)/1e6, 1)         AS monthly_millions,
    COUNT(*)                                             AS transactions,
    -- dollars piling up month over month across the year
    ROUND(SUM(SUM(FEDERAL_ACTION_OBLIGATION))
              OVER (ORDER BY DATE_TRUNC('MONTH', ACTION_DATE))
          /1e6, 1)                                       AS cumulative_millions
FROM DEFENSE_CONTRACTS.ANALYTICS.AIR_FORCE_CONTRACT_TRANSACTIONS
GROUP BY DATE_TRUNC('MONTH', ACTION_DATE)
ORDER BY action_month;
