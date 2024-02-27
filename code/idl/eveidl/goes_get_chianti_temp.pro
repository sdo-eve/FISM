;+
; Project:
;     SDAC
; Name:
;     GOES_GET_CHIANTI_TEMP
;
; Usage:
;     goes_get_chianti_temp, ratio, temperature, sat=goes, /photospheric, r_cor=r_cor, r_pho=r_pho
;
;Purpose:
;     Called by GOES_CHIANTI_TEM to derive temperature and emission measures.
;     This procedures computes the temperature of solar plasma from the
;     ratio B4/B8 of the GOES 0.5-4 and 1-8 Angstrom fluxes
;     using CHIANTI spectral models with coronal or photospheric abundances
;     All background subtraction, smoothing, etc, is done outside (before)
;     this routine. Default abundances are coronal.
;     WARNING: fluxes are asssumed to be TRUE fluxes, so corrections
;     such as the (0.70,0.85) scaling of GOES 8-12 must be applied before
;     use of this routine. GOES_CHIANTI_TEM applies these corrections.
;
;Category:
;     GOES, SPECTRA
;
;Method:
;     From the ratio the temperature is computed
;     from a spline fit from a lookup table for 101 temperatures logT=.02 apart.
;
;Inputs:
;     RATIO - Ratio of GOES channel fluxes, B4/B8
;
;Keywords:
;     sat  - GOES satellite number, needed to get the correct response
;     photospheric - use photospheric abundances rather than the default
;             coronal abundances
;
;Outputs:
;     TEMP - GOES temperature derived from GOES_GET_CHIANTI_TEMP in units of MK
;     R_COR, R_PHO - coefficients for spline fits
;
;Common Blocks:
;     None.
;
;Needed Files:
;     None
;
; MODIFICATION HISTORY:
;     Stephen White, 24-Mar-2004: Initial version based on CHIANTI 4.2
;     This routine created 02/26/13 using CHIANTI version 7.1
;
;     Kim Tolbert, 2-Dec-2009.  Added r_cor and r_pho keywords
;     Kim Tolbert, 9-Nov-2010, For GOES 15, use same table as GOES 14 (by ensuring gsat<13) until
;       tables for GOES 15 are generated.
;     27-Jun-2012 (online date), Kim, Richard, use CHIANTI 7.0
;     S. White, 27-Dec-2013: add GOES 15 (very similar to GOES 14), use CH 7.1
;
; Contact     : Richard.Schwartz@gsfc.nasa.gov
;
;-
;-------------------------------------------------------------------------

pro goes_get_chianti_temp, r, temp, sat=sat, photospheric=photospheric, r_cor=r_cor, r_pho=r_pho

; interpolate tables of temp versus b4/b8 to get temp for given ratio
; using findex data values are responses to CHIANTI spectra for coronal
; and photospheric abundance
; default is coronal abundance

