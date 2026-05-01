library(tidyverse)
library(data.table)
library(ggplot2)
library(caret)
library(rpart)
library(psych)
library(jtools)
library(zoo)

pop_data       <- read_csv("C:/Users/evans/OneDrive/Documents/St John Fisher Documents/Spring 2026/Dynamical Systems/Group Project 1/world_usa_pop_data.csv")
usa_data       <- read.csv("C:/Users/evans/OneDrive/Documents/St John Fisher Documents/Spring 2026/Dynamical Systems/Group Project 1/usa_data_pt2_2.csv")
oil_price_data <- read_csv("C:/Users/evans/OneDrive/Documents/St John Fisher Documents/Spring 2026/Dynamical Systems/Group Project 1/historical_oil_price_y2.csv")
oil_cons_data  <- read_csv("C:/Users/evans/OneDrive/Documents/St John Fisher Documents/Spring 2026/Dynamical Systems/Group Project 1/us_cons.csv")

oil_in_place    <- 6e12
recovery_factor <- 0.50
used_oil        <- 1.3e12
gas_yield       <- 0.45
gal_per_bbl     <- 42

recoverable  <- oil_in_place * recovery_factor
remaining    <- recoverable - used_oil
gasoline_bbl <- remaining * gas_yield
gasoline_gal <- gasoline_bbl * gal_per_bbl

usa_data_cln <- usa_data %>%
  select(-Index) %>%
  rename(vhcl_hwy_total = Highway..total..registered.vehicles.,
         gdp_pcap = GDP.per.capita..current.US..,
         us_pop = Population..total,
         pop_dense = Population.density..people.per.sq..km.of.land.area.,
         lt_vehicle_short = Light.duty.vehicle..short.wheel.base,
         motorcycle = Motorcycle,
         lt_vehicle_long = Light.duty.vehicle..long.wheel.base,
         truck_6tr = Truck..single.unit.2.axle.6.tire.or.more,
         truck_combo = Truck..combination,
         bus = Bus) %>%
  mutate(log_ev_prop = log(prop_ev))

ev_reg <- lm(prop_ev ~ Year, data = usa_data_cln[15:17,])
ev_predictions <- predict(ev_reg, newdata = data.frame(Year = c(2290, 2295, 2300)))

pop_data_reg <- pop_data %>%
  select(-name, -index, -usa_pop, -usa_world_pop_ratio) %>%
  mutate(pop = as.numeric(gsub(",", "", pop)))

log_model        <- nls(pop ~ SSlogis(year, Asym, xmid, scal), data = pop_data_reg)
future_dates_df  <- data.frame(year = seq(from = 1970, to = 10000, by = 10))
future_preds_log <- predict(log_model, newdata = future_dates_df)
future_plot_data <- data.frame(
  year = future_dates_df$year,
  pop = future_preds_log)
future_plot_data$pop_adj <- future_plot_data$pop - (6000*(future_plot_data$year - 1969))*log(future_plot_data$year - 1969)

usa_world_pop_ratio     <- mean(pop_data$usa_world_pop_ratio, na.rm = TRUE)
future_plot_data$us_pop <- future_plot_data$pop*usa_world_pop_ratio

veh_to_uspop                <- mean(usa_data_cln$vhcl_hwy_total/usa_data_cln$us_pop)
future_plot_data$us_hwy_tot <- future_plot_data$us_pop*veh_to_uspop

worldveh_to_us                  <- 1645000000/298700000
future_plot_data$world_veh_tot1 <- future_plot_data$us_hwy_tot*worldveh_to_us

future_plot_data$world_ev_prop <- predict(ev_reg, newdata = data.frame(Year = future_plot_data$year))
future_plot_data$world_ev_prop <- ifelse(future_plot_data$world_ev_prop < 0, 0, future_plot_data$world_ev_prop)
future_plot_data$world_ev_prop <- ifelse(future_plot_data$world_ev_prop > 1, 1, future_plot_data$world_ev_prop)

future_plot_data$world_veh_tot <- future_plot_data$world_veh_tot1*(1 - future_plot_data$world_ev_prop)
future_plot_data$world_ev_tot  <- future_plot_data$world_veh_tot1 - future_plot_data$world_veh_tot

