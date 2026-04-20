# Analysis of the Earth's Supply of Crude Oil

**MATH 222 — Introduction to Dynamical Systems | St. John Fisher University**  
Evan Scheuermann, Lucy Haynes, Jake Scheidelman

> **Status:** In progress — further refinement and conclusion forthcoming.
> Core modeling and analysis complete.

## Overview

Crude oil is one of the most critical and finite natural resources in 
modern society. Determining how long it will last requires accounting 
for both the uncertainty in total supply estimates and the highly dynamic 
nature of consumption over time. This project builds a mathematical model 
in stages, starting from a deliberately naïve preliminary estimate and 
progressively refining it to account for real-world complexity.

The model is implemented in both R and Python via `reticulate`, combining 
data-driven regression modeling with dynamical systems simulation.

## Research Question

How long will the Earth's supply of crude oil last, and how does that 
estimate change as we account for realistic supply constraints, variable 
fuel efficiency, changing vehicle populations, and economic factors?

## Data

All datasets are from open government or public sources and are included
in the `data/` folder.

| File | Source | Description |
|------|--------|-------------|
| `world_usa_pop_data.csv` | World Bank / US Census Bureau | Historical and projected world and US population |
| `usa_data_pt2_2.csv` | Bureau of Transportation Statistics | US highway vehicle registrations by category, GDP, population density |
| `historical_oil_price_y2.csv` | — | Historical nominal and inflation-adjusted crude oil prices |
| `us_cons.csv` | — | US daily crude oil consumption |

**Setup:** Clone the repo and update the file paths in the QMD to match
your local directory before running.

## Modeling Approach

The project is structured in four parts, each building on the last.

### Part 1 — Preliminary Estimate
A baseline calculation under deliberately naïve assumptions (e.g. the 
entire Earth's crust is crude oil, constant vehicle count, uniform fuel 
efficiency). Result: ~1.43 billion years — a known gross overestimate 
used as a reference point.

### Part 2 — Refining the Model (Three Sub-Components)

**2A — Realistic Oil Supply**  
Replaces the crust assumption with best available estimates: ~6 trillion 
total barrels, 50% recovery factor, 45% gasoline yield, minus ~1.3 
trillion barrels already consumed. Revised total: ~32 trillion gallons 
of gasoline remaining as of 2020. At constant Part 1 consumption, this 
alone drops the estimate to ~55 years.

**2B — Dynamic Fuel Efficiency**  
Splits vehicles into seven categories (SUVs, cars, pickups, motorcycles, 
semi-trucks, transit buses, EVs/hybrids) and models fuel efficiency for 
each using linear regression fit to historical data, starting from 1970 
in 10-year steps. Applied in isolation, this extends the estimate to 
~5.7 billion years due to linearly growing efficiency — a known 
limitation addressed in Part 3.

**2C — Vehicle Population Dynamics**  
Models total world vehicle count over time using a logistic population 
model correlated to world population (r ≈ 0.935), with a carrying 
capacity of ~11 billion people slowly declining over time. Incorporates 
the growing proportion of electric vehicles using linear regression on 
recent US EV registration trends, projecting a full combustion-to-electric 
swap around 2300. Applied in isolation, this extends the estimate to 
~4.23 billion years.

### Part 3 — Combined Model
Integrates all three Part 2 components, aligning time series to 2020 as 
a common baseline. Maps vehicle categories between 2B and 2C via 
proportional weighting. Computes total annual gasoline consumption 
per category and aggregates across the global fleet.

**Combined result: ~140 years of gasoline remaining from 2020**, 
implying crude oil runs out around 2160. A hypothetical scenario 
accelerating EV adoption by 50 years extends this to ~700 years, 
demonstrating how dramatically electrification affects the outcome.

### Part 4 — Economic Factors
Incorporates price elasticity of oil consumption via log-linear 
regression of historical consumption changes on nominal oil price, 
with oil price projected forward using a time-based regression. 
Consumption multipliers are propagated forward using `purrr::accumulate` 
and integrated with the Part 3 model.

## Key Results

| Stage | Estimated Lifespan from 2020 |
|-------|------------------------------|
| Part 1 (naïve) | ~1.43 billion years |
| Part 2A (realistic supply only) | ~55 years |
| Part 2B (fuel efficiency only) | ~5.7 billion years |
| Part 2C (vehicle dynamics only) | ~4.23 billion years |
| Part 3 (combined) | **~140 years** |
| Part 3 (accelerated EV scenario) | ~700 years |

## Tools & Packages

- **Languages:** R and Python (via `reticulate`)
- **R packages:** `tidyverse`, `ggplot2`, `caret`, `zoo`, `data.table`,
  `reticulate`
- **Python libraries:** `numpy`, `matplotlib`, `pandas`

## Files

- `crude_oil_analysis.qmd` — Full analysis with code and narrative
- `crude_oil_analysis.pdf` — Rendered report
- `data/` — All input datasets

## Contributors

- **Evan Scheuermann** — project lead, mathematical modeling framework,
  all R and Python implementation, data sourcing and cleaning,
  visualizations, full write-up
- Lucy Haynes — supporting contributions
- Jake Scheidelman — supporting contributions

## References

- Bureau of Transportation Statistics. Schmitt et al. (2025). 
  *Transportation Statistics Annual Report 2025.*
  https://doi.org/10.21949/w2zr-3a26
- California Air Resources Board. (2022). *California moves to accelerate 
  to 100% new zero-emission vehicle sales by 2035.*
  https://ww2.arb.ca.gov/news/california-moves-accelerate-100-new-zero-emission-vehicle-sales-2035
- Geiger, J. (2019). *How Much Crude Oil Has The World Really Consumed?*
  OilPrice.com.
- Hedges, J. (2025). *How many cars are there in the world?*
  Hedges & Company.
- Kirk, K. (2024). *Electric vehicles use half the energy of gas-powered 
  vehicles.* Yale Climate Connections.
- Penn State College of Earth and Mineral Sciences. (2025). 
  *Oil and Gas Reserves.*
- United States Census Bureau. (2026). *International Database.*
  https://www.census.gov/data-tools/demo/idb/
- US Department of Energy. *Alternative Fuels Data Center: TransAtlas.*
  https://afdc.energy.gov/transatlas
- USGS. (2019). *Inside the Earth.* 
  https://pubs.usgs.gov/gip/dynamic/inside.html
- World Bank. (2025). *Population, Total.*
  https://data.worldbank.org/indicator/SP.POP.TOTL
