;+
; :Author: alpa3266
; 
; Name: create_merged_netcdf 
; 
; Purpose: To create merged Netcdf files for FISM V02 in order for LaTiS to run 
; with LISIRD properly/more efficiently 
; 
; Note: This must be called from a place with knowledge of where FISM data is located
;   as it must restore the sav files. It is also set up to run for all the files at
;   once instead of seperately.
; 
; Keywords:
;   update: This keyword is for updating the file. It will determine the last data file 
;     added to the NetCDF file and then add all new ones. In the event that one of the 
;     files does not exist, it will create this file and fill it up to the end date for
;     the update according to dataset
;   
;-

;helper function for finding NetCDF offsets for inserting data along the unlimited dimension
;Taken from processing of NRLSSI2 
function find_offset, f, dim
  compile_opt idl2
  did = ncdf_dimid(f, dim) ;get dimension id
  ncdf_diminq, f, did, name, offset
  return, offset
end

pro create_merged_netcdf, update=update, daily=daily, dbands=dbands
print, 'Start time create_merged_netcdf ', !stime
;variables to control start and end dates of each set
lastdy_d = 1947045    ; daily average
lastdy_db = 1947045   ; daily bands
enddy_d = long(strmid(get_prev_yyyydoy(get_current_yyyydoy(), 1), 7,8))
;checks for the existance of each merged file, will change to 1 if file exists
checkd = 0
checkdb = 0

;find the last day added to the file for each file if the file exists for reference in 
;adding new days during a file update
if keyword_set(update) then begin
  ;find the last day that was added to the file in order to make sure no days are
  ;missed or duplicated
  doyArr = []
  ;daily average
  ;only get the last added day if the file already exists
  if file_test(expand_path('$fism_results') + '/daily_hr_data/daily_data.nc') then begin
    f = ncdf_open(expand_path('$fism_results') + '/daily_hr_data/daily_data.nc')
    doy = NCDF_VARID(f, 'date') ; get the variable ID for the date
    NCDF_VARGET, f, doy, doyArr ; get the data from the variable
    lastdy_d = fix(doyArr[size(doyArr, /N_ELEMENTS) -1], type=3) ; get last value in array
    lastdy_d = get_prev_yyyydoy(lastdy_d, 90)
    checkd = 1 ; mark file as existing
    NCDF_CLOSE, f ; close the NetCDF file to avoid errors 
  endif
  ;daily bands
  if file_test(expand_path('$fism_results') + '/daily_bands/daily_bands.nc') then begin
    f = ncdf_open(expand_path('$fism_results') + '/daily_bands/daily_bands.nc')
    doy = NCDF_VARID(f, 'date')
    NCDF_VARGET, f, doy, doyArr
    lastdy_db = fix(doyArr[size(doyArr, /N_ELEMENTS) -1], type=3)
    lastdy_db = get_prev_yyyydoy(lastdy_db, 90)
    checkdb = 1
    NCDF_CLOSE, f
  endif
endif
if keyword_set(daily) then goto, daily
if keyword_set(dbands) then goto, dbands

;========================
;=======================================================
;Daily Data
;=======================================================
;========================
daily:
stydoy = lastdy_d ;set the start day to the start day specific to daily data
edydoy = enddy_d ; set the end day fspecific to daily data
print, 'Creating merged file for daily data'
;if the file doesnt exist or not updating, initialize the file using the first data
if (keyword_set(update) eq 0) || (checkd eq 0) then begin
  restore, expand_path('$fism_results') + '/daily_hr_data/1947/FISM_daily_1947045_v02_01.sav'
  ncdf_file = NCDF_CREATE(expand_path('$fism_results') + '/daily_hr_data/daily_data.nc', /CLOBBER, /NETCDF4_FORMAT)
  NCDF_CONTROL, ncdf_file, /FILL
  
  ;create dimensions
  wvid = NCDF_DIMDEF(ncdf_file, 'wavelength', 1900) ;1899
  timeid = NCDF_DIMDEF(ncdf_file, 'date', /UNLIMITED)
  
  ; create variables
  ; For merged file, fism_pred gives one spectrum per day, therefore is wavelength and time
  predid = NCDF_VARDEF(ncdf_file, 'irradiance', [wvid, timeid],  /FLOAT, chunk_dimensions=[1900, 1], gzip=2)
  ; wavelength coordinate variable for defining wavelength values
  wavid = NCDF_VARDEF(ncdf_file, 'wavelength', [wvid],  /float)
  errid = NCDF_VARDEF(ncdf_file, 'uncertainty', [wvid, timeid],  /float, chunk_dimensions=[1900, 1], gzip=2)
  doyid = NCDF_VARDEF(ncdf_file, 'date', [timeid],  /STRING)
  
  ;define attributes for the file for global and variables
  NCDF_ATTPUT, ncdf_file, /GLOBAL, 'title', 'FISM2 is an empirical model of the Solar Spectral Irradiance from 0.01-190nm at 0.1 nm spectral bins. This is the daily average product with one spectrum for each day.'
  NCDF_ATTPUT, ncdf_file, /GLOBAL, 'product_version', '2.0'
  
  NCDF_ATTPUT, ncdf_file, predid, 'units', 'W/m^2/nm', /CHAR
  NCDF_ATTPUT, ncdf_file, predid, 'long_name', 'FISM Prediction', /CHAR
  
  NCDF_ATTPUT, ncdf_file, wavid, 'units', 'nm', /CHAR
  NCDF_ATTPUT, ncdf_file, wavid, 'long_name', 'FISM Wavelength', /CHAR
  
  NCDF_ATTPUT, ncdf_file, errid, 'units', '', /CHAR
  NCDF_ATTPUT, ncdf_file, errid, 'long_name', 'FISM Error', /CHAR
  
  NCDF_ATTPUT, ncdf_file, doyid, 'units', 'YYYYDDD', /CHAR
  NCDF_ATTPUT, ncdf_file, doyid, 'long_name', 'Year - Day of year', /CHAR
  
  ;strydoy = strmid(ydoy, 5, 7) ; save the ydoy in correct format
  NCDF_CONTROL, ncdf_file, /ENDEF
  ; put data into variables
  NCDF_VARPUT, ncdf_file, predid, irradiance
  NCDF_VARPUT, ncdf_file, wavid, wavelength
  NCDF_VARPUT, ncdf_file, errid, uncertainty
  NCDF_VARPUT, ncdf_file, doyid, ydoy
  NCDF_CLOSE, ncdf_file