lts_prop    <- mean(usa_data_cln$lt_vehicle_short/usa_data_cln$vhcl_hwy_total)
moto_prop   <- mean(usa_data_cln$motorcycle/usa_data_cln$vhcl_hwy_total)
ltl_prop    <- mean(usa_data_cln$lt_vehicle_long/usa_data_cln$vhcl_hwy_total)
tr6_prop    <- mean(usa_data_cln$truck_6tr/usa_data_cln$vhcl_hwy_total)
tcombo_prop <- mean(usa_data_cln$truck_combo/usa_data_cln$vhcl_hwy_total)
bus_prop    <- mean(usa_data_cln$bus/usa_data_cln$vhcl_hwy_total)

future_plot_data <- future_plot_data %>%
  mutate(
    world_lts = lts_prop*world_veh_tot,
    world_moto = moto_prop*world_veh_tot,
    world_ltl = ltl_prop*world_veh_tot,
    world_6tr = tr6_prop*world_veh_tot,
    world_tcombo = tcombo_prop*world_veh_tot,
    world_bus = bus_prop*world_veh_tot,
    world_lts_ev = lts_prop*world_ev_tot,
    world_moto_ev = moto_prop*world_ev_tot,
    world_ltl_ev = ltl_prop*world_ev_tot,
    world_6tr_ev = tr6_prop*world_ev_tot,
    world_tcombo_ev = tcombo_prop*world_ev_tot,
    world_bus_ev = bus_prop*world_ev_tot,
    sumworld_lts = world_lts + world_lts_ev,
    sumworld_moto = world_moto + world_moto_ev,
    sumworld_ltl = world_ltl + world_ltl_ev,
    sumworld_6tr = world_6tr + world_6tr_ev,
    sumworld_tcombo = world_tcombo + world_tcombo_ev,
    sumworld_bus = world_bus + world_bus_ev,
    suv_prop_ltl = 1606/(1606 + 233),
    pickup_prop_ltl = 1 - suv_prop_ltl,
    suv_galyr_dyn = world_ltl*suv_prop_ltl*14299/(2.37*(year - 1970) + 10.9), # totveh * (mi/yr) / (mi/gal) = total gal/yr    total ldlwb divided proportionally to suv and pickups
    car_galyr_dyn = world_lts*10573/(3.06*(year - 1970) + 11.5),
    pickup_galyr_dyn = world_ltl*pickup_prop_ltl*11318/(1.77*(year - 1970) + 12.9),
    moto_galyr_dyn = world_moto*2005/(-.671*(year - 1970) + 52.1),
    semi_galyr_dyn = world_tcombo*62169/(.543*(year - 1970) + 4.81),
    bus_galyr_dyn = world_bus*42940/(.197*(year - 1970) + 5.79),
    tr6_galyr_dyn = world_6tr*23000/7.4, # since none of the mpg categories reasonably map to 6 tire truck we will assume constant mpg of 7.4 mpg for these vehicles and constant 23000 mi/yr
    ev_galyr_dyn = world_ev_tot*12000/(11.6*(year - 1970) - 7.9),
    sum_galyr_dyn = 10*(suv_galyr_dyn + car_galyr_dyn + pickup_galyr_dyn + moto_galyr_dyn + semi_galyr_dyn + bus_galyr_dyn + tr6_galyr_dyn + ev_galyr_dyn),
    prev_sum_galyr = sum_galyr_dyn
  )


replace_neg_with_prev_max <- function(x) {
  x[x < 0] <- NA
  cumulative_max_x <- cummax(x)
  final_vec <- na.locf(cumulative_max_x, na.rm = FALSE, fromLast = FALSE)
  return(final_vec)
}

future_plot_data <- future_plot_data %>%
  mutate(
    sum_galyr_dyn2 = ifelse(sum_galyr_dyn < 0, replace_neg_with_prev_max(sum_galyr_dyn), sum_galyr_dyn)
  )

oil_price_data <- oil_price_data %>%
  mutate(
    log_nomprice = log(nom_price),
    log_infadj_price = log(infadj_price)
  )

oil_cons_data <- oil_cons_data %>%
  mutate(
    year = Year,
    cons_mil = Consumption*365
  ) %>%
  select(-Year, -Consumption)

