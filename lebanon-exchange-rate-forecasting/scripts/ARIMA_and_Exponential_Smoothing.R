#################################################################
## Univariate Exchange Rate Forecasting and Time Series Analysis ##
## Methods: ARIMA, ETS, and Exponential Smoothing                ##
## Author: Ali Sarini                                            ##
## Date: January 2025                                            ##
#################################################################

#Required Libraries
library(fpp2) #includes the forecast package
library(urca)
library(tseries)
library(ggplot2)

#Import the dataset
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
df <- read.csv("../data/Exchange_Rate_Adjusted.csv")

sum(is.na(df)) #no missing data

#Access the Close rate column
df_exchangerate <- df$Close


head(df_exchangerate)


ts_exchangerate=ts(df_exchangerate, frequency= 12, start=c(2019,1), end= c(2024, 12))


ts_exchangerate
autoplot(ts_exchangerate)


# Plot the time series data
autoplot(ts_exchangerate, color = "blue") +
  ggtitle("LBP Exchange Rate") +
  xlab("Year") +
  ylab("LBP per USD (in Thousands)") +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16), # Center and bold the title
    axis.title = element_text(face = "bold", size = 14), # Bold axis labels
    axis.text = element_text(size = 12), # Larger axis text
    panel.grid.major = element_line(color = "gray", linetype = "dotted") # Dotted grid lines
  ) +
  scale_color_manual(values = c("blue")) # Custom color for the line


summary(ts_exchangerate)
sd(ts_exchangerate)
length(ts_exchangerate)# Length of Dataset, 12 x 6 = 72 records

#Split the time series into a training set and test set:

#Train set
train_exchangerate<- window(ts_exchangerate, frequency = 12, end = c(2023,12)) 
length(train_exchangerate) #Training set has 60 records

#Test set
test_exchangerate<- window(ts_exchangerate, frequency = 12,  start= c(2024, 1))
length(test_exchangerate) #Test set has 12 records

summary(ur.kpss(train_exchangerate))


####Differencing and Transformation####

#To find the appropriate lambda value
lam=BoxCox.lambda(train_exchangerate)
lam #Returns 0.302


#Transform the training set using Box-Cox transformation , i.e., stabilize the variance
ex_transformed_train=BoxCox(train_exchangerate,lambda=lam)

#KPSS test to check whether the data is stationary or not
summary(ur.kpss(ex_transformed_train)) 

#data is non-stationary since the value of the test-statistic (1.5389) is greater than the 1% critical 
#value (0.739). Hence, we must perform differencing

#Another method to check if the training set requires differencing

ndiffs(ex_transformed_train) # as there is trend we are trying to get rid of it
#as expected we received 1

nsdiffs(ex_transformed_train) # as there is no seasonality we expect 0
#Hence, we must perform first differencing in order to render the data stationary.
#No seasonal differencing is required 

ex_train_diff=diff(ex_transformed_train, differences = 1)

#Checking for differences
ndiffs(ex_train_diff)

#The training data has been differenced since ndiffs() returned an output of 0

summary(ur.kpss(ex_train_diff))



#The random walk forecast fo has the lowest RMSE among the benchmarking methods, hence, it is the best method 
#in this case

####Plots####

autoplot(train_exchangerate)+
  ggtitle("LBP Exchange Rate") + xlab("Year") +
  ylab("LBP per USD (in Thousands)") # The data shows no signs of seasonality

ggseasonplot(train_exchangerate, polar= TRUE) 
gglagplot(train_exchangerate) 
ggseasonplot(train_exchangerate) 
ggtsdisplay(train_exchangerate)
autoplot(mstl(train_exchangerate)) 



#Check the ACF and PACF of the transform differenced training set to determine potential ARIMA Models
ggtsdisplay(ex_train_diff)

####Checking the performance of different ARIMA Models####

fit1transform= Arima(train_exchangerate, order= c(1,1,0),lambda = lam)
confint(fit1transform) 

(AICc1transform = fit1transform$aicc) #Extract the AICc value of this ARIMA model.


#Note: AICc can be negative

fit2transform= Arima(train_exchangerate, order= c(1,1,1),lambda = lam)
confint(fit2transform) #Does not include a 0, model is good