r_cor=fltarr(15,101)     ; ratio vs temp for each of 15 GOES satellites

 r_cor[0,*]=[4.67e-06,6.80e-06,9.74e-06,1.38e-05,1.96e-05,2.78e-05,3.95e-05,5.62e-05,$
   8.00e-05,1.14e-04,1.61e-04,2.24e-04,3.06e-04,4.10e-04,5.35e-04,6.84e-04,8.59e-04,$
   1.07e-03,1.31e-03,1.60e-03,1.94e-03,2.34e-03,2.81e-03,3.35e-03,3.97e-03,4.66e-03,$
   5.44e-03,6.30e-03,7.25e-03,8.32e-03,9.50e-03,1.08e-02,1.23e-02,1.39e-02,1.56e-02,$
   1.76e-02,1.98e-02,2.22e-02,2.48e-02,2.78e-02,3.11e-02,3.46e-02,3.86e-02,4.29e-02,$
   4.77e-02,5.28e-02,5.85e-02,6.46e-02,7.14e-02,7.87e-02,8.68e-02,9.59e-02,1.06e-01,$
   1.17e-01,1.30e-01,1.44e-01,1.60e-01,1.78e-01,1.98e-01,2.19e-01,2.41e-01,2.64e-01,$
   2.88e-01,3.13e-01,3.38e-01,3.63e-01,3.88e-01,4.13e-01,4.37e-01,4.61e-01,4.85e-01,$
   5.07e-01,5.29e-01,5.51e-01,5.71e-01,5.91e-01,6.10e-01,6.28e-01,6.46e-01,6.62e-01,$
   6.78e-01,6.94e-01,7.08e-01,7.22e-01,7.35e-01,7.48e-01,7.60e-01,7.72e-01,7.82e-01,$
   7.93e-01,8.03e-01,8.12e-01,8.21e-01,8.29e-01,8.38e-01,8.45e-01,8.53e-01,8.60e-01,$
   8.66e-01,8.73e-01,8.79e-01]
 r_cor[1,*]=[4.61e-06,6.72e-06,9.63e-06,1.37e-05,1.94e-05,2.75e-05,3.90e-05,5.55e-05,$
   7.91e-05,1.12e-04,1.59e-04,2.21e-04,3.03e-04,4.05e-04,5.29e-04,6.76e-04,8.50e-04,$
   1.05e-03,1.29e-03,1.58e-03,1.92e-03,2.32e-03,2.78e-03,3.32e-03,3.92e-03,4.61e-03,$
   5.38e-03,6.23e-03,7.17e-03,8.22e-03,9.39e-03,1.07e-02,1.21e-02,1.37e-02,1.55e-02,$
   1.74e-02,1.95e-02,2.19e-02,2.46e-02,2.75e-02,3.07e-02,3.43e-02,3.82e-02,4.24e-02,$
   4.71e-02,5.22e-02,5.78e-02,6.39e-02,7.05e-02,7.78e-02,8.59e-02,9.48e-02,1.05e-01,$
   1.16e-01,1.28e-01,1.43e-01,1.59e-01,1.76e-01,1.96e-01,2.16e-01,2.38e-01,2.61e-01,$
   2.85e-01,3.10e-01,3.34e-01,3.59e-01,3.84e-01,4.08e-01,4.32e-01,4.56e-01,4.79e-01,$
   5.02e-01,5.23e-01,5.44e-01,5.65e-01,5.84e-01,6.03e-01,6.21e-01,6.38e-01,6.55e-01,$
   6.71e-01,6.86e-01,7.00e-01,7.14e-01,7.27e-01,7.40e-01,7.51e-01,7.63e-01,7.74e-01,$
   7.84e-01,7.94e-01,8.03e-01,8.12e-01,8.20e-01,8.28e-01,8.36e-01,8.43e-01,8.50e-01,$
   8.56e-01,8.63e-01,8.69e-01]
 r_cor[2,*]=[4.61e-06,6.72e-06,9.63e-06,1.37e-05,1.94e-05,2.75e-05,3.90e-05,5.55e-05,$
   7.91e-05,1.12e-04,1.59e-04,2.21e-04,3.03e-04,4.05e-04,5.29e-04,6.76e-04,8.50e-04,$
   1.05e-03,1.29e-03,1.58e-03,1.92e-03,2.32e-03,2.78e-03,3.32e-03,3.92e-03,4.61e-03,$
   5.38e-03,6.23e-03,7.17e-03,8.22e-03,9.39e-03,1.07e-02,1.21e-02,1.37e-02,1.55e-02,$
   1.74e-02,1.95e-02,2.19e-02,2.46e-02,2.75e-02,3.07e-02,3.43e-02,3.82e-02,4.24e-02,$
   4.71e-02,5.22e-02,5.78e-02,6.39e-02,7.05e-02,7.78e-02,8.59e-02,9.48e-02,1.05e-01,$
   1.16e-01,1.28e-01,1.43e-01,1.59e-01,1.76e-01,1.96e-01,2.16e-01,2.38e-01,2.61e-01,$
   2.85e-01,3.10e-01,3.34e-01,3.59e-01,3.84e-01,4.08e-01,4.32e-01,4.56e-01,4.79e-01,$
   5.02e-01,5.23e-01,5.44e-01,5.65e-01,5.84e-01,6.03e-01,6.21e-01,6.38e-01,6.55e-01,$
   6.71e-01,6.86e-01,7.00e-01,7.14e-01,7.27e-01,7.40e-01,7.51e-01,7.63e-01,7.74e-01,$
   7.84e-01,7.94e-01,8.03e-01,8.12e-01,8.20e-01,8.28e-01,8.36e-01,8.43e-01,8.50e-01,$
   8.56e-01,8.63e-01,8.69e-01]
 r_cor[3,*]=[3.82e-06,5.56e-06,7.97e-06,1.13e-05,1.60e-05,2.27e-05,3.23e-05,4.60e-05,$
   6.55e-05,9.31e-05,1.31e-04,1.83e-04,2.51e-04,3.35e-04,4.38e-04,5.60e-04,7.03e-04,$
   8.72e-04,1.07e-03,1.31e-03,1.59e-03,1.92e-03,2.30e-03,2.75e-03,3.25e-03,3.82e-03,$
   4.45e-03,5.15e-03,5.94e-03,6.81e-03,7.77e-03,8.85e-03,1.00e-02,1.13e-02,1.28e-02,$
   1.44e-02,1.62e-02,1.81e-02,2.03e-02,2.27e-02,2.54e-02,2.84e-02,3.16e-02,3.51e-02,$
   3.90e-02,4.32e-02,4.79e-02,5.29e-02,5.84e-02,6.44e-02,7.11e-02,7.85e-02,8.67e-02,$
   9.59e-02,1.06e-01,1.18e-01,1.31e-01,1.46e-01,1.62e-01,1.79e-01,1.97e-01,2.16e-01,$
   2.36e-01,2.56e-01,2.77e-01,2.97e-01,3.18e-01,3.38e-01,3.58e-01,3.77e-01,3.97e-01,$
   4.15e-01,4.33e-01,4.51e-01,4.67e-01,4.84e-01,4.99e-01,5.14e-01,5.28e-01,5.42e-01,$
   5.55e-01,5.68e-01,5.80e-01,5.91e-01,6.02e-01,6.12e-01,6.22e-01,6.31e-01,6.40e-01,$
   6.49e-01,6.57e-01,6.65e-01,6.72e-01,6.79e-01,6.85e-01,6.92e-01,6.98e-01,7.04e-01,$
   7.09e-01,7.14e-01,7.19e-01]
 r_cor[4,*]=[4.03e-06,5.87e-06,8.41e-06,1.19e-05,1.69e-05,2.40e-05,3.41e-05,4.85e-05,$
   6.91e-05,9.82e-05,1.39e-04,1.93e-04,2.65e-04,3.54e-04,4.62e-04,5.91e-04,7.42e-04,$
   9.20e-04,1.13e-03,1.38e-03,1.68e-03,2.02e-03,2.43e-03,2.90e-03,3.43e-03,4.03e-03,$
   4.70e-03,5.44e-03,6.27e-03,7.18e-03,8.20e-03,9.34e-03,1.06e-02,1.20e-02,1.35e-02,$
   1.52e-02,1.71e-02,1.91e-02,2.15e-02,2.40e-02,2.68e-02,2.99e-02,3.33e-02,3.71e-02,$
   4.12e-02,4.56e-02,5.05e-02,5.58e-02,6.16e-02,6.80e-02,7.50e-02,8.28e-02,9.15e-02,$
   1.01e-01,1.12e-01,1.25e-01,1.39e-01,1.54e-01,1.71e-01,1.89e-01,2.08e-01,2.28e-01,$
   2.49e-01,2.70e-01,2.92e-01,3.14e-01,3.35e-01,3.57e-01,3.78e-01,3.98e-01,4.19e-01,$
   4.38e-01,4.57e-01,4.76e-01,4.93e-01,5.10e-01,5.27e-01,5.42e-01,5.58e-01,5.72e-01,$
   5.86e-01,5.99e-01,6.12e-01,6.24e-01,6.35e-01,6.46e-01,6.56e-01,6.66e-01,6.76e-01,$
   6.85e-01,6.93e-01,7.01e-01,7.09e-01,7.16e-01,7.23e-01,7.30e-01,7.36e-01,7.42e-01,$
   7.48e-01,7.54e-01,7.59e-01]
 r_cor[5,*]=[2.76e-06,4.22e-06,6.30e-06,9.30e-06,1.36e-05,1.98e-05,2.89e-05,4.18e-05,$
   6.05e-05,8.71e-05,1.24e-04,1.75e-04,2.41e-04,3.24e-04,4.27e-04,5.50e-04,6.96e-04,$
   8.69e-04,1.07e-03,1.32e-03,1.61e-03,1.95e-03,2.35e-03,2.81e-03,3.34e-03,3.93e-03,$
   4.59e-03,5.33e-03,6.15e-03,7.06e-03,8.07e-03,9.19e-03,1.04e-02,1.18e-02,1.33e-02,$
   1.50e-02,1.69e-02,1.90e-02,2.13e-02,2.39e-02,2.67e-02,2.98e-02,3.33e-02,3.71e-02,$
   4.12e-02,4.57e-02,5.07e-02,5.61e-02,6.21e-02,6.86e-02,7.57e-02,8.37e-02,9.26e-02,$
   1.03e-01,1.14e-01,1.27e-01,1.41e-01,1.57e-01,1.75e-01,1.94e-01,2.14e-01,2.35e-01,$
   2.56e-01,2.79e-01,3.01e-01,3.24e-01,3.47e-01,3.70e-01,3.92e-01,4.14e-01,4.35e-01,$
   4.56e-01,4.76e-01,4.96e-01,5.15e-01,5.33e-01,5.51e-01,5.67e-01,5.84e-01,5.99e-01,$
   6.14e-01,6.28e-01,6.42e-01,6.55e-01,6.67e-01,6.79e-01,6.90e-01,7.01e-01,7.11e-01,$
   7.21e-01,7.30e-01,7.39e-01,7.48e-01,7.56e-01,7.63e-01,7.71e-01,7.78e-01,7.84e-01,$
   7.91e-01,7.97e-01,8.03e-01]
 r_cor[6,*]=[3.31e-06,4.95e-06,7.27e-06,1.06e-05,1.52e-05,2.20e-05,3.17e-05,4.55e-05,$
   6.53e-05,9.32e-05,1.32e-04,1.84e-04,2.51e-04,3.36e-04,4.38e-04,5.61e-04,7.05e-04,$
   8.75e-04,1.08e-03,1.31e-03,1.59e-03,1.93e-03,2.31e-03,2.75e-03,3.26e-03,3.82e-03,$
   4.44e-03,5.14e-03,5.91e-03,6.76e-03,7.70e-03,8.74e-03,9.89e-03,1.12e-02,1.26e-02,$
   1.41e-02,1.58e-02,1.77e-02,1.98e-02,2.21e-02,2.47e-02,2.75e-02,3.06e-02,3.39e-02,$
   3.76e-02,4.16e-02,4.60e-02,5.08e-02,5.60e-02,6.18e-02,6.80e-02,7.50e-02,8.28e-02,$
   9.15e-02,1.01e-01,1.12e-01,1.25e-01,1.38e-01,1.53e-01,1.69e-01,1.86e-01,2.04e-01,$
   2.22e-01,2.41e-01,2.60e-01,2.79e-01,2.98e-01,3.16e-01,3.35e-01,3.53e-01,3.70e-01,$
   3.87e-01,4.04e-01,4.20e-01,4.35e-01,4.50e-01,4.64e-01,4.78e-01,4.91e-01,5.04e-01,$
   5.16e-01,5.27e-01,5.38e-01,5.49e-01,5.59e-01,5.68e-01,5.78e-01,5.86e-01,5.95e-01,$
   6.03e-01,6.10e-01,6.17e-01,6.24e-01,6.31e-01,6.37e-01,6.43e-01,6.48e-01,6.54e-01,$
   6.59e-01,6.64e-01,6.69e-01]
 r_cor[7,*]=[1.63e-06,2.49e-06,3.74e-06,5.54e-06,8.14e-06,1.19e-05,1.74e-05,2.54e-05,$
   3.70e-05,5.36e-05,7.70e-05,1.09e-04,1.51e-04,2.06e-04,2.73e-04,3.55e-04,4.53e-04,$
   5.71e-04,7.12e-04,8.82e-04,1.09e-03,1.33e-03,1.62e-03,1.95e-03,2.33e-03,2.77e-03,$
   3.26e-03,3.81e-03,4.43e-03,5.12e-03,5.90e-03,6.77e-03,7.73e-03,8.81e-03,1.00e-02,$
   1.13e-02,1.28e-02,1.45e-02,1.64e-02,1.84e-02,2.07e-02,2.32e-02,2.61e-02,2.91e-02,$
   3.25e-02,3.63e-02,4.03e-02,4.48e-02,4.97e-02,5.51e-02,6.11e-02,6.78e-02,7.53e-02,$
   8.37e-02,9.33e-02,1.04e-01,1.17e-01,1.30e-01,1.45e-01,1.62e-01,1.79e-01,1.98e-01,$
   2.17e-01,2.36e-01,2.56e-01,2.76e-01,2.96e-01,3.16e-01,3.36e-01,3.56e-01,3.75e-01,$
   3.93e-01,4.12e-01,4.29e-01,4.46e-01,4.62e-01,4.78e-01,4.93e-01,5.08e-01,5.22e-01,$
   5.35e-01,5.48e-01,5.60e-01,5.72e-01,5.83e-01,5.94e-01,6.04e-01,6.14e-01,6.23e-01,$
   6.32e-01,6.40e-01,6.48e-01,6.56e-01,6.63e-01,6.70e-01,6.77e-01,6.83e-01,6.89e-01,$
   6.95e-01,7.00e-01,7.06e-01]
 r_cor[8,*]=[1.81e-06,2.77e-06,4.15e-06,6.12e-06,8.97e-06,1.31e-05,1.91e-05,2.78e-05,$
   4.03e-05,5.83e-05,8.36e-05,1.18e-04,1.64e-04,2.22e-04,2.95e-04,3.82e-04,4.86e-04,$
   6.11e-04,7.60e-04,9.38e-04,1.15e-03,1.41e-03,1.70e-03,2.05e-03,2.45e-03,2.90e-03,$
   3.41e-03,3.97e-03,4.61e-03,5.32e-03,6.11e-03,7.00e-03,7.98e-03,9.08e-03,1.03e-02,$
   1.16e-02,1.32e-02,1.48e-02,1.67e-02,1.88e-02,2.11e-02,2.37e-02,2.65e-02,2.96e-02,$
   3.30e-02,3.67e-02,4.08e-02,4.53e-02,5.02e-02,5.56e-02,6.16e-02,6.82e-02,7.57e-02,$
   8.41e-02,9.36e-02,1.04e-01,1.17e-01,1.30e-01,1.45e-01,1.62e-01,1.79e-01,1.97e-01,$
   2.16e-01,2.35e-01,2.55e-01,2.75e-01,2.95e-01,3.15e-01,3.35e-01,3.54e-01,3.73e-01,$
   3.91e-01,4.09e-01,4.27e-01,4.43e-01,4.60e-01,4.75e-01,4.90e-01,5.05e-01,5.18e-01,$
   5.32e-01,5.44e-01,5.57e-01,5.68e-01,5.79e-01,5.90e-01,6.00e-01,6.10e-01,6.19e-01,$
   6.27e-01,6.36e-01,6.44e-01,6.51e-01,6.58e-01,6.65e-01,6.72e-01,6.78e-01,6.84e-01,$
   6.89e-01,6.95e-01,7.00e-01]
 r_cor[9,*]=[3.00e-06,4.39e-06,6.33e-06,9.04e-06,1.29e-05,1.84e-05,2.63e-05,3.76e-05,$
   5.38e-05,7.67e-05,1.09e-04,1.52e-04,2.08e-04,2.78e-04,3.65e-04,4.68e-04,5.90e-04,$
   7.35e-04,9.07e-04,1.11e-03,1.36e-03,1.65e-03,1.98e-03,2.38e-03,2.82e-03,3.33e-03,$
   3.89e-03,4.52e-03,5.23e-03,6.01e-03,6.88e-03,7.85e-03,8.92e-03,1.01e-02,1.14e-02,$
   1.29e-02,1.45e-02,1.63e-02,1.83e-02,2.05e-02,2.30e-02,2.57e-02,2.87e-02,3.19e-02,$
   3.55e-02,3.94e-02,4.37e-02,4.83e-02,5.35e-02,5.91e-02,6.52e-02,7.21e-02,7.97e-02,$
   8.84e-02,9.81e-02,1.09e-01,1.21e-01,1.35e-01,1.50e-01,1.66e-01,1.83e-01,2.01e-01,$
   2.19e-01,2.38e-01,2.57e-01,2.77e-01,2.96e-01,3.15e-01,3.33e-01,3.52e-01,3.70e-01,$
   3.87e-01,4.04e-01,4.21e-01,4.36e-01,4.52e-01,4.66e-01,4.80e-01,4.94e-01,5.07e-01,$
   5.19e-01,5.31e-01,5.43e-01,5.53e-01,5.64e-01,5.74e-01,5.83e-01,5.92e-01,6.01e-01,$
   6.09e-01,6.17e-01,6.24e-01,6.31e-01,6.38e-01,6.44e-01,6.50e-01,6.56e-01,6.62e-01,$
   6.67e-01,6.72e-01,6.77e-01]