cons_price_oil <- inner_join(oil_cons_data, oil_price_data, by = "year")
cons_price_oil <- cons_price_oil %>%
  mutate(
    log_cons_mil   = log(cons_mil),
    change_cons    = cons_mil/lag(cons_mil, 10),
    change_logcons = log_cons_mil/lag(log_cons_mil, 10)
  ) %>%
  drop_na()

price_time_reg <- lm(log_nomprice ~ year, data = cons_price_oil)
cons_pr <- lm(change_cons ~ log_nomprice, data = cons_price_oil)

#conschng_timereg <- lm(change_cons ~ modyear, data = cons_price_oil)
#summary(conschng_timereg)

export_summs(price_time_reg, cons_pr)

plot1 <- ggplot(data = cons_price_oil, aes(x = year, y = log_nomprice)) +
  geom_point() +
  geom_smooth(method = "lm", col = "red", se = FALSE) +
  labs(
    title = 'Change in log(Price)\nvs. Time',
    x = 'Year',
    y = 'log(Nominal Price per Barrel)'
  )

plot2 <- ggplot(data = cons_price_oil, aes(x = log_nomprice, y = change_cons)) +
  geom_point() +
  geom_smooth(method = "lm", col = "red", se = FALSE) +
  labs(
    title = 'Change in Consumption\nvs. log(Price)',
    x = 'log(Nominal Price per Barrel)',
    y = 'Change in Consumption (per decade)'
  )

plot1 + plot2

econ_fut <- data.frame(
  year = seq(from = 2030, to = 2300, by = 10)
)

econ_fut$log_nomprice <- predict(price_time_reg, newdata = econ_fut)
econ_fut$change_cons  <- predict(cons_pr, newdata = econ_fut)
econ_fut <- econ_fut %>%
  mutate(
    change_cons = ifelse(change_cons < 0, 0, change_cons),
    cons_mil = accumulate(
      change_cons, ~ .x * .y, .init = 6639.35
    )[-length(change_cons)]
  )

temp <- cons_price_oil %>%
  filter(year %% 10 == 0) %>%
  select(year, log_nomprice, change_cons, cons_mil)
combined_prodcons  <- rbind(temp, econ_fut)
combined_prodcons  <- combined_prodcons %>%
  mutate(
    galgas_cons = cons_mil*gas_yield*gal_per_bbl*1000000
  )

combined_prodcons  <- combined_prodcons[-1,]
test_sum_galyr_dyn <- future_plot_data$sum_galyr_dyn
test_sum_galyr_dyn <- test_sum_galyr_dyn[3:24]
test_galgas_cons   <- combined_prodcons$galgas_cons
test_galgas_cons   <- test_galgas_cons[3:24]
future_plot_data2  <- full_join(future_plot_data, combined_prodcons, by = "year")

future_plot_data2  <- future_plot_data2 %>%
  select(year, prev_sum_galyr, sum_galyr_dyn, change_cons) %>%
  filter(year >= 2020) %>%
  mutate(
    sum_galyr_dyn = accumulate(
      (change_cons + 7)/8,
      ~ .x * .y,
      .init = prev_sum_galyr[1]
    )[-length(prev_sum_galyr)],
    sum_galyr_dyn = ifelse(sum_galyr_dyn < 0, 0, sum_galyr_dyn)
  )

plt1 <- ggplot(data = future_plot_data2, aes(x = year, y = prev_sum_galyr)) +
  geom_line(linewidth = 1.2, color = 'grey20') +
  geom_line(aes(y = sum_galyr_dyn), color = 'royalblue4', linewidth = 1.2) +
  labs(
    title = 'Gasoline Consumption Comparison',
    subtitle = 'Addition of Price-Demand Adjustment',
    x = 'Year',
    y = 'Annual Consumption (Gallons)'#,
    #color = 'Legend'
  ) +
  geom_hline(yintercept = 0) +
  #scale_color_manual(values = c('grey20', 'royalblue4')) +
  #theme(legend.position = c(.8, .85)) +
  coord_cartesian(xlim = c(2020, 2160)) +
  geom_vline(xintercept = 2020)

