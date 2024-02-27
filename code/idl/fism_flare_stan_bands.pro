;+
; :Author: alpa3266
; 
; FILE: fism_flare_stan_bands
; 
; Purpose: Get the "stan bands" for the FISM flare data at a certain step cadence 
; 
; Inputs: (all optional - the file will run without them)
; 
; stdoy - The start yyyydoy to begin at, if no start day is given, it will be set to 2003001
;     Note: FISM Flare can be run back to 1982002, this file could also be run that far given 
;       that the FISM Flare files have been created for it
; eddoy - The end yyyydoy to stop execution after, if no end day is given, it will be 
;   set to 5 days previous to the current day, this 5 days is due to SORCE data being released 
;   5 days after the day it was collected
; update - If the update keyword is used, only the past 60 days will be updated (up to 5 days 
;   in the past)
; step - the number, in minutes, to step by when producing the file. Must be in X.000 format to be 
;   used correctly. 5 minute cadence is the default. Ex. 10 minute -> 10.000
; ncdf - keyword for having the result saved as a NetCDF file, if this is not set then the file 
;   will be saved as the default which is .sav
; 
; Example call:
; fism_flare_stan_bands, stdoy=2005048, eddoy=2005051, step=15.000, /ncdf
; 
; Information:
; Files that are produced will be in photons, these files can be either sav or NetCDF files, if the 
;   desired output is in watts, remove the /inverse keyword from line 113 in the stan_bands file.
;   
;   The stan bands produced by this file will be all stored in the same array for a given day 
;-


