;+
; :Author: alpa3266
; 
; FILE: fism_daily_stan_bands
; 
; Purpose: Get the stan bands for the FISM daily data
; 
; Inputs: (all optional)
; 
; stdoy - The start yyyydoy to begin at, if no start day is given, it will be set to 1947045
; eddoy - The end yyyydoy to stop execution after, if no end day is given, it will be 
;   set to 5 days previous to the current day
; update - If the update keyword is used, only the past 60 days will be updated (up to 5 days 
;   in the past)
; ncdf - keyword for having the result saved as a NetCDF file, default is .sav 
; 
; Example call:
; 
; fism_flare_stan_bands, stdoy=2005048, eddoy=2005051, /ncdf
; 
; Information:
; Files that are produced will be in photons, these files can be either .sav or NetCDF files, if the 
;   desired output is in watts, remove the /inverse keyword from line 113 in the stan_bands file.
;-


pro fism_daily_stan_bands, stdoy = stdoy, eddoy=eddoy, update=update, ncdf=ncdf

print, 'Running fism_daily_stan_bands... ', !stime
if not keyword_set(stdoy) then stdoy = 1947045
tdy=fix(get_current_yyyydoy(),type=3)
if keyword_set(update) then begin
  ;tdy=long(strmid(get_current_yyyydoy(), 7,8))
  end_yd=fix(get_prev_yyyydoy(tdy,1),type=3)
  stdoy=get_prev_yyyydoy(tdy,90) ; run for the past 90 days
endif
styd=strtrim(stdoy,2)
styr=strmid(styd,0,4)
dir = expand_path('$fism_results') + '/daily_bands/netcdf/'
FILE_MKDIR, string(dir)
restore, expand_path('$fism_save') + '/fism_version_file.sav
if keyword_set(eddoy) and not keyword_set(update) then end_yd = eddoy else end_yd=fix(get_prev_yyyydoy(tdy,1),type=3)

; if not keyword_set(eddoy) then begin
;   ;get the current day and subtract 5 for sorce data
;   curr_doy = fix(get_current_yyyydoy(), type=3)
;   cur_d = fix(strmid(curr_doy, 9,3), type=2)
;   end_y = fix(strmid(curr_doy, 5,4), type=2)
;   this_y = fix(strmid(curr_doy, 3,4), type=3)
;   end_d = cur_d -5
;   ; if its the beginning of the year -> go back to last yeat
;   if cur_d lt 5 then begin
;     end_y = this_y -1
;     ; check if last year was a leap year
;     if leap_year(end_y) gt 0 then begin
;       case cur_d of
;         1: end_d = 362
;         2: end_d = 363
;         3: end_d = 364
;         4: end_d = 365
;         5: end_d = 366
;         else: end_d = 365
;       endcase
;     endif else begin
;       case cur_d of
;         1: end_d = 361
;         2: end_d = 362
;         3: end_d = 363
;         4: end_d = 364
;         5: end_d = 365
;         else: end_d = 365
;       endcase
;     endelse
;   endif
;   end_yd = end_y*fix(1000,type=3)+end_d
; endif
tmp_yd = fix(styd, type=3)