r_cor[10,*]=[2.25e-06,3.35e-06,4.91e-06,7.10e-06,1.02e-05,1.48e-05,2.13e-05,3.07e-05,$
   4.42e-05,6.35e-05,9.04e-05,1.27e-04,1.75e-04,2.36e-04,3.12e-04,4.02e-04,5.10e-04,$
   6.39e-04,7.92e-04,9.76e-04,1.20e-03,1.46e-03,1.76e-03,2.12e-03,2.53e-03,2.99e-03,$
   3.51e-03,4.09e-03,4.74e-03,5.47e-03,6.28e-03,7.19e-03,8.19e-03,9.31e-03,1.06e-02,$
   1.19e-02,1.35e-02,1.52e-02,1.71e-02,1.92e-02,2.16e-02,2.42e-02,2.70e-02,3.02e-02,$
   3.36e-02,3.74e-02,4.16e-02,4.61e-02,5.11e-02,5.66e-02,6.26e-02,6.93e-02,7.69e-02,$
   8.53e-02,9.50e-02,1.06e-01,1.18e-01,1.32e-01,1.47e-01,1.63e-01,1.80e-01,1.98e-01,$
   2.17e-01,2.36e-01,2.55e-01,2.75e-01,2.95e-01,3.14e-01,3.33e-01,3.52e-01,3.71e-01,$
   3.89e-01,4.06e-01,4.23e-01,4.39e-01,4.55e-01,4.70e-01,4.85e-01,4.99e-01,5.13e-01,$
   5.25e-01,5.38e-01,5.50e-01,5.61e-01,5.72e-01,5.82e-01,5.92e-01,6.01e-01,6.10e-01,$
   6.19e-01,6.27e-01,6.34e-01,6.42e-01,6.49e-01,6.55e-01,6.62e-01,6.68e-01,6.74e-01,$
   6.79e-01,6.84e-01,6.90e-01]