pro fism_flare_stan_bands, stdoy = stdoy, eddoy=eddoy, step=step, update=update, ncdf=ncdf

  print, 'Running fism_flare_stan_bands... ', !stime
  
  ;start day
  if not keyword_set(stdoy) then stdoy = 2003001
  
  ;cap the start day if update is used
  if keyword_set(update) then begin
    tdy=long(strmid(get_current_yyyydoy(), 7,8))
    stdoy=get_prev_yyyydoy(tdy,90) ; run for the past 60 days
  endif
  ;set default step to 5 minutes 
  if not keyword_set(step) then step=5.000
  
  styd=strtrim(stdoy,2)
  styr=strmid(styd,0,4)
  dir = expand_path('$fism_results') + '/flare_bands' ;make the save directory if it does not exist
  FILE_MKDIR, string(dir)
  restore, expand_path('$fism_save') + '/fism_version_file.sav' ; get the FISM version 
  
  if not keyword_set(eddoy) then begin
    ;get the current day and subtract 5 for sorce data -> sorce data is released approx 5 days late
    curr_doy = fix(get_current_yyyydoy(), type=3)
    cur_d = fix(strmid(curr_doy, 9,3), type=2)
    end_y = fix(strmid(curr_doy, 5,4), type=2)
    this_y = fix(strmid(curr_doy, 3,4), type=3)
    end_d = cur_d -5
    ; if its the beginning of the year -> go back to last yeat
    if cur_d lt 5 then begin
      end_y = this_y -1
      ; check if last year was a leap year
      if leap_year(end_y) gt 0 then begin
        case cur_d of
          1: end_d = 362
          2: end_d = 363
          3: end_d = 364
          4: end_d = 365
          5: end_d = 366
          else: end_d = 365
        endcase
      endif else begin
        case cur_d of
          1: end_d = 361
          2: end_d = 362
          3: end_d = 363
          4: end_d = 364
          5: end_d = 365
          else: end_d = 365
        endcase
      endelse
    endif
    end_yd = end_y*fix(1000,type=3)+end_d
  endif
  tmp_yd = fix(styd, type=3)
  if keyword_set(eddoy) then end_yd = fix(eddoy, type=3)
  end_yd = get_prev_yyyydoy(end_yd, 2)
  while tmp_yd lt end_yd do begin
    yrst=strmid(tmp_yd,5,4)
    
    ;set up information for the output file 
    date=strmid(tmp_yd, 5, 7)
    
    ;band_width holds the total width of each band 
    band_width= [0.350000,  0.400000, 1.00000,  1.40000,  3.80000,  8.50000,  6.90000,  6.60000,  3.00000, $
    22.0000,11.0000,14.8000,  14.8000,  11.5000,  11.5000,  11.5000,  6.20000,  6.20000,  6.20000,  $
    1.20000,  4.00000,  2.30000, 16.00000]
  
    ;restore the FISM flare data to take the irradiance from 
    file = '/FISM_60sec_' + strmid(tmp_yd, 5, 7) + '_v' + version + '.sav'
    restore, expand_path('$fism_results') + '/flare_hr_data/' + yrst + file
    
    ;temporarily store the data for the minute being looked at 
    ssitmp=fltarr(1, 23)
    date_sec=[] ;initialize 
    ;find the bands for each minute in the day given a step 
    for i=0.000, 1440.000-step, step do begin 
      ;set the temporary value to the stan bands produced 
      ssitmp = [ssitmp, transpose(stan_bands(irradiance[*,i-1],wavelength, /photons))]
      ;save the date seconds 
      date_sec = [date_sec, (i*60.000)]
    endfor 
    
    ; compute Julian date for each sample
    jd = yd2jd(double(date)) + (date_sec / 86400d)

    ;create the final array in the proper order 
    ssi = transpose(ssitmp[1:(1440/step), *])
    ;wavelength holds the median wavelength for each bin
    wavelength = [0.22500001, 0.60000002, 1.3000001,  2.5000000,  5.0999999,  11.250000,  18.950001,  $
      25.700001,30.500000,  43.000000,  59.500000,  72.400002,  72.400002,  85.550003,85.550003,85.550003, $
      94.400002,94.400002, 94.400002,98.099998,100.70000,103.85000, 113.00000]
    ;make the directory for the year to be saved if it is not there
    dir = expand_path('$fism_results') + '/flare_bands/' + yrst
    FILE_MKDIR, dir
    
    
    ;produce netcdf
    if keyword_set(ncdf) then begin 
      dir = expand_path('$fism_results') + '/flare_bands/netcdf/' + yrst
      FILE_MKDIR, dir
      ;name of file to be created
      ncdf_file = NCDF_CREATE(expand_path('$fism_results') + '/flare_bands/netcdf/' + yrst + '/FISM_bands_' + strmid(tmp_yd, 5, 7) + '_v' + version + '.nc', /CLOBBER, /NETCDF4_FORMAT)
  
      NCDF_CONTROL, ncdf_file, /FILL
      
      ;set dimensions 
      wvid = NCDF_DIMDEF(ncdf_file, 'wavelength', 23)
      cadenceid = NCDF_DIMDEF(ncdf_file, 'seconds', (1440/step))
      tid = NCDF_DIMDEF(ncdf_file, 'date', 1)
      jddid = NCDF_DIMDEF(ncdf_file, 'jd', (1440/step))
  
      ;set variables 
      bwid = NCDF_VARDEF(ncdf_file, 'band_width', [wvid], gzip=4, /FLOAT)
      did = NCDF_VARDEF(ncdf_file, 'date', [tid], gzip=4, /string)
      dsid = NCDF_VARDEF(ncdf_file, 'date_sec', [cadenceid], gzip=4, /FLOAT)
      jdvid = NCDF_VARDEF(ncdf_file, 'jd', [jddid], gzip=4, /DOUBLE)
      ssiid = NCDF_VARDEF(ncdf_file, 'ssi', [wvid, cadenceid], gzip=4, /DOUBLE)
      wvid = NCDF_VARDEF(ncdf_file, 'wavelength', [wvid], gzip=4, /FLOAT)
      
      ;set global and variable attributes
      NCDF_ATTPUT, ncdf_file, /GLOBAL, 'title', 'FISM2 is an empirical model of the Solar Spectral Irradiance, here covering the range from 0.01-121 nm binned to the 23 "Stan Bands" spectral bins commonly used in atmospheric models. This is the flare product with one spectrum every 60 seconds.'
      NCDF_ATTPUT, ncdf_file, /GLOBAL, 'product_version', '2.0'
      
      NCDF_ATTPUT, ncdf_file, bwid, 'units', 'nm', /CHAR
      NCDF_ATTPUT, ncdf_file, bwid, 'long_name', 'Width of band', /CHAR
      
      NCDF_ATTPUT, ncdf_file, did, 'units', 'YYYYDDD', /CHAR
      NCDF_ATTPUT, ncdf_file, did, 'long_name', 'Year - Day of year', /CHAR
      
      NCDF_ATTPUT, ncdf_file, dsid, 'units', 'seconds', /CHAR
      NCDF_ATTPUT, ncdf_file, dsid, 'long_name', 'Seconds after 00:00', /CHAR

      NCDF_ATTPUT, ncdf_file, jdvid, 'units', 'Julian date', /CHAR
      NCDF_ATTPUT, ncdf_file, jdvid, 'long_name', 'Julian date', /CHAR

      NCDF_ATTPUT, ncdf_file, ssiid, 'units', 'W/m^2/nm', /CHAR
      NCDF_ATTPUT, ncdf_file, ssiid, 'long_name', 'Solar Spectral Irradiance', /CHAR
      
      NCDF_ATTPUT, ncdf_file, wvid, 'units', 'nm', /CHAR
      NCDF_ATTPUT, ncdf_file, wvid, 'long_name', 'Median wavelegth of band', /CHAR


      NCDF_CONTROL, ncdf_file, /ENDEF
      ;put the data into the variables in the file 
      NCDF_VARPUT, ncdf_file, bwid, band_width
      NCDF_VARPUT, ncdf_file, did, date
      NCDF_VARPUT, ncdf_file, dsid, date_sec
      NCDF_VARPUT, ncdf_file, jdvid, jd
      NCDF_VARPUT, ncdf_file, ssiid, ssi
      NCDF_VARPUT, ncdf_file, wvid, wavelength
  
      NCDF_CLOSE, ncdf_file
    endif else begin
      ;produce save file

      svfile = expand_path('$fism_results') + '/flare_bands/' + yrst + '/FISM_bands_' + strmid(tmp_yd, 5, 7) + '_v' + version + '.sav'
      save, band_width, date, date_sec, jd, ssi, wavelength, file=svfile, /compress


    endelse
    tmp_yd = get_next_yyyydoy(tmp_yd)
  endwhile
  print, 'End time fism_flare_stan_bands: ', !stime
end
