# U.S. Air Force Contract Spending, FY2025

An independent analysis of federal defense contract obligations, built to practice modern data warehousing on real, messy,and domain-relevant data. Raw data loaded and modeled in "Snowflake", four analyses written in"SQL", results visualized in "Tableau Public.

**Live dashboard:** https://public.tableau.com/app/profile/emem.ibok/viz/AirForceSpendingin2025/Dashboard1

**Scope note up front: this is a familiarity-level project. It demonstrates the ability to load real data into a cloud warehouse, model it into a clean analytical layer, write correct aggregate and window-function SQL, handle real data-quality problems, and turn results into a defensible visual narrative. It is not a data-engineering pipeline or a production system.**

---

## Purpose of the Project

Federal contract spend is available o the public, but most people (re: citizens) rarely read past the headline dollar figures. This project takes one agency's full fiscal year and asks four operational questions an average program/strategy team would actually care about: which companies or contractors receive the money, where is the contracted work happening, when obligated funds gets spent, and how the contracts allocate cost risk (i.e. what type of award is it?)

To no ones suprise, a singular thread is present in every analysis.A small number of large awards drives a disproportionate share of dollars, while a large number of small activities drive volume.Separating those two is the analytical POV of the whole project.

## The data

- **Source:** USASpending.gov, Contracts, Department of Defense, Department of the Air Force, FY2025 (full-year CSV file).
- **Reproduction:** Filter USASpending's Award Search to Contracts -> Department of Defense -> Department of the Air Force -> FY2025 and export the CSV. The raw file is intentionally not committed to this repo (it is large and publicly available at the source). The `sql/` files document exactly how it was loaded and modeled in Snowflake. 
- **Verified baseline:** 105,344 transactions, 56,581 distinct awards, $98.38B net obligated (net includes negative deobligations, which is correct and intentional).

## Findings

**1. Contractor concentration is high.** Boeing is the single largest recipient of Air Force awards, with an astounding 13.9% of obligated dollars. More importantly, the top five contractors together account for in 40.6%. Award counts separate the primes that win a few very large awards from vendors with many small actions.

**2. Air Force spending is steady, but experiences two distinct spikes through the fiscal yearfor two distict reasons.** Monthly obligations sit ~$7B, with a July spike ($12.8B, driven by a handful of large awards at normal transaction volume) and a September spike ($13.7B, driven by roughly double the normal transaction count). September's surge is consistent with fiscal year-end obligation deadlines (use it or lose it). July on the other hand is different, as the volume remained the same, but the size/scope of award activies increased.

**3. Work concentrates geographically, but less sharply than by contractor.** The top five states (CA, TX, VA, FL, CO) account for 46.6% of domestic obligated dollars. This is logical when understanding where  government/space contractor presence is high. The top ten reach 68.4%. Geography is softer than contractor concentration because a single prime spreads work across many states.

**4. The contract mix is a near-even split between two risk models.** Fixed-price work (58%) places cost-overrun risk on the contractor. When accounting for program overruns (like T-7 or VC-25B), the federal government seems to reign in on "blank check" contracting, ensuring contractors are responsible for appropriately scoping and sticking to the proposed costs to develop or deliver on time and within schedule. Cost-reimbursable work (41%) places it on the government. This type of work tends to be maintenance, modernization, or support of current programs.  Time-and-materials is negligible (1%). A roughly balanced split signals a portfolio spanning mature production programs and uncertain-scope R&D.

## Messy data and how I got over

Real federal data does not arrive clean. Handling that was half the work and is the part most worth reading.

- **Multiline CSV fields.** The export contains free-text fields with embedded line breaks, which break a naive load. Handled at load time with `FIELD_OPTIONALLY_ENCLOSED_BY = '"'` and `ON_ERROR = CONTINUE` within the snowflake ingestion UI.
- **Mislabeled source columns.** 'Trust but verify' is real! The contract-pricing columns are swapped at the source: the field named `TYPE_OF_CONTRACT_PRICING_CODE` holds the readable text ("FIRM FIXED PRICE") while `TYPE_OF_CONTRACT_PRICING` holds the single-letter code ("J"). The contract-type analysis classifies off the correct (text) column, whereas if this was not caught, getting this backward silently routes every row to "unclassified."
- **Unstandardized recipient names.** The same company appears under multiple variants (LOCKHEED MARTIN CORPORATION vs LOCKHEED MARTIN CORP). Normalized with `CASE` before ranking, or contractor concentration is understated.
- **Meaningful nulls.** 8.2% of transactions (8,668) have a null place-of-performance state, representing overseas, foreign military sales, or classified work. The geography analysis is scoped to domestic spend and excludes them explicitly, keeping the percentage denominators honest.

## What's in this repo

```
sql/
  01_load_and_curate.sql        			Load raw CSV, build the curated analytics table, and validate
  02_contractor_concentration.sql   		Pareto concentration, name normalization, and usage of window functions
  03_award_trends.sql           			Monthly spend and running total
  04_geographic_distribution.sql    		Spend by state
  05_contract_type_mix.sql      			Detailed 13-type pricing breakdown (incentive-fee finding)
  05b_contract_family_rollup.sql    		3-family risk rollup for the dashboard
results/
  Dashboard screenshot and any exported result CSVs
LEARNINGS.md                    SQL concepts demonstrated (window functions, execution order, data-quality habits)
README.md                       This file
```

## Data model (curated table)

`DEFENSE_CONTRACTS.ANALYTICS.AIR_FORCE_CONTRACT_TRANSACTIONS`, built via CTAS from the raw landing table. Nine columns: `AWARD_ID_PIID`, `ACTION_DATE`, `RECIPIENT_NAME`, `FEDERAL_ACTION_OBLIGATION`, place-of-performance state code and name, contract-pricing type, and product/service code and description.

## Tools

Snowflake (free trial, Snowsight SQL worksheets) for the warehouse and all SQL. Tableau Public for visualization; the free tier is file-based, so each query result was exported as CSV and connected as a text file rather than via a live warehouse connector.
