# Flare Irradiance Spectral Model
## Version 2 (FISM2)

PI: Phillip Chamberlin, U. of Colorado, Laboratory for Atmospheric and Space Physics (CU/LASP)

Phil.Chamberlin@lasp.colorado.edu

May 19, 2020

### Table of Contents

1. [Introduction](#introduction)
2. [Responsible Data Usage](#responsible-data-usage)
3. [Reference Publications](#reference-publications)
4. [FISM2 Products](#fism2-products)

    a. [_FISM2 Daily_](#fism2-daily)

    b. [_FISM2 Daily Stan Bands_](#fism2-daily-stan-bands)

    c. [_FISM2 Flare_](#fism2-flare)

    d. [_FISM2 Flare Stan Bands_](#fism2-flare-stan-bands)

## Introduction

The Flare Irradiance Spectral Model – Version 2 (FISM2; Chamberlin et al., 2020) was created at the Laboratory for Atmospheric and Space Physics in Boulder, Colorado. FISM was originally released in 2005 (Chamberlin, Woods, and Eparvier, 2007, 2008), and still consists of a ‘Daily’ and ‘Flare’ products, where the ‘Daily’ is a single spectrum for the day from 1947-Present, the ‘Flare’ product is from 2003-Present at 60 second cadence. FISM2 has been upgraded to 0.1nm spectral bins and is available in the full spectral range from 0.1-190nm. To be more compatible with many Ionosphere and Thermosphere models, such as WACCM/WACCM-X and TIME-GCM, two other daily and flare data products are also being released already in “Stan Bands” wavelength binning (Solomon and Qian, 2005)*. FISM2 incorporates more accurate, higher cadence measurements that have become available since the original release.

\* The FISM2 ‘Stan Band’ data products are provided with the irradiance values already converted to the units of photons/cm^2 /sec, instead of the ISO standard W/m^2 /nm that the other full spectral resolution products are provide in, as a convenience to eliminate the extra step to get to the standard unit inputs of many ionosphere/thermosphere models and avoid any confusion and errors that may occur in this conversion.

These new base data sets include:

**0 - 6 nm:**
Solar Radiation and Climate Experiment (SORCE)/X-Ray Photometer System (XPS), Level 4, Version 12
**6 - 105 nm:**
Solar Dynamics Observatory (SDO; Pesnell et al. 2011)/EUV Variability Experiment (EVE; Woods et al. 2011), Level 2, Version 6
**115 - 190 nm:**
Solar Radiation and Climate Experiment (SORCE; Rottman et al. 2005)/Solar Stellar Irradiance Comparison Experiment (SOLSTICE; McClintock et al. 2005), Level 3, Version 15

We have made every effort at verification and validation of this model, but if there are any questions or encounter any problems with the FISM2 estimations, please let us know about them. For access, data product, or science issues, please contact:
Phil.Chamberlin@lasp.colorado.edu

## Responsible Data Usage

FISM2 results are open to all, however users should contact the PI, Phillip Chamberlin (Phil.Chamberlin@lasp.colorado.edu) early in an analysis project to discuss appropriate use of data results. Appropriate acknowledgements should be given, and pre-prints of publications and conference abstracts are encouraged to be widely distributed.

## Reference Publications

Chamberlin, P. C., F.G. Eparvier, V. Knoer, H. Leise, A. Pankratz, M. Snow, B. Templeman, E. M. B. Thiemann, D. L. Woodraska, and T. N. Woods, (in preparation, 2020), The Flare Irradiance Spectral Model – Version 2 (FISM2).

Chamberlin, P. C., T. N. Woods, and F. G. Eparvier (2007), Flare Irradiance Spectral Model (FISM): Daily component algorithms and results, _Space Weather_ , 5, S07005, doi:10.1029/2007SW000316.

Chamberlin, P. C., T. N. Woods, and F. G. Eparvier (2008), Flare Irradiance Spectral Model (FISM): Flare component algorithms and results, _Space Weather_ , 6, S05001, doi:10.1029/2007SW000372.

## FISM2 Products

#### FISM2 Daily

Cadence: 24-hour
Spectral Range: 0-190 nm
Spectral Bins: 0.1 nm (centered on 0.05 nm; e.g. 0.05 nm, 0.15 nm, 0.25 nm, ...)

LISIRD Data Plotting and Access:

[http://lasp.colorado.edu/lisird/data/fism_daily_hr/](http://lasp.colorado.edu/lisird/data/fism_daily_hr/)

Direct Data Access:

[http://lasp.colorado.edu/eve/data_access/evewebdata/fism/daily_hr_data/](http://lasp.colorado.edu/eve/data_access/evewebdata/fism/daily_hr_data/)

Data Arrays: 
```
YDOY (1 element): Date in YYYYDOY format, where YYYY is year, DOY is day of year (e.g. 2003301)
IRRADIANCE (1900 elements): The Solar Irradiance, in W/m^2/nm
WAVELENGTH (1900 elements): The wavelength array, in nm.
UNCERTAINTY (1900 elements): The 1-sigma relative uncertainty of the IRRADIANCE.
```
`Relative_Uncertainty = Absolute_Uncertainty / IRRADIANCE`

#### FISM2 Daily Stan Bands

Cadence: 24-hour
Spectral Range: 0.01-121.
Spectral Bins: 23 bins of various length (see Solomon and Qian, 2005)

LISIRD Data Plotting and Access:

[http://lasp.colorado.edu/lisird/data/fism_daily_bands/](http://lasp.colorado.edu/lisird/data/fism_daily_bands/)

Direct Data Access:

[http://lasp.colorado.edu/eve/data_access/evewebdata/fism/daily_bands/](http://lasp.colorado.edu/eve/data_access/evewebdata/fism/daily_bands/)

Data Arrays:
```
DATE (1 element): Date in YYYYDOY format, where YYYY is year, DOY is day of year (e.g. 
2003301)
DATE_SEC (1): Seconds of Day, just set to mid-day for daily product, 43200.0 sec
SSI (23 elements): The Solar Irradiance for the bin, in photons/cm^2 /second
WAVELENGTH (23 elements): The central wavelength of the bin, in nm.
BAND_WIDTH (23 elements): The spectral width of the band, in nm.
```
#### FISM2 Flare

Cadence: 60-sec (in daily files)
Spectral Range: 0-190 nm
Spectral Bins: 0.1 nm (centered on 0.05 nm; e.g. 0.05 nm, 0.15 nm, 0.25 nm, ...)

LISIRD Data Plotting and Access:

[http://lasp.colorado.edu/lisird/data/fism_flare_hr/](http://lasp.colorado.edu/lisird/data/fism_flare_hr/)

Direct Data Access:

[http://lasp.colorado.edu/eve/data_access/evewebdata/fism/flare_hr_data/](http://lasp.colorado.edu/eve/data_access/evewebdata/fism/flare_hr_data/)

Data Arrays: 

```YDOY (1 element): Date in YYYYDOY format, where YYYY is year, DOY is day of year (e.g. 
2003301)
UTC (1440 elements): UTC Seconds of Day
IRRADIANCE (1900x1440 elements): The Solar Irradiance, in W/m^2/nm
WAVELENGTH (1900 elements): The wavelength array, in nm.
UNCERTAINTY (1900x1440 elements): The 1-sigma relative uncertainty of the 
IRRADIANCE.
```
`Relative_Uncertainty = Absolute_Uncertainty / IRRADIANCE`

#### FISM2 Flare Stan Bands

Cadence: 5-minutes (in daily files)
Spectral Range: 0-121 nm
Spectral Bins: 23 bins of various length (see Solomon and Qian, 2005)

LISIRD Data Plotting and Access:

[http://lasp.colorado.edu/lisird/data/fism_flare_bands/](http://lasp.colorado.edu/lisird/data/fism_flare_bands/)

Direct Data Access:

[http://lasp.colorado.edu/eve/data_access/evewebdata/fism/flare_bands/](http://lasp.colorado.edu/eve/data_access/evewebdata/fism/flare_bands/)

Data Arrays: 

```DATE (1 element): Date in YYYYDOY format, where YYYY is year, DOY is day of year (e.g. 2003301)
DATE_SEC (288 elements): UTC Seconds of Day
SSI (23x288 elements): The Solar Irradiance, in photons/cm^2/second
WAVELENGTH (23 elements): The central wavelength of the bin, in nm.
BAND_WIDTH (23 elements): The spectral width of the band, in nm.
```