r_cor[11,*]=[2.47e-06,3.66e-06,5.34e-06,7.70e-06,1.11e-05,1.59e-05,2.28e-05,3.28e-05,$
   4.71e-05,6.75e-05,9.61e-05,1.35e-04,1.86e-04,2.50e-04,3.28e-04,4.23e-04,5.35e-04,$
   6.69e-04,8.28e-04,1.02e-03,1.25e-03,1.51e-03,1.83e-03,2.20e-03,2.61e-03,3.09e-03,$
   3.62e-03,4.21e-03,4.88e-03,5.62e-03,6.45e-03,7.37e-03,8.39e-03,9.53e-03,1.08e-02,$
   1.22e-02,1.38e-02,1.55e-02,1.74e-02,1.96e-02,2.19e-02,2.46e-02,2.75e-02,3.06e-02,$
   3.41e-02,3.79e-02,4.21e-02,4.67e-02,5.17e-02,5.72e-02,6.32e-02,7.00e-02,7.75e-02,$
   8.61e-02,9.57e-02,1.07e-01,1.19e-01,1.32e-01,1.47e-01,1.64e-01,1.81e-01,1.99e-01,$
   2.17e-01,2.36e-01,2.56e-01,2.75e-01,2.95e-01,3.14e-01,3.33e-01,3.52e-01,3.70e-01,$
   3.88e-01,4.06e-01,4.22e-01,4.39e-01,4.54e-01,4.69e-01,4.84e-01,4.98e-01,5.11e-01,$
   5.24e-01,5.36e-01,5.48e-01,5.59e-01,5.70e-01,5.80e-01,5.90e-01,5.99e-01,6.08e-01,$
   6.16e-01,6.24e-01,6.32e-01,6.39e-01,6.46e-01,6.53e-01,6.59e-01,6.65e-01,6.71e-01,$
   6.76e-01,6.82e-01,6.87e-01]
r_cor[12,*]=[2.21e-06,3.29e-06,4.82e-06,6.98e-06,1.01e-05,1.45e-05,2.09e-05,3.02e-05,$
   4.35e-05,6.25e-05,8.90e-05,1.25e-04,1.73e-04,2.33e-04,3.07e-04,3.96e-04,5.03e-04,$
   6.30e-04,7.81e-04,9.63e-04,1.18e-03,1.44e-03,1.74e-03,2.10e-03,2.50e-03,2.96e-03,$
   3.47e-03,4.05e-03,4.69e-03,5.42e-03,6.22e-03,7.12e-03,8.12e-03,9.24e-03,1.05e-02,$
   1.19e-02,1.34e-02,1.51e-02,1.70e-02,1.91e-02,2.15e-02,2.41e-02,2.69e-02,3.01e-02,$
   3.35e-02,3.73e-02,4.14e-02,4.60e-02,5.10e-02,5.64e-02,6.25e-02,6.92e-02,7.67e-02,$
   8.52e-02,9.49e-02,1.06e-01,1.18e-01,1.32e-01,1.47e-01,1.63e-01,1.80e-01,1.98e-01,$
   2.17e-01,2.36e-01,2.56e-01,2.75e-01,2.95e-01,3.15e-01,3.34e-01,3.53e-01,3.72e-01,$
   3.90e-01,4.07e-01,4.24e-01,4.41e-01,4.57e-01,4.72e-01,4.87e-01,5.01e-01,5.14e-01,$
   5.27e-01,5.40e-01,5.52e-01,5.63e-01,5.74e-01,5.84e-01,5.94e-01,6.03e-01,6.12e-01,$
   6.21e-01,6.29e-01,6.37e-01,6.44e-01,6.51e-01,6.58e-01,6.64e-01,6.70e-01,6.76e-01,$
   6.82e-01,6.87e-01,6.92e-01]
r_cor[13,*]=[2.21e-06,3.29e-06,4.82e-06,6.98e-06,1.01e-05,1.45e-05,2.09e-05,3.02e-05,$
   4.35e-05,6.25e-05,8.90e-05,1.25e-04,1.73e-04,2.33e-04,3.07e-04,3.96e-04,5.03e-04,$
   6.30e-04,7.81e-04,9.63e-04,1.18e-03,1.44e-03,1.74e-03,2.10e-03,2.50e-03,2.96e-03,$
   3.47e-03,4.05e-03,4.69e-03,5.42e-03,6.22e-03,7.12e-03,8.12e-03,9.24e-03,1.05e-02,$
   1.19e-02,1.34e-02,1.51e-02,1.70e-02,1.91e-02,2.15e-02,2.41e-02,2.69e-02,3.01e-02,$
   3.35e-02,3.73e-02,4.14e-02,4.60e-02,5.10e-02,5.64e-02,6.25e-02,6.92e-02,7.67e-02,$
   8.52e-02,9.49e-02,1.06e-01,1.18e-01,1.32e-01,1.47e-01,1.63e-01,1.80e-01,1.98e-01,$
   2.17e-01,2.36e-01,2.56e-01,2.75e-01,2.95e-01,3.15e-01,3.34e-01,3.53e-01,3.72e-01,$
   3.90e-01,4.07e-01,4.24e-01,4.41e-01,4.57e-01,4.72e-01,4.87e-01,5.01e-01,5.14e-01,$
   5.27e-01,5.40e-01,5.52e-01,5.63e-01,5.74e-01,5.84e-01,5.94e-01,6.03e-01,6.12e-01,$
   6.21e-01,6.29e-01,6.37e-01,6.44e-01,6.51e-01,6.58e-01,6.64e-01,6.70e-01,6.76e-01,$
   6.82e-01,6.87e-01,6.92e-01]
