library(tydygraphs)
library(tidyverse)
library(tsibble)
library(fable)
library(feasts)
library(lubridate)
library(tidyverse)
library(tsibble)


# Read in flume data ------------------------------------------------------

raw_flumes <- 
  read_csv("../Data/QAQC/Continuous_Sampling/flume_stage.csv") %>% 
  select(site, 
         sample_time, 
         stage_m) %>% 
  mutate(field_season = year(sample_time))


# Fit an ARIMA model to each site and year to compare ---------------------

models <- 
  raw_flumes %>% 
  group_nest(site,
             field_season) %>% 
  pull(data) %>% 
  map(function(x){
        x %>% 
          filter(!is.na(stage_m)) %>% 
          as_tsibble(index = sample_time) %>% 
          fill_gaps() %>% 
          model(ARIMA(stage_m ~ pdq()))
      })

raw_flumes %>% 
  group_by(site) %>% 
  index_by(field_season = year(sample_time)) %>% 
  mutate(stage_smoothed = RcppRoll::roll_meanr(c(NA_real_, diff(stage_m)),
                                               n = 24)) %>% 
  ungroup() %>% 
  tydygraphs::dygraph(stage_smoothed)

mod_flume <- 
  raw_flumes %>% 
  filter_index("2017-04-15" ~ "2017-10-15") %>% 
  mutate(site = paste0("site_", site)) %>% 
  filter(site == "site_053") %>% 
  mutate(stage_smoothed = RcppRoll::roll_meanr(c(NA_real_, diff(stage_m)),
                                               n = 24)) %>% 
  slice(-(1:24)) %>% 
  select(site,
         sample_time,
         stage_smoothed)

mod_ts <- 
  as.ts(mod_flume, 
        frequency = 365 * 96)

plot(mod_ts)

acf(mod_ts,
    lag.max = 192)

pacf(mod_ts,
    lag.max = 192)

mod_ts %>% 
  TSA::armasubsets(nar = 5, nma = 5) %>% 
  plot()

mod_ts %>% 
  TSA::armasubsets(nar = 5, nma = 5) %>% 
  plot(scale = "AICc")

mod_ts %>% 
  TSA::armasubsets(nar = 5, nma = 5) %>% 
  plot(scale = "AIC")

forecast::auto.arima(mod_ts)

mod <- 
  forecast::Arima(mod_ts, 
                  order = c(3, 0, 0),
                  seasonal = list(order = c(2, 0, 0),
                                  period = 24))

raw_flumes %>% 
  # filter_index("2017-04-15" ~ "2017-10-15") %>% 
  mutate(site = paste0("site_", site)) %>% 
  filter(site == "site_053") %>% 
  mutate(fitted = as.numeric(fitted(mod))) %>% 
  tydygraphs::dygraph(stage_m, fitted)


# Rolling Predict

one_step_forecasts <- 
  raw_flumes %>% 
  filter(site == "053") %>% 
  index_by(field_season = year(sample_time)) %>% 
  mutate(stage_smoothed = RcppRoll::roll_meanr(c(NA_real_, diff(stage_m)),
                                               n = 24)) %>% 
  ungroup() %>% 
  select(site,
         sample_time,
         stage_smoothed) %>% 
  mutate(pred = NA_real_) %>% 
  slice(1:100000)
  
for(i in 73:(nrow(one_step_forecasts))){
  
  obs <- 
    one_step_forecasts$stage_smoothed
  
  pred <- 
    coef(mod)[1] * obs[i-2] +
    coef(mod)[2] * obs[i-3] +
    coef(mod)[3] * obs[i-4] +
    coef(mod)[4] * obs[i-24] +
    coef(mod)[5] * obs[i-48] +
    coef(mod)[6]
  
  se <- 
    
  
  one_step_forecasts$pred[i-1] <- 
    pred
}

# plot(one_step_forecasts$stage_m, type = "l") 
# points(one_step_forecasts$pred, type = "l", col = "red")

one_step_forecasts %>% 
  tydygraphs::dygraph(stage_smoothed,
                      pred)



test_df <- 
  raw_flumes %>% 
  filter(site == "053", 
         year(sample_time) == 2013) %>% 
  filter(!is.na(stage_m)) %>% 
  fill_gaps()

test_mod <- 
  raw_flumes %>% 
  filter(site == "053", 
         year(sample_time) == 2013) %>% 
  model(ARIMA(stage_m ~ PDQ(0, 0, 0)))

test_new_data <- 
  raw_flumes %>% 
  filter(site == "053", 
         year(sample_time) == 2014, 
         !is.na(stage_m))

test_new_data %>% 
  mutate(diff_m = c(9.50970e-7, diff(stage_m)), 
         lag1 = lag(diff_m, 1, default = 9.50970e-7), 
         lag2 = lag(diff_m, 2, default = 9.50970e-7), 
         lag3 = lag(diff_m, 3, default = 9.50970e-7), 
         lag4 = lag(diff_m, 4, default = 9.50970e-7), 
         lag5 = lag(diff_m, 5, default = 9.50970e-7), 
         predict = lag1*0.26182310 + lag2*0.26182310 + lag3*0.12773168 + lag4*0.07745699 + lag5*0.03514551 + stage_m) %>%
  tydygraphs::dygraph(predict, stage_m)