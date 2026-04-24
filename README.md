# 📈 Time Series Analysis and Forecasting of Exchange Rates in Lebanon

> **Course Project** — Business, Economic, and Financial Data  
> Università degli Studi di Padova · Department of Mathematics · MSc Data Science  
> **Author:** Ali Sarini · **Student ID:** 2121552  
> **Supervisor:** Prof. Mariangela Guidolin · **Academic Year:** 2024–2025

---

## 📋 Table of Contents

- [Overview](#overview)
- [Background](#background)
- [Dataset](#dataset)
- [Project Structure](#project-structure)
- [Methodology](#methodology)
- [Results](#results)
- [Requirements](#requirements)
- [Usage](#usage)
- [References](#references)

---

## Overview

This project analyzes and forecasts the **Lebanese Pound (LBP) / US Dollar exchange rate** from 2019 to 2024 using time series modeling. Three modeling approaches are compared:

| Model | Type | External Variables |
|-------|------|--------------------|
| ARIMA | Univariate | ❌ |
| ETS (Exponential Smoothing) | Univariate | ❌ |
| ARIMAX | Multivariate | ✅ CPI + Foreign Currency Reserves |

The **ARIMAX** model achieved the best forecasting performance, with an MAE of **4.83** and RMSE of **5.26**, substantially outperforming the univariate approaches.

---

## Background

Since 2019, Lebanon has experienced one of the most severe economic collapses in modern history. The Lebanese Pound lost over **98% of its value** against the USD. In February 2023, the Central Bank of Lebanon officially devalued the exchange rate by 90%, yet the black-market gap persisted.

This volatility makes accurate exchange rate forecasting critical for policymakers, investors, and businesses navigating the uncertain financial landscape.

---

## Dataset

The dataset was assembled from four sources, covering **monthly data from January 2019 to December 2024** (72 observations).

| Variable | Source | Description |
|----------|--------|-------------|
| `Close` | World Bank | Monthly LBP/USD closing exchange rate (normalized ÷ 1,000) |
| `fcb` | Banque du Liban | Foreign currency reserves (billions USD) |
| `cpi` | Banque du Liban | Consumer Price Index |
| `interest` | Banque du Liban | USD deposit average interest rates |

**File:** `Exchange_Rate_Adjusted.csv`

### Descriptive Statistics

| Variable | Min | Mean | Max | Std Dev |
|----------|-----|------|-----|---------|
| Exchange Rate | 1.515 | 38.553 | 98.265 | 37.311 |
| CPI | 0.096 | 2.210 | 6.896 | 2.515 |
| Foreign Currency Reserves | 8.759 | 16.785 | 31.932 | 8.166 |
| Interest Rate | 0.020 | 0.185 | 6.610 | 2.166 |

---

## Project Structure

```
📦 Lebanon-Exchange-Rate-Forecasting
├── 📄 README.md
├── 📊 Exchange_Rate_Adjusted.csv         # Main dataset
├── 📝 ARIMA_and_Exponential_Smoothing.R  # ARIMA & ETS modeling script
├── 📝 ARIMAX.R                           # ARIMAX modeling script
└── 📄 Report_Ali_Sarini.pdf              # Full project report
```

---

## Methodology

### 1. Exploratory Data Analysis
- Visualized LBP/USD exchange rate, foreign currency reserves, and CPI trends
- Computed Pearson correlation matrix — CPI (r = 0.960) and FCB (r = −0.786) showed strongest correlation with exchange rate; interest rate (r = −0.599) was excluded

### 2. Preprocessing
- **Train/Test Split:** Jan 2019–Dec 2023 (60 obs) / Jan 2024–Dec 2024 (12 obs)
- **Box-Cox Transformation:** Applied to stabilize variance (λ = 0.302 for exchange rate)
- **Stationarity Testing:** KPSS test confirmed non-stationarity; first-order differencing applied (KPSS statistic dropped from 1.539 → 0.115)
- No seasonal differencing required (`nsdiffs() = 0`)

### 3. ARIMA Modeling
Five candidate models were evaluated using AICc:

| Model | AICc |
|-------|------|
| ARIMA(1,1,0) | 24.735 |
| ARIMA(1,1,1) | 24.963 |
| ARIMA(0,1,1) | 23.648 |
| ARIMA(1,1,1) + Drift | 24.963 |
| **ARIMA(0,1,1) + Drift** | **18.064** ✅ |

Best model equation:
$$Y_t = 0.153 + (1 - 0.503B)^{-1}\epsilon_t$$

Ljung-Box p-value: **0.864** → residuals are white noise.

### 4. ETS Modeling
Four exponential smoothing variants were tested:

| Model | AICc | Test RMSE | Test MAPE |
|-------|------|-----------|-----------|
| Simple Exponential Smoothing | 442.35 | 0.00 | 8.14% |
| **Holt's Method** | **441.93** | **15.30** | **15.07%** ✅ |
| Holt's (Damped) | 431.76 | 19.43 | 20.20% |
| Holt-Winters (Additive) | 473.29 | 54.68 | 56.41% |

### 5. ARIMAX Modeling
ARIMAX(1,1,1) was fitted using FCB and CPI as external regressors:

| Parameter | Estimate | Std. Error | 95% CI |
|-----------|----------|------------|--------|
| AR(1) | 0.7090 | 0.0991 | [0.515, 0.903] |
| MA(1) | 0.4002 | 0.1386 | [0.126, 0.674] |
| Intercept | 26.2308 | 12.1816 | [2.336, 50.125] |
| FCB | −21.3861 | 12.6689 | [−46.228, 3.456] |
| CPI | 1.8174 | 0.2990 | [1.221, 2.414] |

Ljung-Box p-value: **0.663** → residuals are white noise. All AR/MA roots lie within the unit circle (model is stationary and invertible).

---

## Results

### Model Comparison (Test Set)

| Model | MAE | RMSE | AICc |
|-------|-----|------|------|
| ARIMA(0,1,1) + Drift | 24.174 | 28.109 | 18.064 |
| ETS — Holt's Method | 13.513 | 15.300 | 441.930 |
| **ARIMAX(1,1,1)** | **4.833** | **5.257** | **−3.580** ✅ |

> **Key finding:** ARIMAX reduced MAE by **80%** compared to ARIMA and **64%** compared to ETS, demonstrating the significant value of incorporating macroeconomic external variables.

---

## Requirements

### R Version
```
R >= 4.0.0
```

### R Packages

```r
install.packages(c(
  "fpp2",       # Forecasting: Principles and Practice (includes forecast)
  "forecast",   # ARIMA, ETS, auto.arima
  "ggplot2",    # Visualization
  "urca",       # Unit root / KPSS tests
  "tseries",    # Time series utilities
  "Metrics"     # MAE, RMSE evaluation
))
```

---

## Usage

### 1. Clone the repository

```bash
git clone https://github.com/your-username/lebanon-exchange-rate-forecasting.git
cd lebanon-exchange-rate-forecasting
```

### 2. Set your working directory

In both R scripts, update the `setwd()` path to match your local environment:

```r
setwd("path/to/your/project/folder")
```

### 3. Run ARIMA & ETS analysis

```r
source("ARIMA_and_Exponential_Smoothing.R")
```

This script will:
- Load and visualize the exchange rate time series
- Apply Box-Cox transformation and differencing
- Fit and compare five ARIMA models
- Fit SES, Holt's, Holt's Damped, and Holt-Winters models
- Output accuracy metrics and forecast plots

### 4. Run ARIMAX analysis

```r
source("ARIMAX.R")
```

This script will:
- Load exchange rate, FCB, and CPI time series
- Apply Box-Cox transformations to all variables
- Fit the ARIMAX model using `auto.arima()` with external regressors
- Forecast 12 months ahead and back-transform predictions
- Compute MAE, RMSE, and run residual diagnostics

---

## References

1. Hyndman, R. J., & Athanasopoulos, G. (2018). *Forecasting: Principles and Practice* (2nd ed.). OTexts.
2. World Bank. (2024). Lebanon — Monthly Currency Exchange Rate Estimates by Market.
3. Banque du Liban. Economic and Financial Data. https://www.bdl.gov.lb
4. Box, G. E. P., Jenkins, G. M., & Reinsel, G. C. (2015). *Time Series Analysis: Forecasting and Control* (5th ed.). Wiley.
5. Ljung, G. M., & Box, G. E. P. (1978). On a Measure of Lack of Fit in Time Series Models. *Biometrika*, 65(2), 297–303.
6. Kwiatkowski, D., et al. (1992). Testing the Null Hypothesis of Stationarity. *Journal of Econometrics*, 54(1–3), 159–178.
7. R Core Team. (2022). *R: A Language and Environment for Statistical Computing*. https://www.r-project.org/

---

<div align="center">

**Università degli Studi di Padova · Department of Mathematics · MSc Data Science**  
Academic Year 2024–2025

</div>