r_cor[14,*]=[2.43e-06,3.63e-06,5.31e-06,7.69e-06,1.11e-05,1.59e-05,2.29e-05,3.30e-05,$
   4.74e-05,6.80e-05,9.68e-05,1.36e-04,1.88e-04,2.53e-04,3.33e-04,4.29e-04,5.43e-04,$
   6.78e-04,8.39e-04,1.03e-03,1.26e-03,1.53e-03,1.84e-03,2.21e-03,2.63e-03,3.10e-03,$
   3.63e-03,4.22e-03,4.89e-03,5.62e-03,6.45e-03,7.36e-03,8.38e-03,9.51e-03,1.08e-02,$
   1.22e-02,1.37e-02,1.54e-02,1.74e-02,1.95e-02,2.19e-02,2.45e-02,2.73e-02,3.05e-02,$
   3.40e-02,3.78e-02,4.19e-02,4.65e-02,5.14e-02,5.69e-02,6.30e-02,6.97e-02,7.72e-02,$
   8.57e-02,9.53e-02,1.06e-01,1.18e-01,1.32e-01,1.47e-01,1.63e-01,1.80e-01,1.98e-01,$
   2.17e-01,2.36e-01,2.56e-01,2.76e-01,2.96e-01,3.15e-01,3.35e-01,3.54e-01,3.72e-01,$
   3.90e-01,4.08e-01,4.25e-01,4.42e-01,4.58e-01,4.73e-01,4.88e-01,5.02e-01,5.16e-01,$
   5.29e-01,5.41e-01,5.53e-01,5.64e-01,5.75e-01,5.86e-01,5.96e-01,6.05e-01,6.14e-01,$
   6.23e-01,6.31e-01,6.39e-01,6.46e-01,6.53e-01,6.60e-01,6.66e-01,6.72e-01,6.78e-01,$
   6.84e-01,6.89e-01,6.94e-01]

