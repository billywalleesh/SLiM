# Building the population-size chart in Excel

Open `population_size_chart.xlsx`. The data is already summed across the four demes and trimmed to the observed-climate years, so you can go straight to charting.

**What's in the sheet**

| Column | Contents |
|---|---|
| A | Year, 1970–2025 |
| B | Population size (total across four demes) |
| C | Ne, heterozygosity-based |
| D | Ne, inbreeding-based |
| E | One number: population size at the predictor year |
| F | One number: population size at the outcome year |

Columns E and F are blank except for a single row each. That blankness is the trick — it's what makes Excel draw one dot instead of a line.

The yellow cells in column H are the only ones to edit. The summary below them recalculates live.

---

## 1. The base line

1. Select **A1:B57** (click A1, then Shift-click B57).
2. **Insert → Charts → Insert Line or Area Chart → Line** (first 2-D option).
3. Click the chart title and the legend, press **Delete** on each. You'll add your own text later.
4. Drag a corner to make it roughly twice as wide as it is tall.

## 2. Add the two marker series

5. Right-click the chart → **Select Data**.
6. **Add** → Series name: click cell **E1** → Series values: select **E2:E57** → OK.
7. **Add** again → Series name: **F1** → Series values: **F2:F57** → OK.
8. On the right, under *Horizontal (Category) Axis Labels*, click **Edit** → select **A2:A57** → OK → OK.

Nothing visible will change yet. That's expected.

## 3. Turn the markers into dots

9. Click the chart, then use the **series selector** at the top of the Format pane (or click directly on the chart area near the year 2000) to select **Marker: predictor year**.
10. Right-click → **Format Data Series** → paint-can icon:
    - **Line → No line**
    - **Marker → Marker Options → Built-in**, Type: circle, Size: **10**
    - **Marker → Fill → Solid fill** → hex **2A78D6**
    - **Marker → Border → Solid line** → white, width **2 pt**
11. Repeat for **Marker: outcome year**, using hex **EB6834**.

You should now see two dots sitting on the line.

## 4. The vertical drop lines

This is the only fiddly part. Excel draws them as *error bars*.

12. Select the **Marker: predictor year** series again.
13. **Chart Design → Add Chart Element → Error Bars → More Error Bars Options**.
14. In the Format pane, under *Vertical Error Bar*:
    - Direction: **Minus**
    - End Style: **No Cap**
    - Error Amount: **Percentage**, value **100**
15. Still in that pane, click the paint-can → **Line → Solid line**, colour **2A78D6**, width **2.25 pt**, **Dash type: Dash**.
16. Repeat steps 12–15 for the outcome series in **EB6834**.

A minus error bar of 100% runs from the point down to zero — which is exactly the dashed line you want.

> If Excel also adds *horizontal* error bars, click one and press Delete.

## 5. Format the population line

17. Click the population-size line → **Format Data Series → Line**: Solid line, black, width **3 pt**, and under *Marker* choose **None**.

## 6. Axes and gridlines

18. Click the vertical axis → **Format Axis → Bounds**: Minimum **0**, Maximum **2450**.
19. Click the horizontal axis → **Labels → Interval between labels → Specify interval unit: 10**. That gives 1970, 1980, … 2020.
20. Click a gridline → set it to light grey, **0.75 pt**. Or delete them entirely.
21. **Chart Design → Add Chart Element → Axis Titles**: vertical = `Population size`, horizontal = `Year`.
22. Select the whole chart → **Home tab** → font **Arial**, size **12**.

## 7. The question

23. **Insert → Shapes → Lines → Arc.** Draw it between the two dots, then **Format Shape → Line → End Arrow type** → arrowhead. Colour it mid-grey, 2 pt.
24. **Insert → Text Box**, twice:
    - `does Ne here…` — Arial Bold 18, colour **2A78D6**, above the 2000 dot
    - `…predict Ne here?` — Arial Bold 18, colour **EB6834**, above the 2025 dot

> Excel can't colour individual axis labels, so if you want bold coloured "2000" and "2025" under the axis, add them as two more text boxes and position them by hand.

## 8. Out of Excel

25. Right-click the chart border → **Save as Picture** → PNG. Or **Copy**, then in PowerPoint use **Paste Special → Picture (Enhanced Metafile)** so it stays sharp when scaled.

---

## Changing the years

Type a different year into the yellow cells (I3, I4) and the summary updates. The dots won't move on their own — delete the number from column E or F and retype it on the row you want. Two edits, not one, but it keeps the file free of error values.

## What the numbers say

With 2000 as predictor and 2025 as outcome, between those years the run retains:

- **Population size: 37.0%** — a two-thirds collapse
- **Ne from inbreeding: 36.6%** — tracks the population almost exactly
- **Ne from heterozygosity: 98.7%** — essentially unchanged

That is the finding, and it is about the *estimator*, not the population. Pick one
measure and the indicator sees the collapse; pick the other and it sees nothing.

## Adding the third line

Columns C and D plot straight onto the same axis as B — all three are counts of
individuals, so no secondary axis is needed. Add them as two more series
(Select Data → Add), give C orange and D blue, leave B black, and label the three
line ends directly instead of using a legend.

---

Source: `grib_4pop_ne_ramp_weak_sel050_K500_rep_1_seed_186306227.csv` — weak migration, selection 0.05, K = 500, summed across four demes, observed-climate phase only.
