/*
   02_contractor_concentration.sql
   Air Force FY2025 contract spend analysis - who gets the money

   I wanted to see how concentrated Air Force spending is, and in whose hands. This ranks contractors by obligated dollars and adds a running share, so you can read straight down the list and watch how few names it takes to reach a big slice of the budget.

   One cleanup had to happen first. The same company shows up under a few spellings in federal data. "LOCKHEED MARTIN CORPORATION" and "LOCKHEED MARTIN CORP" are the same firm. If I rank the raw names, one company gets split across rows and looks smaller than it really is, so I fold the obvious variants together before I add anything up.

   Boeing sits at the top with 13.89% of all obligated dollars. Boeing and Lockheed together already reach about a quarter of the budget (26%), and the top five firms hold roughly 41%. The money pools heavily among the big prime integrators.
*/

WITH normalized AS (
    -- clean the names first, still one row per transaction
    SELECT
        CASE
            WHEN RECIPIENT_NAME IN ('LOCKHEED MARTIN CORPORATION', 'LOCKHEED MARTIN CORP')
                THEN 'LOCKHEED MARTIN'
            WHEN RECIPIENT_NAME IN ('NORTHROP GRUMMAN SYSTEMS CORPORATION', 'NORTHROP GRUMMAN SYSTEMS CORP')
                THEN 'NORTHROP GRUMMAN'
            WHEN RECIPIENT_NAME IN ('RAYTHEON COMPANY', 'RTX CORPORATION')
                THEN 'RAYTHEON / RTX'      -- RTX owns Raytheon, so I merged them
            ELSE RECIPIENT_NAME
        END                                                  AS contractor,
        FEDERAL_ACTION_OBLIGATION,
        AWARD_ID_PIID
    FROM DEFENSE_CONTRACTS.ANALYTICS.AIR_FORCE_CONTRACT_TRANSACTIONS
)
SELECT
    contractor,
    ROUND(SUM(FEDERAL_ACTION_OBLIGATION)/1e6, 1)         AS obligated_millions,
    COUNT(DISTINCT AWARD_ID_PIID)                        AS award_count,
    -- each firm's slice of every obligated dollar
    ROUND(100 * SUM(FEDERAL_ACTION_OBLIGATION)
          / SUM(SUM(FEDERAL_ACTION_OBLIGATION)) OVER (), 2)   AS pct_of_total,
    -- running slice down the ranking, so the top few visibly add up fast
    ROUND(100 * SUM(SUM(FEDERAL_ACTION_OBLIGATION))
                    OVER (ORDER BY SUM(FEDERAL_ACTION_OBLIGATION) DESC)
          / SUM(SUM(FEDERAL_ACTION_OBLIGATION)) OVER (), 2)   AS cumulative_pct
FROM normalized
GROUP BY contractor
ORDER BY obligated_millions DESC
LIMIT 25;