(AICc2transform = fit2transform$aicc) #Extract the AICc value of this ARIMA model.

fit3transform= Arima(train_exchangerate, order= c(0,1,1),lambda = lam)
confint(fit3transform)

(AICc3transform = fit3transform$aicc) #Extract the AICc value of this ARIMA model.

fit4transform= Arima(train_exchangerate, order= c(1,1,1), include.drift= TRUE, lambda = lam)
confint(fit4transform) 

(AICc4transform = fit4transform$aicc) #Extract the AICc value of this ARIMA model.


fit5transform=Arima(train_exchangerate, order = c(0, 1, 1), include.drift = TRUE, lambda = lam)




fit5transform
confint(fit5transform) 

(AICc5transform = fit5transform$aicc) #Extract the AICc value of this ARIMA model.


# Computing the RMSE and compare through the various models:

rmse1<-accuracy(forecast(fit1transform,h=12)$mean,test_exchangerate)[2]
rmse2<-accuracy(forecast(fit2transform,h=12)$mean,test_exchangerate)[2]
rmse3<-accuracy(forecast(fit3transform,h=12)$mean,test_exchangerate)[2]
rmse4<-accuracy(forecast(fit4transform,h=12)$mean,test_exchangerate)[2]
rmse5<-accuracy(forecast(fit5transform,h=12)$mean,test_exchangerate)[2]

# Collecting P-Values to see if they are white noise

p1 <- checkresiduals(fit1transform)$p.value
p2 <- checkresiduals(fit2transform)$p.value
p3 <- checkresiduals(fit3transform)$p.value
p4 <- checkresiduals(fit4transform)$p.value
p5 <- checkresiduals(fit5transform)$p.value


# Making a dataframe to capture all scores and their respective models

models <-
  c("ARIMA(1,1,0)","ARIMA(1,1,1)","ARIMA(0,1,1)",
    "ARIMA(1,1,1) with drift","ARIMA(0,1,1) with drift")

aics <-c(AICc1transform, AICc2transform, AICc3transform,
         AICc4transform, AICc5transform)

rmses <- c(rmse1,rmse2, rmse3, rmse4, rmse5)

pvalues <-c(p1,p2,p3,p4,p5) 

all_models_arima = data.frame(models, aics,rmses,pvalues)

all_models_arima

# Return the model that had the lowest AICc value:
all_models_arima$models[which.min(all_models_arima$aics)]

# Making a for loop where if p-value is greater than 0.05 then the models are white noise or else not
all_models_arima["White Noise"] = ifelse(all_models_arima$pvalues > 0.05, "Yes","No")

all_models_arima["White Noise"]


#Working with the best ARIMA model, i.e. ARIMA(0,1,1) with drift

fit5transform # (0,1,1) with drift

summary(fit5transform)

forecasts.arima_transformed <- forecast(fit5transform, h=12)#Forecasting the next 12 months


checkresiduals(fit5transform) #The time plot shows that the variance is constant (or homoscedasticity) aside from a 
#few outliers. The histogram shows that the mean of residuals is 0 and they are normally distributed. Lastly, the ACF
#plot shows that there are no spikes outside the bounds, indicating that the residuals are White Noise.

autoplot(forecasts.arima_transformed)+
  ggtitle("Forecasts from the ARIMA(0,1,1) with drift (Transformed)") + xlab("Year") +
  ylab("LBP per USD (in Thousands)") #Plotting our forecast

accuracy(forecasts.arima_transformed, test_exchangerate) #Checking the RMSE of the model

autoplot(fit5transform) ## checking the invertibility and stationarity conditions are satisfied. In this case, all red
# dots are within each circle, thus the fitted model is both stationary and invertible

# Plot the ARIMA forecasts along with actual, fitted, and forecasted values
autoplot(forecasts.arima_transformed) +
  autolayer(test_exchangerate, series = "Actual", color = "blue") +  # Add the actual test set
  autolayer(fitted(fit5transform), series = "Fitted", color = "red") +  # Add fitted values
  autolayer(forecasts.arima_transformed$mean, series = "Forecast", color = "green") +  # Add forecasted values
  ggtitle("Forecasts from the ARIMA(0,1,1) with drift (Transformed)") +
  xlab("Year") +
  ylab("LBP/USD (in Thousands)") +
  guides(colour = guide_legend(title = "Series")) +
  theme_minimal()