r_pho=fltarr(15,101)

 r_pho[0,*]=[5.19e-06,7.91e-06,1.18e-05,1.74e-05,2.54e-05,3.66e-05,5.23e-05,7.42e-05,$
   1.04e-04,1.46e-04,2.02e-04,2.76e-04,3.72e-04,4.93e-04,6.45e-04,8.32e-04,1.06e-03,$
   1.34e-03,1.68e-03,2.11e-03,2.62e-03,3.25e-03,4.00e-03,4.87e-03,5.88e-03,7.02e-03,$
   8.29e-03,9.69e-03,1.12e-02,1.29e-02,1.48e-02,1.68e-02,1.91e-02,2.15e-02,2.41e-02,$
   2.69e-02,3.00e-02,3.33e-02,3.68e-02,4.07e-02,4.48e-02,4.93e-02,5.41e-02,5.92e-02,$
   6.48e-02,7.07e-02,7.71e-02,8.40e-02,9.14e-02,9.93e-02,1.08e-01,1.17e-01,1.27e-01,$
   1.38e-01,1.49e-01,1.62e-01,1.76e-01,1.91e-01,2.07e-01,2.23e-01,2.40e-01,2.58e-01,$
   2.76e-01,2.95e-01,3.13e-01,3.32e-01,3.51e-01,3.70e-01,3.88e-01,4.07e-01,4.25e-01,$
   4.43e-01,4.60e-01,4.78e-01,4.95e-01,5.11e-01,5.27e-01,5.43e-01,5.58e-01,5.73e-01,$
   5.88e-01,6.02e-01,6.16e-01,6.30e-01,6.43e-01,6.56e-01,6.68e-01,6.81e-01,6.92e-01,$
   7.04e-01,7.15e-01,7.26e-01,7.36e-01,7.47e-01,7.57e-01,7.66e-01,7.76e-01,7.85e-01,$
   7.94e-01,8.03e-01,8.12e-01]
 r_pho[1,*]=[5.13e-06,7.82e-06,1.17e-05,1.72e-05,2.51e-05,3.62e-05,5.17e-05,7.33e-05,$
   1.03e-04,1.44e-04,1.99e-04,2.73e-04,3.67e-04,4.88e-04,6.38e-04,8.23e-04,1.05e-03,$
   1.33e-03,1.67e-03,2.08e-03,2.59e-03,3.21e-03,3.95e-03,4.82e-03,5.81e-03,6.94e-03,$
   8.19e-03,9.58e-03,1.11e-02,1.28e-02,1.46e-02,1.67e-02,1.88e-02,2.12e-02,2.38e-02,$
   2.66e-02,2.96e-02,3.29e-02,3.64e-02,4.02e-02,4.43e-02,4.87e-02,5.34e-02,5.86e-02,$
   6.40e-02,6.99e-02,7.63e-02,8.30e-02,9.03e-02,9.82e-02,1.07e-01,1.16e-01,1.25e-01,$
   1.36e-01,1.48e-01,1.60e-01,1.74e-01,1.89e-01,2.04e-01,2.21e-01,2.38e-01,2.55e-01,$
   2.73e-01,2.91e-01,3.10e-01,3.28e-01,3.47e-01,3.66e-01,3.84e-01,4.02e-01,4.20e-01,$
   4.38e-01,4.55e-01,4.72e-01,4.89e-01,5.05e-01,5.21e-01,5.37e-01,5.52e-01,5.67e-01,$
   5.82e-01,5.96e-01,6.09e-01,6.23e-01,6.36e-01,6.49e-01,6.61e-01,6.73e-01,6.85e-01,$
   6.96e-01,7.07e-01,7.18e-01,7.28e-01,7.38e-01,7.48e-01,7.58e-01,7.67e-01,7.76e-01,$
   7.85e-01,7.94e-01,8.02e-01]
 r_pho[2,*]=[5.13e-06,7.82e-06,1.17e-05,1.72e-05,2.51e-05,3.62e-05,5.17e-05,7.33e-05,$
   1.03e-04,1.44e-04,1.99e-04,2.73e-04,3.67e-04,4.88e-04,6.38e-04,8.23e-04,1.05e-03,$
   1.33e-03,1.67e-03,2.08e-03,2.59e-03,3.21e-03,3.95e-03,4.82e-03,5.81e-03,6.94e-03,$
   8.19e-03,9.58e-03,1.11e-02,1.28e-02,1.46e-02,1.67e-02,1.88e-02,2.12e-02,2.38e-02,$
   2.66e-02,2.96e-02,3.29e-02,3.64e-02,4.02e-02,4.43e-02,4.87e-02,5.34e-02,5.86e-02,$
   6.40e-02,6.99e-02,7.63e-02,8.30e-02,9.03e-02,9.82e-02,1.07e-01,1.16e-01,1.25e-01,$
   1.36e-01,1.48e-01,1.60e-01,1.74e-01,1.89e-01,2.04e-01,2.21e-01,2.38e-01,2.55e-01,$
   2.73e-01,2.91e-01,3.10e-01,3.28e-01,3.47e-01,3.66e-01,3.84e-01,4.02e-01,4.20e-01,$
   4.38e-01,4.55e-01,4.72e-01,4.89e-01,5.05e-01,5.21e-01,5.37e-01,5.52e-01,5.67e-01,$
   5.82e-01,5.96e-01,6.09e-01,6.23e-01,6.36e-01,6.49e-01,6.61e-01,6.73e-01,6.85e-01,$
   6.96e-01,7.07e-01,7.18e-01,7.28e-01,7.38e-01,7.48e-01,7.58e-01,7.67e-01,7.76e-01,$
   7.85e-01,7.94e-01,8.02e-01]
 r_pho[3,*]=[4.25e-06,6.47e-06,9.68e-06,1.43e-05,2.08e-05,2.99e-05,4.28e-05,6.07e-05,$
   8.55e-05,1.19e-04,1.65e-04,2.26e-04,3.04e-04,4.04e-04,5.28e-04,6.81e-04,8.68e-04,$
   1.10e-03,1.38e-03,1.72e-03,2.15e-03,2.66e-03,3.27e-03,3.99e-03,4.81e-03,5.74e-03,$
   6.78e-03,7.93e-03,9.20e-03,1.06e-02,1.21e-02,1.38e-02,1.56e-02,1.76e-02,1.97e-02,$
   2.20e-02,2.45e-02,2.72e-02,3.01e-02,3.33e-02,3.67e-02,4.03e-02,4.42e-02,4.85e-02,$
   5.30e-02,5.79e-02,6.31e-02,6.87e-02,7.48e-02,8.13e-02,8.82e-02,9.57e-02,1.04e-01,$
   1.13e-01,1.22e-01,1.33e-01,1.44e-01,1.56e-01,1.69e-01,1.83e-01,1.97e-01,2.11e-01,$
   2.26e-01,2.41e-01,2.57e-01,2.72e-01,2.87e-01,3.03e-01,3.18e-01,3.33e-01,3.48e-01,$
   3.62e-01,3.77e-01,3.91e-01,4.05e-01,4.18e-01,4.32e-01,4.44e-01,4.57e-01,4.69e-01,$
   4.81e-01,4.93e-01,5.04e-01,5.16e-01,5.26e-01,5.37e-01,5.47e-01,5.57e-01,5.67e-01,$
   5.76e-01,5.85e-01,5.94e-01,6.03e-01,6.11e-01,6.19e-01,6.27e-01,6.35e-01,6.43e-01,$
   6.50e-01,6.57e-01,6.64e-01]
 r_pho[4,*]=[4.48e-06,6.83e-06,1.02e-05,1.50e-05,2.19e-05,3.16e-05,4.52e-05,6.41e-05,$
   9.02e-05,1.26e-04,1.74e-04,2.38e-04,3.21e-04,4.26e-04,5.57e-04,7.19e-04,9.16e-04,$
   1.16e-03,1.45e-03,1.82e-03,2.27e-03,2.81e-03,3.45e-03,4.21e-03,5.08e-03,6.06e-03,$
   7.16e-03,8.37e-03,9.71e-03,1.12e-02,1.28e-02,1.45e-02,1.65e-02,1.86e-02,2.08e-02,$
   2.32e-02,2.59e-02,2.87e-02,3.18e-02,3.51e-02,3.87e-02,4.26e-02,4.67e-02,5.12e-02,$
   5.59e-02,6.11e-02,6.66e-02,7.25e-02,7.89e-02,8.57e-02,9.31e-02,1.01e-01,1.10e-01,$
   1.19e-01,1.29e-01,1.40e-01,1.52e-01,1.65e-01,1.78e-01,1.93e-01,2.08e-01,2.23e-01,$
   2.39e-01,2.55e-01,2.71e-01,2.87e-01,3.03e-01,3.19e-01,3.35e-01,3.51e-01,3.67e-01,$
   3.82e-01,3.98e-01,4.13e-01,4.27e-01,4.41e-01,4.55e-01,4.69e-01,4.82e-01,4.95e-01,$
   5.08e-01,5.20e-01,5.32e-01,5.44e-01,5.55e-01,5.67e-01,5.77e-01,5.88e-01,5.98e-01,$
   6.08e-01,6.18e-01,6.27e-01,6.36e-01,6.45e-01,6.54e-01,6.62e-01,6.70e-01,6.78e-01,$
   6.86e-01,6.94e-01,7.01e-01]
 r_pho[5,*]=[3.06e-06,4.89e-06,7.62e-06,1.17e-05,1.76e-05,2.61e-05,3.82e-05,5.54e-05,$
   7.94e-05,1.13e-04,1.58e-04,2.18e-04,2.97e-04,3.97e-04,5.23e-04,6.80e-04,8.72e-04,$
   1.11e-03,1.40e-03,1.76e-03,2.20e-03,2.74e-03,3.38e-03,4.13e-03,4.99e-03,5.97e-03,$
   7.06e-03,8.27e-03,9.60e-03,1.11e-02,1.27e-02,1.44e-02,1.63e-02,1.84e-02,2.07e-02,$
   2.31e-02,2.58e-02,2.86e-02,3.17e-02,3.51e-02,3.87e-02,4.26e-02,4.68e-02,5.13e-02,$
   5.62e-02,6.15e-02,6.71e-02,7.32e-02,7.97e-02,8.67e-02,9.42e-02,1.02e-01,1.11e-01,$
   1.21e-01,1.31e-01,1.43e-01,1.55e-01,1.68e-01,1.83e-01,1.97e-01,2.13e-01,2.29e-01,$
   2.45e-01,2.62e-01,2.79e-01,2.96e-01,3.13e-01,3.30e-01,3.47e-01,3.64e-01,3.81e-01,$
   3.97e-01,4.13e-01,4.29e-01,4.45e-01,4.60e-01,4.75e-01,4.89e-01,5.04e-01,5.18e-01,$
   5.31e-01,5.45e-01,5.58e-01,5.70e-01,5.82e-01,5.94e-01,6.06e-01,6.17e-01,6.28e-01,$
   6.39e-01,6.50e-01,6.60e-01,6.70e-01,6.79e-01,6.89e-01,6.98e-01,7.07e-01,7.16e-01,$
   7.24e-01,7.32e-01,7.41e-01]
 r_pho[6,*]=[3.76e-06,5.89e-06,9.03e-06,1.36e-05,2.02e-05,2.95e-05,4.28e-05,6.14e-05,$
   8.71e-05,1.22e-04,1.70e-04,2.32e-04,3.13e-04,4.15e-04,5.42e-04,6.99e-04,8.90e-04,$
   1.12e-03,1.41e-03,1.76e-03,2.19e-03,2.70e-03,3.32e-03,4.03e-03,4.85e-03,5.78e-03,$
   6.80e-03,7.93e-03,9.16e-03,1.05e-02,1.20e-02,1.36e-02,1.53e-02,1.72e-02,1.93e-02,$
   2.15e-02,2.38e-02,2.64e-02,2.92e-02,3.21e-02,3.53e-02,3.87e-02,4.24e-02,4.64e-02,$
   5.07e-02,5.52e-02,6.01e-02,6.54e-02,7.10e-02,7.70e-02,8.35e-02,9.06e-02,9.81e-02,$
   1.06e-01,1.15e-01,1.25e-01,1.36e-01,1.47e-01,1.59e-01,1.71e-01,1.84e-01,1.98e-01,$
   2.11e-01,2.25e-01,2.39e-01,2.54e-01,2.68e-01,2.82e-01,2.96e-01,3.10e-01,3.24e-01,$
   3.37e-01,3.50e-01,3.63e-01,3.76e-01,3.89e-01,4.01e-01,4.13e-01,4.25e-01,4.36e-01,$
   4.47e-01,4.58e-01,4.69e-01,4.79e-01,4.89e-01,4.99e-01,5.08e-01,5.17e-01,5.26e-01,$
   5.35e-01,5.44e-01,5.52e-01,5.60e-01,5.68e-01,5.76e-01,5.83e-01,5.90e-01,5.98e-01,$
   6.05e-01,6.11e-01,6.18e-01]
 r_pho[7,*]=[1.77e-06,2.84e-06,4.44e-06,6.82e-06,1.03e-05,1.54e-05,2.27e-05,3.31e-05,$
   4.79e-05,6.85e-05,9.68e-05,1.35e-04,1.85e-04,2.51e-04,3.34e-04,4.38e-04,5.68e-04,$
   7.30e-04,9.32e-04,1.18e-03,1.49e-03,1.87e-03,2.33e-03,2.88e-03,3.51e-03,4.23e-03,$
   5.04e-03,5.94e-03,6.95e-03,8.06e-03,9.30e-03,1.07e-02,1.22e-02,1.38e-02,1.56e-02,$
   1.75e-02,1.96e-02,2.19e-02,2.44e-02,2.72e-02,3.01e-02,3.33e-02,3.68e-02,4.05e-02,$
   4.45e-02,4.89e-02,5.36e-02,5.87e-02,6.41e-02,7.00e-02,7.64e-02,8.33e-02,9.08e-02,$
   9.90e-02,1.08e-01,1.18e-01,1.28e-01,1.40e-01,1.52e-01,1.65e-01,1.79e-01,1.93e-01,$
   2.07e-01,2.22e-01,2.37e-01,2.52e-01,2.67e-01,2.82e-01,2.97e-01,3.12e-01,3.27e-01,$
   3.41e-01,3.56e-01,3.70e-01,3.84e-01,3.97e-01,4.11e-01,4.24e-01,4.36e-01,4.49e-01,$
   4.61e-01,4.73e-01,4.85e-01,4.96e-01,5.07e-01,5.18e-01,5.28e-01,5.38e-01,5.48e-01,$
   5.58e-01,5.67e-01,5.77e-01,5.85e-01,5.94e-01,6.03e-01,6.11e-01,6.19e-01,6.27e-01,$
   6.34e-01,6.42e-01,6.49e-01]
 r_pho[8,*]=[1.97e-06,3.14e-06,4.90e-06,7.51e-06,1.13e-05,1.68e-05,2.48e-05,3.60e-05,$
   5.19e-05,7.41e-05,1.04e-04,1.45e-04,1.99e-04,2.69e-04,3.57e-04,4.68e-04,6.05e-04,$
   7.76e-04,9.87e-04,1.25e-03,1.57e-03,1.97e-03,2.45e-03,3.01e-03,3.67e-03,4.41e-03,$
   5.25e-03,6.18e-03,7.22e-03,8.37e-03,9.63e-03,1.10e-02,1.26e-02,1.42e-02,1.60e-02,$
   1.80e-02,2.02e-02,2.25e-02,2.51e-02,2.78e-02,3.08e-02,3.40e-02,3.75e-02,4.13e-02,$
   4.54e-02,4.97e-02,5.45e-02,5.96e-02,6.50e-02,7.10e-02,7.73e-02,8.42e-02,9.17e-02,$
   9.99e-02,1.09e-01,1.19e-01,1.29e-01,1.41e-01,1.53e-01,1.66e-01,1.79e-01,1.93e-01,$
   2.07e-01,2.22e-01,2.37e-01,2.52e-01,2.67e-01,2.82e-01,2.96e-01,3.11e-01,3.26e-01,$
   3.40e-01,3.55e-01,3.69e-01,3.82e-01,3.96e-01,4.09e-01,4.22e-01,4.34e-01,4.47e-01,$
   4.59e-01,4.71e-01,4.82e-01,4.93e-01,5.04e-01,5.15e-01,5.25e-01,5.35e-01,5.45e-01,$
   5.55e-01,5.64e-01,5.73e-01,5.82e-01,5.90e-01,5.99e-01,6.07e-01,6.15e-01,6.22e-01,$
   6.30e-01,6.37e-01,6.44e-01]
 r_pho[9,*]=[3.37e-06,5.17e-06,7.77e-06,1.15e-05,1.69e-05,2.45e-05,3.52e-05,5.01e-05,$
   7.09e-05,9.95e-05,1.38e-04,1.89e-04,2.56e-04,3.41e-04,4.47e-04,5.78e-04,7.40e-04,$
   9.39e-04,1.18e-03,1.49e-03,1.86e-03,2.31e-03,2.85e-03,3.48e-03,4.21e-03,5.04e-03,$
   5.96e-03,6.98e-03,8.11e-03,9.36e-03,1.07e-02,1.22e-02,1.39e-02,1.56e-02,1.76e-02,$
   1.96e-02,2.19e-02,2.44e-02,2.70e-02,2.99e-02,3.29e-02,3.63e-02,3.99e-02,4.37e-02,$
   4.79e-02,5.23e-02,5.71e-02,6.23e-02,6.79e-02,7.38e-02,8.03e-02,8.72e-02,9.47e-02,$
   1.03e-01,1.12e-01,1.22e-01,1.32e-01,1.43e-01,1.55e-01,1.68e-01,1.81e-01,1.95e-01,$
   2.09e-01,2.23e-01,2.37e-01,2.51e-01,2.66e-01,2.80e-01,2.95e-01,3.09e-01,3.23e-01,$
   3.36e-01,3.50e-01,3.63e-01,3.76e-01,3.89e-01,4.02e-01,4.14e-01,4.26e-01,4.38e-01,$
   4.49e-01,4.60e-01,4.71e-01,4.82e-01,4.92e-01,5.02e-01,5.12e-01,5.22e-01,5.31e-01,$
   5.40e-01,5.49e-01,5.57e-01,5.65e-01,5.74e-01,5.81e-01,5.89e-01,5.97e-01,6.04e-01,$
   6.11e-01,6.18e-01,6.25e-01]
