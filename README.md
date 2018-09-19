# Event Based Water Sampling
This repository contains scripts to perform event-based sampling using an ISCO autosampler. Water
levels are monitored via a Milone Technologies eTape and a Campbell Scientific datalogger is used
to record water levels and trigger sampling. Sampling is not threshold triggered, but is based on
deviation from streamflow trends. This provides flexibility to capture events during periods of
high and mean flows, and importantly small events during dry or low flow periods. The exact approach
was developed empirically using existing data for two small headwater wetlands, but it should be
flexible enough to work across varied systems.

# Approach
Water levels (WL) are read and recorded hourly along with the hourly change in water level
(WL<sub>&Delta;1</sub>). Rolling means of (WL<sub>&Delta;1</sub>) are calculated for 2
(WL<sub>&Delta;2</sub>), 6 (WL<sub>&Delta;6</sub>), and 24-hr (WL<sub>&Delta;24</sub>) periods as
well as the hourly change in WL<sub>&Delta;24</sub> (&Delta;WL<sub>&Delta;24</sub>). The 24-hr
rolling standard deviation of WL<sub>&Delta;1</sub> is calculated and recorded (WL<sub>SD-24</sub>).
An event is triggered when (&Delta;WL<sub>&Delta;24</sub>) is outside of the 99.5% confidence
interval and WL<sub>&Delta;6</sub> is above a threshold, which is currently set at 0.1 cm.


Sample if  
&Delta;WL<sub>&Delta;24</sub> >= WL<sub>&Delta;24</sub> + 2.58 * WL<sub>SD-24</sub>
AND WL<sub>&Delta;6</sub> > 0.1

When an event is triggered a sample is taken, the `hydrographLimb` variable is set from `NA` to
'rising', and the water level is stored (WL<sub>Event</sub>. Samples are taken hourly and when
WL<sub>&Delta;2</sub> is negative the `hydrographLimb` is set to 'falling'. Sampling is ended when
WL falls to 1.1 times WL<sub>Event</sub> and `hydrographLimb` is set to `NA`.

If 24 hours pass after the last sample a single sample is taken. Sampling will cease after 24 samples
to avoid sample mixing.

# Equipment
- ISCO Autosampler from [Teledyne ISCO](http://www.teledyneisco.com/en-us/water-and-wastewater/samplers/products)
(this script has been tested using the 3700 Portable Sampler)  
- Campbell Scientific Datalogger (this script is written for a CR800)  
- [Milone Technologies Standard eTape](https://milonetech.com/)
  - I have tested sampling using the Voltage Divider and 0-5 V Resistance to Voltage output modules. Experience and personal communications
  with the manufacturer shows that the Voltage Divider is a more robust option that will not be immediately
  damaged from a shorted circuit or wiring error, however your precision will be reduced as the range of teh eTape is recorded from 2.5-5 V rather than 0-5 V.

# Set up
Wiring guide for the CR800 and the two tested output module of eTapes

eTape | Datalogger<br>(Voltage Divider) | Datalogger<br>(0-5V Module)
:----------:|:------------:|:--------:
Vin	|	5V | 12V
Vout	|	1H | 1H
Gnd	|	Ground | Ground

Wiring guide for the CR800 and the ISCO autosampler

ISCO	|	CR800
:------:|:--------:
Flow Meter Port Pin A | SDI 12V
Flow Meter Port Pin C | SDI C1

# Table Outputs
The CRBasic programs output three tables Diagnostics, ISCO, and Water_Level.  
__Diagnostics__  
-batteryVoltage  
-loggerTemperature  
__ISCO__  
-bottleNumber  
-waterLevel  
-hydrographLimb  

__Water_Level__  
-bottleNumber  
-eTape  
-waterLevel  
-laggedWaterLevel  
-deltaWaterLevel_1hr  
-meanDeltaWL_2hr  
-meanDeltaWL_6hr  
-dailyWaterLevel  
-laggedDailyWaterLevel  
-deltaDailyWaterLevel  
-meanDeltaDailyWL_24hr  
-sdDeltaDailyWL_24hr  
-samplingEvent  
-hydrographLimb  
-startWaterLevel  
-hoursAfterSample  

# To Do
- [ ] Update ISCO wiring guide in CRBasic programs  
- [ ] Set up a constants table for threshold values (0.1 cm, 24 hours between samples, yes or no for interval sampling, etc) to allow easier customization  
    - THIS NEEDS TO BE A PRIORITY. Whenever restarting the program to reset the
    bottle number it risks making a slowly rising hydrograph look like an events
    because there is not 24-hours of data to smooth the mean and sd.
- [ ] Evaluate and adjust as needed the 110% threshold for ending events  
- [ ] Set a minimum water level to avoid interval sampling when no flow is present  
- [ ] Add sequential mode call to program
- [ ] Slow rising limbs are missed, not and quite event, but wet-up periods. Perhaps
this is fine because it is captured by the interval sampling
- [ ] Add example data and figure
- [ ] Convert intermediate variables to declaration by Dim rather than Public
- [ ] Test storing deltaDailyWaterLevel in an array and calculating the standard deviation using StdDevSpa
