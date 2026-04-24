# Required Libraries
library(forecast) # For ARIMAX modeling and forecasting
library(ggplot2)  # For plotting
library(Metrics)
library(fpp2) #includes the forecast package
library(urca)
library(tseries)
library(ggplot2)

# Import Data and Create Time Series
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
df <- read.csv("../data/Exchange_Rate_Adjusted.csv")

ts_exchangerate <- ts(df$Close, frequency = 12, start = c(2019, 1), end = c(2024, 12))
ts_fcb <- ts(df$fcb, frequency = 12, start = c(2019, 1), end = c(2024, 12))
ts_cpi <- ts(df$cpi, frequency = 12, start = c(2019, 1), end = c(2024, 12))

# Split Data into Train and Test
train_exchangerate <- window(ts_exchangerate, end = c(2023, 12))  # Training set
test_exchangerate <- window(ts_exchangerate, start = c(2024, 1))  # Test set

train_fcb <- window(ts_fcb, end = c(2023, 12))  # Training set for fcb
test_fcb <- window(ts_fcb, start = c(2024, 1))  # Test set for fcb

train_cpi <- window(ts_cpi, end = c(2023, 12))  # Training set for cpi
test_cpi <- window(ts_cpi, start = c(2024, 1))  # Test set for cpi

# Box-Cox Transformation for Exchange Rate
lambda_exchangerate <- BoxCox.lambda(train_exchangerate)
train_exchangerate_transformed <- BoxCox(train_exchangerate, lambda = lambda_exchangerate)
test_exchangerate_transformed <- BoxCox(test_exchangerate, lambda = lambda_exchangerate)

# Box-Cox Transformation for FCB
lambda_fcb <- BoxCox.lambda(train_fcb)
train_fcb_transformed <- BoxCox(train_fcb, lambda = lambda_fcb)
test_fcb_transformed <- BoxCox(test_fcb, lambda = lambda_fcb)

# Box-Cox Transformation for CPI
lambda_cpi <- BoxCox.lambda(train_cpi)
train_cpi_transformed <- BoxCox(train_cpi, lambda = lambda_cpi)
test_cpi_transformed <- BoxCox(test_cpi, lambda = lambda_cpi)

# Fit the ARIMAX Model with FCB and CPI as Regressors
arimax_model <- auto.arima(
  train_exchangerate_transformed,  # Dependent variable
  xreg = cbind(train_fcb_transformed, train_cpi_transformed),  # External regressors
  approximation = FALSE,
  stepwise = FALSE
)

# Model Summary
cat("ARIMAX Model Summary:\n")
summary(arimax_model)

# Forecast Using ARIMAX Model
arimax_forecast <- forecast(
  arimax_model,
  xreg = cbind(test_fcb_transformed, test_cpi_transformed),
  h = length(test_fcb_transformed)
)

# Inverse Box-Cox Transformation to Return to Original Scale
forecast_values <- InvBoxCox(arimax_forecast$mean, lambda = lambda_exchangerate)

# Evaluate Forecast Accuracy
mae_value <- mae(test_exchangerate, forecast_values)
rmse_value <- rmse(test_exchangerate, forecast_values)

cat("\nMean Absolute Error (MAE):", mae_value, "\n")
cat("Root Mean Squared Error (RMSE):", rmse_value, "\n")

# Plot Forecast vs Actual Data
autoplot(ts_exchangerate) +
  autolayer(forecast_values, series = "Forecasted Exchange Rate (Back-Transformed)") +
  autolayer(test_exchangerate, series = "Actual Exchange Rate") +
  ggtitle("ARIMAX Forecast using Foreign Currency Reserves and CPI") +
  xlab("Year") +
  ylab("LBP per USD (in thousands)") +
  theme_minimal()


# Check residuals for white noise
checkresiduals(arimax_model)

# Ljung-Box Test: Extracting p-value
ljung_box_test <- Box.test(arimax_model$residuals, lag = 10, type = "Ljung-Box")
cat("Ljung-Box Test p-value:", ljung_box_test$p.value, "\n")

# Check invertibility (roots of the AR and MA components)
autoplot(arimax_model) +
  ggtitle("ARIMAX Model: Invertibility and Stationarity Check") +
  xlab("AR and MA Roots") +
  theme_minimal()










# Compute correlations
correlation_matrix <- data.frame(
  Variable1 = c("Exchange Rate", "Exchange Rate"),
  Variable2 = c("Foreign Currency Reserves (FCB)", "Consumer Price Index (CPI)"),
  Correlation = c(
    cor(ts_exchangerate, ts_fcb, use = "complete.obs"),
    cor(ts_exchangerate, ts_cpi, use = "complete.obs")
  )
)

# Display correlation matrix
print(correlation_matrix)

# Correlation matrix for all variables
all_correlations <- cor(
  cbind(ts_exchangerate, ts_fcb, ts_cpi),
  use = "complete.obs"
)

# Print the full correlation matrix
print(all_correlations)

# Load required libraries
library(ggplot2)

# Plot for Exchange Rate
autoplot(ts_exchangerate, color = "red") +
  ggtitle("Exchange Rate Over Time") +
  xlab("Year") +
  ylab("LBP per USD (in thousands)") +
  theme_minimal()

# Plot for Foreign Currency Reserves (FCB)
autoplot(ts_fcb, color = "red") +
  ggtitle("Foreign Currency Reserves") +
  xlab("Year") +
  ylab("FCB (in billions USD)") +
  theme_minimal()

# Plot for Consumer Price Index (CPI)
autoplot(ts_cpi, color = "blue") +
  ggtitle("Consumer Price Index (CPI)") +
  xlab("Year") +
  ylab("CPI (Index)") +
  theme_minimal()





# Summary statistics for CPI and FCB
summary_cpi <- summary(ts_cpi)
summary_fcb <- summary(ts_fcb)

# Standard deviation for CPI and FCB
sd_cpi <- sd(ts_cpi, na.rm = TRUE)
sd_fcb <- sd(ts_fcb, na.rm = TRUE)

# Print results
cat("Summary Statistics for CPI:\n")
print(summary_cpi)
cat("\nStandard Deviation for CPI:", sd_cpi, "\n")

cat("\nSummary Statistics for FCB:\n")
print(summary_fcb)
cat("\nStandard Deviation for FCB:", sd_fcb, "\n")
#Access the Close rate column
df_interest <- df$interest


head(df_interest)


ts_interest=ts(df_interest, frequency= 12, start=c(2019,1), end= c(2024, 12))


summary_interest <- summary(ts_interest)
# Standard deviation for CPI and FCB
cat("\nSummary Statistics for Interest:\n")
print(summary_interest)
cat("\nStandard Deviation for FCB:", sd_interest, "\n")
sd_interest <- sd(ts_interest, na.rm = TRUE)





# Combine all variables into a data frame for correlation analysis
correlation_data <- data.frame(
  ExchangeRate = ts_exchangerate,
  CPI = ts_cpi,
  FCB = ts_fcb,
  InterestRate = ts_interest
)

# Compute the correlation matrix using Pearson's method
correlation_matrix <- cor(correlation_data, use = "complete.obs", method = "pearson")

# Print the correlation matrix
cat("Correlation Matrix (Pearson's method):\n")
print(correlation_matrix)