autoplot(forecasts.arima_transformed) +
  autolayer(test_exchangerate, series = "Actual", color = "blue") +
  autolayer(fitted(fit5transform), series = "Fitted", color = "red") +
  autolayer(forecasts.arima_transformed$mean, series = "Forecast", color = "green") +
  ggtitle("Forecasts from ARIMA(0,1,1) with drift") +
  xlab("Year") +
  ylab("LBP/USD (in Thousands)") +
  scale_y_log10() +  # Logarithmic scaling
  theme_minimal(base_size = 14) +  # Larger text for better readability
  theme(legend.position = "bottom") +  # Adjust legend placement
  guides(colour = guide_legend(title = "Series"))


# Check the accuracy of the model
accuracy(forecasts.arima_transformed, test_exchangerate)

# Autoplot for invertibility and stationarity
autoplot(fit5transform)



#### ETS vs. Holt's vs. Holt's-Winter ####

#Simple Exponential Smoothing method:

fc <- ses(train_exchangerate, h=12)
fc[['model']] #AICc = 243.1089

# Accuracy of one-step-ahead training errors
accuracy(fc)

#Rounded accuracy 
round(accuracy(fc),2)

# Evaluate forecast accuracy on the test set
accuracy(fc, test_exchangerate)

# Rounded accuracy
round(accuracy(fc, test_exchangerate), 2)

# Plot the forecast
autoplot(fc) +
  autolayer(fitted(fc), series = "Fitted") +
  ylab("LBP/USD (in Thousands)") + xlab("Year") +
  ggtitle("SES Forecasts with Fitted Values")

autoplot(fc) +
  autolayer(fitted(fc), series="Fitted") +
  ylab("LBP/USD (in Thousands") + xlab("Year") #Plotting the forecast

#Holt's method:

fc2 <- holt(train_exchangerate, h=12)
fc2[['model']] #AICc = 213.2645 

#Holt's method (Damped):

fc3 <- holt(train_exchangerate, damped=TRUE, phi = 0.9, h=12) #damping parameter phi is set to be 0.90
fc3[['model']] #AICc = 219.9245

# Evaluate forecast accuracy on the test set
accuracy(fc2, test_exchangerate)

# Rounded accuracy
round(accuracy(fc2, test_exchangerate), 2)

# Plot the forecast
autoplot(fc2) +
  autolayer(fitted(fc2), series = "Fitted") +
  ylab("LBP per USD (in Thousands)") + xlab("Year") +
  ggtitle("Holt's Method Forecasts (No Damping)")

fc4 <- hw(train_exchangerate,seasonal="additive")
fc5 <- hw(train_exchangerate,seasonal="multiplicative")

fc4[["model"]] #AICc = 238
fc5[["model"]] #AICc = 136


# Evaluate forecast accuracy on the test set
accuracy(fc4, test_exchangerate)

# Evaluate forecast accuracy on the test set
accuracy(fc5, test_exchangerate)

autoplot(train_exchangerate) +
  autolayer(fc, series="Simple Exponential Smoothing Forecasts", PI=FALSE) +
  autolayer(fc2, series="Holt's forecasts", PI=FALSE)+
  autolayer(fc3, series="Holt's (Damped) forecasts", PI=FALSE)+
  autolayer(fc4, series="HW additive forecasts", PI=FALSE) +
  autolayer(fc5, series="HW multiplicative forecasts",
            PI=FALSE) +
  xlab("Year") +
  ylab("LBP per USD (in Thousands)") +
  ggtitle("LBP Exchange Rate") +
  guides(colour=guide_legend(title="Forecast")) #Plotting the forecasts




#ETS method returned the lowest (or best) AICc 

summary(fc)

forecasts.fc1 <- forecast(fc, h=12)

checkresiduals(fc) # Variance is constant in the time plot (except for a few outliers), Histogram shows signs of a 
#normal distribution and the mean is close to 0. The residuals are White Noise (according to the ACF plot)

autoplot(fc) +
  xlab("Year") + ylab("") #Plotting the forecasts of the time series

accuracy(forecasts.fc1, test_exchangerate)