while tmp_yd lt end_yd do begin
  yrst=strmid(tmp_yd,5,4)  
  
  ;set save information 
  date=strmid(tmp_yd, 5, 7)
  date_sec=43200.000 ; set to midday for daily
  ;band_width is the total width of each band 
  band_width= [0.350000,  0.400000, 1.00000,  1.40000,  3.80000,  8.50000,  6.90000,  6.60000,  3.00000, $
  22.0000,11.0000,14.8000,  14.8000,  11.5000,  11.5000,  11.5000,  6.20000,  6.20000,  6.20000,  $
  1.20000,  4.00000,  2.30000, 16.00000]
  
  ;get the fism data to use for the bands
  file = '/FISM_daily_' + strmid(tmp_yd, 5, 7) + '_v' + version + '.sav'
  restore, expand_path('$fism_results') + '/daily_hr_data/' + yrst + file
  
  ;create the stan bands with data in photons 
  ssi = stan_bands(irradiance,wavelength, /photons)
  ;wavelength holds the median wavelength for each bin
  wavelength = [0.22500001, 0.60000002, 1.3000001,  2.5000000,  5.0999999,  11.250000,  18.950001,  $
    25.700001,30.500000,  43.000000,  59.500000,  72.400002,  72.400002,  85.550003,85.550003,85.550003, $
    94.400002,94.400002, 94.400002,98.099998,100.70000,103.85000, 113.00000]

  ;make the year directory for saving 
  dir = expand_path('$fism_results') + '/daily_bands/' + yrst
  FILE_MKDIR, dir
  
  ;create save file 
  
  
  ;create a netcdf file 
  if keyword_set(ncdf) then begin 
    ;name of the file being created
    dir = expand_path('$fism_results') + '/daily_bands/netcdf/' + yrst
    FILE_MKDIR, dir
    ncdf_file = NCDF_CREATE(expand_path('$fism_results') + '/daily_bands/netcdf/' + yrst + '/FISM_bands_' + strmid(tmp_yd, 5, 7) + '_v' + version + '.nc', /CLOBBER, /NETCDF4_FORMAT)
  
    NCDF_CONTROL, ncdf_file, /FILL
    
    ;create dimensions 
    wvid = NCDF_DIMDEF(ncdf_file, 'wavelength', 23)
    timeid = NCDF_DIMDEF(ncdf_file, 'date', 1)
    
    ; create variables
    bwid = NCDF_VARDEF(ncdf_file, 'band_width', [wvid], gzip=4, /FLOAT)
    did = NCDF_VARDEF(ncdf_file, 'date', [timeid], gzip=4, /string)
    ssiid = NCDF_VARDEF(ncdf_file, 'ssi', [wvid], gzip=4, /DOUBLE)
    wvid = NCDF_VARDEF(ncdf_file, 'wavelength', [wvid], gzip=4, /FLOAT)
    
    ;create global and variable attributes
    NCDF_ATTPUT, ncdf_file, /GLOBAL, 'title', 'FISM2 is an empirical model of the Solar Spectral Irradiance, here covering the range from 0.01-121 nm binned to the 23 "Stan Bands" spectral bins commonly used in atmospheric models. This is the daily average product with one spectrum for each day.'
    NCDF_ATTPUT, ncdf_file, /GLOBAL, 'product_version', '2.0'
    
    NCDF_ATTPUT, ncdf_file, bwid, 'units', 'nm', /CHAR
    NCDF_ATTPUT, ncdf_file, bwid, 'long_name', 'Width of band', /CHAR
    
    NCDF_ATTPUT, ncdf_file, did, 'units', 'YYYYDDD', /CHAR
    NCDF_ATTPUT, ncdf_file, did, 'long_name', 'Year - Day of year', /CHAR
    
    NCDF_ATTPUT, ncdf_file, ssiid, 'units', 'photons/cm^2/s', /CHAR
    NCDF_ATTPUT, ncdf_file, ssiid, 'long_name', 'Solar Spectral Irradiance', /CHAR
    
    NCDF_ATTPUT, ncdf_file, wvid, 'units', 'nm', /CHAR
    NCDF_ATTPUT, ncdf_file, wvid, 'long_name', 'Median wavelegth of band', /CHAR
    
    NCDF_CONTROL, ncdf_file, /ENDEF
    ; put data into variables 
    NCDF_VARPUT, ncdf_file, bwid, band_width
    NCDF_VARPUT, ncdf_file, did, date
    NCDF_VARPUT, ncdf_file, ssiid, ssi
    NCDF_VARPUT, ncdf_file, wvid, wavelength
  
    NCDF_CLOSE, ncdf_file
  endif else begin
    ;default -> create a sav file
      svfile = expand_path('$fism_results') + '/daily_bands/' + yrst + '/FISM_bands_' + strmid(tmp_yd, 5, 7) + '_v' + version + '.sav'
      save, band_width, date, date_sec,ssi, wavelength, file=svfile, /compress
    
  endelse
  
  tmp_yd = get_next_yyyydoy(tmp_yd)
endwhile
print, 'End time fism_daily_stan_bands: ', !stime
end