parameters <- data.frame(oil_in_place = 6e12,
                         recovery_factor = .5,
                         used_oil = 1.3e12,
                         gas_yield = .45,
                         gal_per_bbl = 42)

parameters <- parameters %>%
  add_row(!!!parameters[1, ] %>% mutate(oil_in_place = oil_in_place * 1.1)) %>%
  add_row(!!!parameters[1, ] %>% mutate(oil_in_place = oil_in_place * .9)) %>%
  add_row(!!!parameters[1, ] %>% mutate(recovery_factor = recovery_factor * 1.15)) %>%
  add_row(!!!parameters[1, ] %>% mutate(recovery_factor = recovery_factor * .85)) %>%
  add_row(!!!parameters[1, ] %>% mutate(used_oil = used_oil * 1.05)) %>%
  add_row(!!!parameters[1, ] %>% mutate(used_oil = used_oil * .95)) %>%
  add_row(!!!parameters[1, ] %>% mutate(gas_yield = gas_yield * 1.05)) %>%
  add_row(!!!parameters[1, ] %>% mutate(gas_yield = gas_yield * .95)) %>%
  mutate(gas_gal = (oil_in_place * recovery_factor - used_oil) * gas_yield * gal_per_bbl)

final_future_data <- future_plot_data2 %>%
  select(year, sum_galyr_dyn)

sens_analysis <- c()

for (k in 1:9) {
  final_plot_data <- data.frame(year = 2020, remaining = parameters$gas_gal[k])
  i <- 1
  while (tail(final_plot_data$remaining, 1) > 0) {
    new_remaining <- tail(final_plot_data$remaining, 1) - final_future_data$sum_galyr_dyn[i]
    new_year <- tail(final_plot_data$year, 1) + 10
    final_plot_data <- rbind(final_plot_data, data.frame(year = new_year, remaining = new_remaining))
    i <- i + 1
  }
  
  final_slope <- (tail(final_plot_data$remaining, 2) - tail(final_plot_data$remaining, 1))/(tail(final_plot_data$year, 2) - tail(final_plot_data$year, 1))
  final_int   <- tail(final_plot_data$remaining, 1) - (final_slope*tail(final_plot_data$year, 1))
  year_empty  <- (-final_int/final_slope[1])
  
  sens_analysis <- append(sens_analysis, year_empty)
  
  if (k == 1) {
    final_plot_data3 <- data.frame(year = 2020, remaining = parameters$gas_gal[k])
    i <- 1
    while (tail(final_plot_data3$remaining, 1) > 0) {
      new_remaining <- tail(final_plot_data3$remaining, 1) - future_plot_data2$prev_sum_galyr[i]
      new_year <- tail(final_plot_data3$year, 1) + 10
      final_plot_data3 <- rbind(final_plot_data3, data.frame(year = new_year, remaining = new_remaining))
      i <- i + 1
    }
    og_plot <- ggplot(data = final_plot_data3, aes(x = year, y = remaining, color = 'Before Adjustment')) +
      geom_line(linewidth = 1.2) +
      geom_line(data = final_plot_data, aes(y = remaining, color = 'After Adjustment'), linewidth = 1.2) +
      scale_color_manual(values = c('royalblue4', 'grey20')) +
      labs(
        title = 'Remaining Supply of Oil',
        subtitle = 'Addition of Price-Demand Adjustment',
        x = 'Year',
        y = 'Remaining Gasoline (Gallons)',
        color = 'Legend'
      ) +
      theme(legend.position = c(.7, .8)) +
      geom_hline(yintercept = 0) +
      coord_cartesian(ylim = c(0, 3.25e13)) +
      guides(color = guide_legend(reverse = TRUE)) +
      geom_vline(xintercept = 2020)
    #print(og_plot)
  }
  
}

sens_analysis <- sens_analysis[!is.nan(sens_analysis)]
parameters$year_out <- sens_analysis
parameters$year_dif <- parameters$year_out - parameters$year_out[1]
parameters$dif_pct  <- 100*(parameters$year_out - 2020)/(parameters$year_out[1] - 2020) - 100
change_vector <- c(1, 10, -10, 15, -15, 5, -5, 5, -5)
parameters$elast    <- parameters$dif_pct/change_vector

plt1 + og_plot



