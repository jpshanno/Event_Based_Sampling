# This calibration is for the eTape currently deployed at 053. It is fitted with 
# a voltage divider rather than a 0-5 V output converter. This is probably the 
# better option as the voltage divider is more robust than the output converter.
# Speaking with Chris Milone he said there is no chip in the voltage divider,
# which means a wiring error will not destroy the eTape. To make this work with
# a CS logger use the 5V out power supply and the following calibration curve.

library(dplyr)
library(readr)

# VDiff Range:
values <- 
	read_csv("water_level_cm, vdiff_mV
1, 2498.5
2, 2498.5
3, 2499.2
4, 2539.1
5, 2558.0
8, 2614.8
10, 2668.9
15, 2781.2
25, 3051.7
35, 3357.5
50, 3931.0
59, 4409.9
61.8, 4562.7")

# The eTape won't respond at less than 1-inch water level, so here I set 2.54 cm
# to the same value as 1 and 2.

# values <- 
#   values %>% 
#   add_row(water_level_cm = 2.54,
#           vdiff_mV = 2498.5,
#           .after = 2)

# The entire curve is non-linear, and rather than fit a non-linear curve I fit a
# linear curve to the lower range of values. After initial testing r^2 was best
# when doing 3-25 as a range of water levels. But mse was much lower over 3-15
# range. The entire curve is non-linear.

expected_range <- 
  values %>% 
  filter(water_level_cm >= 3,
         water_level_cm <= 15)

mod <- 
	lm(water_level_cm ~ vdiff_mV,
	   data = expected_range)

coef(mod)		


# Vout = (vin * r2) / (r1 + r2)



