# Build Notes (private, do not commit)

Personal where-I-got-stuck log. This is for future-me, not for readers. Add `NOTES.md` to `.gitignore` so it never gets pushed. Dump anything here: menu locations, dead ends, "it finally worked when I..." moments.

---

## Tableau Public friction

- **Edit Axis vs Format are different menus.** Double-clicking an axis opens *Edit Axis* (range, scale, titles), which is NOT where number formatting lives. Number format is: right-click the axis or pill -> **Format** (not "Edit Axis"). The most reliable route is skipping the axis entirely: Data pane -> right-click the field -> **Default Properties -> Number Format -> Custom**. That one applies everywhere (axis, tooltip, labels) and carries to the dashboard.
- **Number format not "taking".** The "$0.0,\"B\"" trailing-comma scaler (divide by 1000) failed twice: once from a missing comma, once from smart/curly quotes when pasted. Fix: retype straight quotes directly in the box. Cleaner fix overall: make a calc field that divides explicitly (e.g. `[obligated_millions] / 1000`) and format with a plain "$0.0\"B\"" so there is no scaling magic to get wrong.
- **Every-other-month labels + month ordering.** A continuous date axis thins its own labels and can order by calendar month (Jan-Dec), which buries the fiscal-year story. Two toggles: right-click the month pill -> **Discrete** forces a header under every bar; and pick the year-based Month level (reads "Oct 2024") so ordering is chronological, not calendar-month.
- **Label abbreviation is separate from rotation.** Rotating labels does not shorten them. Shortening is a date-format setting: right-click the discrete pill -> Format -> Header -> Dates -> "mmm yyyy".
- **No "Label" button on the Marks card in this version.** Turn labels on via top menu **Worksheet -> Show Mark Labels**. Add a second field as a label by dragging it onto the Marks card and setting the tile to Label.
- **Two labels stack on separate lines.** Fix by editing the label text (Label tile -> Text -> "..." box) to put both tags on one line with a separator, e.g. `<dollars> (<pct>)`.
- **Calc fields do not cross data sources.** Each CSV is its own source, so the billions calc field had to be remade on each sheet.

## Snowflake / Snowsight friction

- (add as they come up)

## SQL debugging log

- **100% "Other / Unclassified" = wrong input column.** The family rollup returned everything in the catch-all bucket because it queried the curated `ANALYTICS` column that holds the code, not the RAW `..._CODE` column that actually holds the text. Diagnostic habit: when a CASE dumps everything into ELSE, `SELECT DISTINCT <col>` first to see what the column really contains.

## Things to remember next time

- Standardize the display unit (billions) across all sheets *before* building, not after. Retrofitting units meant re-touching every sheet.
- Decide fiscal-year ordering at the first chart, not the third.

## Open questions / to revisit

- Reconcile the handoff note claiming the curated table was rebuilt to fix the pricing-column swap, since the curated column still returned codes. Which source did each of `05` and `05b` actually read? (Resolved for the analysis by reading RAW's text column, but worth confirming the curated table's state so LEARNINGS stays accurate.)
