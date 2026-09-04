# Learnings

The SQL concepts this project demonstrates and the analytical judgment calls behind the findings. Written to be useful to anyone reading the `sql/` files, and to document why certain decisions were made rather than assumed.

---

## SQL concepts

### Window functions: the frame is set by what you put in `OVER()`

Even with solid experience with SQL, I never used the clause `over` in queries until this project. For this project, I used `over` to alter the window function across the rows in different ways to achieve different results.

- `SUM(x) OVER ()` with an empty window computes one total across the entire result set and repeats it on every row. The result is that every row gets a grand total to divide against, setting the stage for a percent of total without he needs of additional joins or subqueries.
- `SUM(x) OVER (ORDER BY action_month)` adds an `ORDER BY`, and that ordering silently redefines the frame to "everything up to and including the current row." The same `SUM` now produces a running (cumulative) total instead of a grand total.

Both show up directly in the analysis. The empty window  drives concentration percentages, and the ordered version of the same calculation drives data points for a cumulative line.

### Aggregating an aggregate: `SUM(SUM(x)) OVER ()`

The percent-of-total pattern nests two levels. The inner `SUM(x)` is the `GROUP BY` aggregate, computed per group (per contractor, per family). The outer `SUM(...) OVER ()` is a window function that runs after the grouping and sums those per-group totals into a single grand total. It makes sense to read from the inside and expand outward. Aggregate within groups first, then aggregate across groups.

### Execution order ensures the percentages are accurate

The clause order that matters here is: `FROM` then `WHERE` then `GROUP BY` then `HAVING` then window functions then `ORDER BY` then `LIMIT`/`TOP`.

One major consequences shaped the analyses:

- `LIMIT`/`TOP` runs last, after the window functions have already computed. This means a "show top 15" display filter does not corrupt percentages that were computed across the full set. This is worth knowing  when a chart shows only the top 15 contractors but the cumulative line was calculated on all of them: the line topping out below 100% is a display effect.

### CTE plus `CASE` for normalization and decoding

I'm familiar with cases, and common table expressions plus `CASE` handled two additional "data cleaning" jobs for me. First, case allowed me to roll all recipient-name variants into a single canonical name before ranking (see LOCKHEED). Second, case allowed me to classify detailed pricing types into three  major risk families (FIXED PRICE, COST, TIME & MAT).

One transferable lesson from the risk family breakdown is that `CASE` order matters. "COST PLUS FIXED FEE" contains the word FIXED but is a cost-reimbursable contract. The `CASE` has to test for the full phrase "FIXED PRICE" before it tests for "COST," or that row gets misclassified. Check the most specific condition first.

---

## Data-quality habits

### Compare `COUNT(*)` to `COUNT(column)` before ranking anything

The gap between the two will illuminate how many nulls are present, and a deeper dive determines whether the data is bad or the nulls are purposeful. In this dataset, 8.2% of transactions (8,668 of 105,344) have a null place-of-performance state. At first thought, I assumed it was noise, but upon a closer look and reasoning, a series of explanations can account for this, like representation of overseas, foreign military sales, and classified work. Knowing the gap existed before ranking states is what turned "geography" into the more defensible "domestic geography," with the nulls excluded explicitly and the denominator scoped to match.

### Net versus gross obligations

Federal obligation data includes negative values (deobligations, where money is pulled back off a contract). Summing the column gives a net figure. That is the correct and intentional choice here, but the lesson is to know which one you are reporting. A net total and a gross total answer different questions, and reporting one while implying the other is a quiet way to be wrong.

### Name normalization changes the answer, not just the tidiness

The same contractor appears under several spellings (for example, LOCKHEED MARTIN CORPORATION and LOCKHEED MARTIN CORP). Left alone, a ranking splits one company's spend across multiple rows and understates its true concentration. Normalizing before ranking materially changes the concentration finding.

---

## Source and domain gotchas

### Columns can be mislabeled at the source

In this dataset the two contract-pricing columns are swapped. The field named `TYPE_OF_CONTRACT_PRICING_CODE` holds the readable text ("FIRM FIXED PRICE"), and the field named `TYPE_OF_CONTRACT_PRICING` holds the single-letter code ("J"). Classifying off the wrong (code) column sends every row to "unclassified," and because the query still runs and returns a clean-looking result, may go unnoticed. When i didn't get the output I expected, I quadruple checked my query, and then I chceked the source data to see what was found in the columns I pulled from. the lesson here distinct column values can help identify suspect results when your logic or queries don't feel right.

### Federal fiscal year runs October to September

The government fiscal year ends September 30. Ordering a monthly spend chart by calendar month puts September in the middle and buries the year-end pattern. Ordering by fiscal sequence puts September last, where the year-end obligation surge is visible as the final bar.

---

## Tool boundaries

### Tableau Public's free tier is file-based

There is no live Snowflake connector on the free tier, that is a paid Desktop/Cloud feature. The workflow is therefore: run each analysis in Snowflake, export the result grid as CSV, and connect each CSV as a text-file data source in Tableau Public. A practical consequence is that each sheet has its own separate data source, so calculated fields do not carry across sheets and have to be recreated per sheet.

### Pick one unit scale and apply it everywhere

With obligations ranging from thousands to tens of billions, the display unit is a choice. The decision here was to standardize on billions across every panel. A dashboard that mixes millions on one chart and billions on another reads as two different measurement systems and undercuts trust in the numbers, even when every figure is individually correct.