endif
tmpyd = get_next_yyyydoy(stydoy)
;add each new day onto the file
while tmpyd ne edydoy do begin
  ;print, tmpyd, ' ', edydoy
  numdys = yd_to_jd(edydoy) - yd_to_jd(tmpyd) 
  ;open the netcdf file
  f = ncdf_open(expand_path('$fism_results') + '/daily_hr_data/daily_data.nc', /write)
  ;date pieces for opening file
  ydoy = strmid(tmpyd, 5, 7)
  yr = strmid(ydoy, 0, 4)
  ;open idl sav file of data
  restore, '$fism_results/daily_hr_data/' + yr + '/FISM_daily_'+ydoy+'_v02_01.sav'
  ;get the offset for how many 'spaces' to place new variable after
  offset = find_offset(f, 'date')
  strydoy = strmid(tmpyd, 5, 7)
  ;add the next set of data at the location along the record dimension at the offset
  if keyword_set(update) then begin
    ; if this is updating, data needs to be placed in the file for the offset - 60 days first and up until 0
   ncdf_varput, f, 'irradiance', irradiance, offset=[0, offset - numdys]
    ncdf_varput, f, 'uncertainty', uncertainty, offset=[0, offset - numdys]
    ncdf_varput, f, 'date', strydoy, offset=offset- numdys
  endif else begin
    ncdf_varput, f, 'irradiance', irradiance, offset=[0, offset]
    ncdf_varput, f, 'uncertainty', uncertainty, offset=[0, offset]
    ncdf_varput, f, 'date', strydoy, offset=offset
  endelse
  
  ncdf_close, f
  tmpyd = get_next_yyyydoy(tmpyd)
endwhile
if keyword_set(daily) then goto, finish
dbands:
;========================
;=======================================================
;Daily Bands
;=======================================================
;========================
stydoy = lastdy_db
edydoy = enddy_d
print, 'Creating merged file for daily bands data'
if (keyword_set(update) eq 0) || (checkdb eq 0) then begin
  restore, expand_path('$fism_results') + '/daily_bands/1947/FISM_bands_1947045_v02_01.sav'
  ncdf_file = NCDF_CREATE(expand_path('$fism_results') + '/daily_bands/daily_bands.nc', /CLOBBER, /NETCDF4_FORMAT)
  date = strmid(date, 5, 7)
  NCDF_CONTROL, ncdf_file, /FILL
  
  ;create dimensions
  wvid = NCDF_DIMDEF(ncdf_file, 'wavelength', 23)
  timeid = NCDF_DIMDEF(ncdf_file, 'date', /UNLIMITED)
  
  ; create variables
  bwid = NCDF_VARDEF(ncdf_file, 'band_width', [wvid],  /FLOAT)
  did = NCDF_VARDEF(ncdf_file, 'date', [timeid],  /string)
  ssiid = NCDF_VARDEF(ncdf_file, 'ssi', [wvid, timeid],  /DOUBLE)
  wvid = NCDF_VARDEF(ncdf_file, 'wavelength', [wvid],  /FLOAT)
  
  ;set global and variable attributes
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
  date = '1947045'
  ; put data into variables 
  NCDF_VARPUT, ncdf_file, bwid, band_width
  NCDF_VARPUT, ncdf_file, did, date
  NCDF_VARPUT, ncdf_file, ssiid, ssi
  NCDF_VARPUT, ncdf_file, wvid, wavelength
  
  NCDF_CLOSE, ncdf_file
endif
tmpyd = get_next_yyyydoy(stydoy)

while tmpyd ne edydoy do begin
  ;print, tmpyd, ' ', edydoy
  numdys = yd_to_jd(edydoy) - yd_to_jd(tmpyd) 
  f = ncdf_open(expand_path('$fism_results') + '/daily_bands/daily_bands.nc', /write)
  ydoy = strmid(tmpyd, 5, 7)
  yr = strmid(ydoy, 0, 4)
  doy = strmid(ydoy, 4, 3)
  restore, '$fism_results/daily_bands/' + yr + '/FISM_bands_'+ydoy+'_v02_01.sav'
  offset = find_offset(f, 'date')
  date = string(date)
  if keyword_set(update) then begin
    ncdf_varput, f, 'date', date, offset=offset - numdys
    ncdf_varput, f, 'ssi', ssi, offset=[0,offset - numdys]
  endif else begin
    ncdf_varput, f, 'date', date, offset=offset
    ncdf_varput, f, 'ssi', ssi, offset=[0,offset]
  endelse
  ncdf_close, f
  tmpyd = get_next_yyyydoy(tmpyd)
  ;stop
endwhile
if keyword_set(dbands) then goto, finish
finish:
print, 'End time create_merged_netcdf ', !stime
end