r_pho[10,*]=[2.49e-06,3.87e-06,5.91e-06,8.88e-06,1.32e-05,1.93e-05,2.81e-05,4.04e-05,$
   5.77e-05,8.15e-05,1.14e-04,1.58e-04,2.15e-04,2.88e-04,3.80e-04,4.96e-04,6.38e-04,$
   8.15e-04,1.03e-03,1.30e-03,1.64e-03,2.05e-03,2.54e-03,3.11e-03,3.78e-03,4.54e-03,$
   5.39e-03,6.34e-03,7.40e-03,8.56e-03,9.84e-03,1.13e-02,1.28e-02,1.45e-02,1.63e-02,$
   1.83e-02,2.05e-02,2.28e-02,2.54e-02,2.82e-02,3.12e-02,3.44e-02,3.79e-02,4.17e-02,$
   4.57e-02,5.01e-02,5.48e-02,5.99e-02,6.54e-02,7.13e-02,7.77e-02,8.46e-02,9.21e-02,$
   1.00e-01,1.09e-01,1.19e-01,1.29e-01,1.41e-01,1.53e-01,1.66e-01,1.79e-01,1.93e-01,$
   2.07e-01,2.21e-01,2.36e-01,2.50e-01,2.65e-01,2.80e-01,2.94e-01,3.09e-01,3.23e-01,$
   3.38e-01,3.51e-01,3.65e-01,3.79e-01,3.92e-01,4.05e-01,4.17e-01,4.30e-01,4.42e-01,$
   4.54e-01,4.65e-01,4.76e-01,4.87e-01,4.98e-01,5.08e-01,5.19e-01,5.28e-01,5.38e-01,$
   5.47e-01,5.57e-01,5.65e-01,5.74e-01,5.82e-01,5.91e-01,5.99e-01,6.06e-01,6.14e-01,$
   6.21e-01,6.29e-01,6.36e-01]
r_pho[11,*]=[2.73e-06,4.24e-06,6.45e-06,9.64e-06,1.42e-05,2.08e-05,3.01e-05,4.32e-05,$
   6.15e-05,8.68e-05,1.21e-04,1.67e-04,2.27e-04,3.04e-04,4.00e-04,5.20e-04,6.68e-04,$
   8.51e-04,1.08e-03,1.36e-03,1.70e-03,2.12e-03,2.62e-03,3.22e-03,3.90e-03,4.68e-03,$
   5.55e-03,6.52e-03,7.60e-03,8.78e-03,1.01e-02,1.15e-02,1.31e-02,1.48e-02,1.67e-02,$
   1.87e-02,2.09e-02,2.33e-02,2.59e-02,2.86e-02,3.17e-02,3.49e-02,3.85e-02,4.23e-02,$
   4.64e-02,5.08e-02,5.55e-02,6.06e-02,6.61e-02,7.21e-02,7.85e-02,8.54e-02,9.29e-02,$
   1.01e-01,1.10e-01,1.20e-01,1.30e-01,1.42e-01,1.54e-01,1.66e-01,1.80e-01,1.93e-01,$
   2.07e-01,2.22e-01,2.36e-01,2.51e-01,2.65e-01,2.80e-01,2.95e-01,3.09e-01,3.23e-01,$
   3.37e-01,3.51e-01,3.65e-01,3.78e-01,3.91e-01,4.04e-01,4.17e-01,4.29e-01,4.41e-01,$
   4.53e-01,4.64e-01,4.75e-01,4.86e-01,4.97e-01,5.07e-01,5.17e-01,5.27e-01,5.36e-01,$
   5.46e-01,5.55e-01,5.64e-01,5.72e-01,5.80e-01,5.89e-01,5.96e-01,6.04e-01,6.12e-01,$
   6.19e-01,6.26e-01,6.33e-01]
r_pho[12,*]=[2.44e-06,3.80e-06,5.81e-06,8.73e-06,1.29e-05,1.90e-05,2.76e-05,3.97e-05,$
   5.67e-05,8.03e-05,1.12e-04,1.55e-04,2.12e-04,2.84e-04,3.75e-04,4.89e-04,6.29e-04,$
   8.04e-04,1.02e-03,1.29e-03,1.62e-03,2.02e-03,2.51e-03,3.08e-03,3.74e-03,4.49e-03,$
   5.34e-03,6.28e-03,7.32e-03,8.48e-03,9.75e-03,1.12e-02,1.27e-02,1.44e-02,1.62e-02,$
   1.82e-02,2.03e-02,2.27e-02,2.52e-02,2.80e-02,3.10e-02,3.42e-02,3.77e-02,4.15e-02,$
   4.55e-02,4.99e-02,5.47e-02,5.97e-02,6.52e-02,7.11e-02,7.75e-02,8.44e-02,9.19e-02,$
   1.00e-01,1.09e-01,1.19e-01,1.29e-01,1.41e-01,1.53e-01,1.66e-01,1.79e-01,1.93e-01,$
   2.07e-01,2.21e-01,2.36e-01,2.51e-01,2.66e-01,2.80e-01,2.95e-01,3.10e-01,3.24e-01,$
   3.38e-01,3.52e-01,3.66e-01,3.80e-01,3.93e-01,4.06e-01,4.19e-01,4.31e-01,4.43e-01,$
   4.55e-01,4.67e-01,4.78e-01,4.89e-01,5.00e-01,5.10e-01,5.20e-01,5.30e-01,5.40e-01,$
   5.49e-01,5.58e-01,5.67e-01,5.76e-01,5.84e-01,5.93e-01,6.01e-01,6.09e-01,6.16e-01,$
   6.24e-01,6.31e-01,6.38e-01]
r_pho[13,*]=[2.44e-06,3.80e-06,5.81e-06,8.73e-06,1.29e-05,1.90e-05,2.76e-05,3.97e-05,$
   5.67e-05,8.03e-05,1.12e-04,1.55e-04,2.12e-04,2.84e-04,3.75e-04,4.89e-04,6.29e-04,$
   8.04e-04,1.02e-03,1.29e-03,1.62e-03,2.02e-03,2.51e-03,3.08e-03,3.74e-03,4.49e-03,$
   5.34e-03,6.28e-03,7.32e-03,8.48e-03,9.75e-03,1.12e-02,1.27e-02,1.44e-02,1.62e-02,$
   1.82e-02,2.03e-02,2.27e-02,2.52e-02,2.80e-02,3.10e-02,3.42e-02,3.77e-02,4.15e-02,$
   4.55e-02,4.99e-02,5.47e-02,5.97e-02,6.52e-02,7.11e-02,7.75e-02,8.44e-02,9.19e-02,$
   1.00e-01,1.09e-01,1.19e-01,1.29e-01,1.41e-01,1.53e-01,1.66e-01,1.79e-01,1.93e-01,$
   2.07e-01,2.21e-01,2.36e-01,2.51e-01,2.66e-01,2.80e-01,2.95e-01,3.10e-01,3.24e-01,$
   3.38e-01,3.52e-01,3.66e-01,3.80e-01,3.93e-01,4.06e-01,4.19e-01,4.31e-01,4.43e-01,$
   4.55e-01,4.67e-01,4.78e-01,4.89e-01,5.00e-01,5.10e-01,5.20e-01,5.30e-01,5.40e-01,$
   5.49e-01,5.58e-01,5.67e-01,5.76e-01,5.84e-01,5.93e-01,6.01e-01,6.09e-01,6.16e-01,$
   6.24e-01,6.31e-01,6.38e-01]
r_pho[14,*]=[2.65e-06,4.14e-06,6.32e-06,9.48e-06,1.40e-05,2.06e-05,2.98e-05,4.29e-05,$
   6.11e-05,8.63e-05,1.21e-04,1.66e-04,2.27e-04,3.04e-04,4.01e-04,5.21e-04,6.70e-04,$
   8.53e-04,1.08e-03,1.36e-03,1.70e-03,2.12e-03,2.63e-03,3.22e-03,3.91e-03,4.69e-03,$
   5.56e-03,6.54e-03,7.62e-03,8.81e-03,1.01e-02,1.16e-02,1.31e-02,1.49e-02,1.67e-02,$
   1.88e-02,2.10e-02,2.34e-02,2.60e-02,2.88e-02,3.18e-02,3.51e-02,3.86e-02,4.24e-02,$
   4.66e-02,5.10e-02,5.58e-02,6.09e-02,6.65e-02,7.24e-02,7.88e-02,8.58e-02,9.33e-02,$
   1.02e-01,1.11e-01,1.20e-01,1.31e-01,1.42e-01,1.54e-01,1.67e-01,1.81e-01,1.95e-01,$
   2.09e-01,2.23e-01,2.38e-01,2.53e-01,2.67e-01,2.82e-01,2.97e-01,3.12e-01,3.26e-01,$
   3.40e-01,3.54e-01,3.68e-01,3.82e-01,3.95e-01,4.08e-01,4.21e-01,4.33e-01,4.45e-01,$
   4.57e-01,4.69e-01,4.80e-01,4.91e-01,5.02e-01,5.12e-01,5.22e-01,5.32e-01,5.42e-01,$
   5.51e-01,5.60e-01,5.69e-01,5.78e-01,5.86e-01,5.95e-01,6.03e-01,6.10e-01,6.18e-01,$
   6.26e-01,6.33e-01,6.40e-01]

if keyword_set(sat) then gsat=fix(sat-1)>0<14 else gsat=8-1 ; subtract 1 to get array index
if keyword_set(photospheric) then rdat=reform(r_pho[gsat,*]) else rdat=reform(r_cor[gsat,*])

; simplest version: linear interpolation is not as good as it needs to be:
; inx=findex(rdat,r)
; if (inx[0] gt 0.0) then print,'Quick: ',10^(inx[0]*0.05) else temp=1.0

; do spline fit instead

logtemp=findgen(101)*0.02       ; temp in MK as in goes_tem
int_ftn=spl_init(rdat,logtemp,/double)
; make sure ratio is within fitted range
temp=10.d0^(spl_interp(rdat,logtemp,int_ftn,(r>min(rdat))<max(rdat),/double))

; print,'Spline result: ',temp

end
