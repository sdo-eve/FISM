;
; NAME: combine_fism_daily_v2
;
; PURPOSE: combine results from fuv, euv, and xuv into a single save file for daily data
;
; HISTORY:
;       VERSION 2_01
;
; Inputs:
;   stydoy - Starting ydoy for the file to run from, if this is not set it will begin 
;     running at 1947045
;   eddoy - Ending day for the file to run to, if this isnt set then it will run until 5 
;     days in the past
;   update - This keyword will automatically run the file for the past 60 days 
;   ncdf - If this keyword is set then the output file will be in NetCDF form, if this is
;     not set then a .sav file will be produced instead
;
pro combine_fism_daily_v2, stydoy=stydoy, eddoy=eddoy, update=update, ncdf=ncdf

print, 'Running combine_fism_daily_v2 ... ', !stime
restore, expand_path('$fism_save') + '/fism_version_file.sav'
if not keyword_set(stydoy) then stydoy=1947045; 2017249
tdy=fix(get_current_yyyydoy(),type=3)
if keyword_set(update) then begin
  ;tdy=long(strmid(get_current_yyyydoy(), 7,8))
  end_yd=fix(get_prev_yyyydoy(tdy,1),type=3)
  stydoy=fix(get_prev_yyyydoy(tdy,90),type=3) ; run for the past 90 days
endif
styd=strtrim(stydoy,2)
styr=strmid(styd,0,4)
dir = expand_path('$fism_results') + '/daily_hr_data'
FILE_MKDIR, string(dir)
if keyword_set(eddoy) and not keyword_set(update) then end_yd = eddoy else end_yd=fix(get_prev_yyyydoy(tdy,1),type=3)

;if not keyword_set(eddoy) then begin
;  ;get the current day and subtract 5 for sorce data
;  curr_doy = fix(get_current_yyyydoy(), type=3)
;  cur_d = fix(strmid(curr_doy, 9,3), type=2)
;  end_y = fix(strmid(curr_doy, 5,4), type=2)
;  this_y = fix(strmid(curr_doy, 3,4), type=3)
;  end_d = cur_d -5
;  ; if its the beginning of the year -> go back to last yeat
;  if cur_d lt 5 then begin
;    end_y = this_y -1
;    ; check if last year was a leap year
;    if leap_year(end_y) gt 0 then begin
;      case cur_d of
;        1: end_d = 362
;        2: end_d = 363
;        3: end_d = 364
;        4: end_d = 365
;        5: end_d = 366
;        else: end_d = 365
;      endcase
;    endif else begin
;      case cur_d of
;        1: end_d = 361
;        2: end_d = 362
;        3: end_d = 363
;        4: end_d = 364
;        5: end_d = 365
;        else: end_d = 365
;      endcase
;    endelse
;  endif
;  end_yd = end_y*fix(1000,type=3)+end_d
;endif
tmp_yd = fix(styd, type=3)

while tmp_yd le end_yd do begin
  ydoy=strmid(tmp_yd, 5, 7)
  styd = strmid(strtrim(tmp_yd,2), 0, 7)
  styr=strmid(styd,0,4)
  ; setup fism final structure
  fism_pred_all=fltarr(1900)     ; 0.05-189.95 nm, 0.1nm bins, daily average
  fism_wv_all=findgen(1900,increment=0.1d0,start=0.05d0);/10.+0.05
  fism_err_all=findgen(1900)
  
  ; Populate FUV from create_fism_daily_fuv.pro
  restore, '$fism_results/daily_data/fuv_daily/' + styr + '/FISM_daily_'+styd+'_fuv_' + version + '.sav'
  ;restore, '$fism_results/daily_data/fuv_daily/' + styr + '/FISM_daily_'+styd+'_fuv_02_01.sav'
  fism_pred_all[1150:1899]=fism_pred_fuv 
  fism_err_all[1150:1899]=fism_err_fuv
  
  ; Populate EUV from comp_fism_flare.pro
  restore, '$fism_results/daily_data/euv/'+styr+'/FISM_daily_'+styd+'_'+version+'.sav'
  ;restore, '$fism_results/daily_data/euv/'+styr+'/FISM_daily_'+styd+'_02_01.sav'
  fism_pred_all[60:1059]=fism_pred
  fism_err_all[60:1059]=fism_error
  
  ; Populate XUV from create_fism_hr_xuv.pro
  restore, '$fism_results/daily_data/xuv_daily/'+styr+'/FISM_daily_'+styd+'_xuv_' + version +'.sav'
  fism_pred_all[0:59]=fism_pred[0:59]
  fism_err_all[0:59]=fism_error[0:59]
  
  ; Interpolate over 106-115 to fill gap between MEGS-B and SOLSTICE
  st_int_pre=1047
  end_int_pre=1055
  st_int_post=1150
  end_int_post=1165
  wv_pre_post=[fism_wv_all[st_int_pre:end_int_pre],fism_wv_all[st_int_post:end_int_post]]
  wv_interp=fism_wv_all[end_int_pre+1:st_int_post-1]
  int_irr=[smooth(fism_pred_all[st_int_pre:end_int_pre],3),smooth(fism_pred_all[st_int_post:end_int_post],3)]
  fism_pred_all[end_int_pre+1:st_int_post-1]=interpol(int_irr,wv_pre_post,wv_interp)
  
  fism_pred=fism_pred_all
  fism_wv=fism_wv_all
  ;print, fism_err_all
  ;print, 'Saving for: ' + string(tmp_yd)
  FILE_MKDIR, '$fism_results/daily_hr_data/' + strmid(tmp_yd,5,4)
  
  irradiance = fism_pred
  wavelength = fism_wv
  uncertainty = fism_err_all
  
  if keyword_set(ncdf) then begin
    dir = expand_path('$fism_results') + '/daily_hr_data/netcdf/' + strmid(tmp_yd,5,4)
    FILE_MKDIR, dir
    ;name of the file being created
    ncdf_file = NCDF_CREATE(expand_path('$fism_results') + '/daily_hr_data/netcdf/' + strmid(tmp_yd,5,4) + '/FISM_daily_' + strmid(tmp_yd, 5, 7) + '_v' + version + '.nc', /CLOBBER, /NETCDF4_FORMAT)

    NCDF_CONTROL, ncdf_file, /FILL
    
    ;create dimensions
    wvid = NCDF_DIMDEF(ncdf_file, 'wavelength', 1900) ;1899
    timeid = NCDF_DIMDEF(ncdf_file, 'date', 1)
    
    ; create variables
    predid = NCDF_VARDEF(ncdf_file, 'irradiance', [wvid], gzip=4, /FLOAT)
    wavid = NCDF_VARDEF(ncdf_file, 'wavelength', [wvid], gzip=4, /float)
    errid = NCDF_VARDEF(ncdf_file, 'uncertainty', [wvid], gzip=4, /float)
    doyid = NCDF_VARDEF(ncdf_file, 'date', [timeid], gzip=4, /string)
    
    ;create global and variable dimensions
    NCDF_ATTPUT, ncdf_file, /GLOBAL, 'title', 'FISM2 is an empirical model of the Solar Spectral Irradiance from 0.01-190nm at 0.1 nm spectral bins. This is the daily average product with one spectrum for each day.'
    NCDF_ATTPUT, ncdf_file, /GLOBAL, 'product_version', '2.0'
    
    NCDF_ATTPUT, ncdf_file, predid, 'units', 'W/m^2/nm', /CHAR
    NCDF_ATTPUT, ncdf_file, predid, 'long_name', 'FISM Prediction', /CHAR
    
    NCDF_ATTPUT, ncdf_file, wavid, 'units', 'nm', /CHAR
    NCDF_ATTPUT, ncdf_file, wavid, 'long_name', 'FISM Wavelength', /CHAR
    ;NCDF_ATTPUT, ncdf_file, wavid, 'FORTRAN_format', '(F20.3)'
    
    NCDF_ATTPUT, ncdf_file, errid, 'units', '', /CHAR
    NCDF_ATTPUT, ncdf_file, errid, 'long_name', 'FISM Error', /CHAR
    
    NCDF_ATTPUT, ncdf_file, doyid, 'units', 'YYYYDDD', /CHAR
    NCDF_ATTPUT, ncdf_file, doyid, 'long_name', 'Year - Day of year', /CHAR
     
    NCDF_CONTROL, ncdf_file, /ENDEF
    ; put data into variables
    NCDF_VARPUT, ncdf_file, predid, irradiance
    NCDF_VARPUT, ncdf_file, wavid, fism_wv_all ; wavelength
    NCDF_VARPUT, ncdf_file, errid, uncertainty
    NCDF_VARPUT, ncdf_file, doyid, ydoy
    NCDF_CLOSE, ncdf_file
  endif else begin 
    ; Make sure file path exists
    subDir = expand_path('$fism_results') + '/daily_hr_data/' + strmid(tmp_yd,5,4)
    FILE_MKDIR, subDir
    save, irradiance, wavelength, uncertainty, ydoy, file='$fism_results/daily_hr_data/' + strmid(tmp_yd,5,4) + '/FISM_daily_'+strmid(tmp_yd,5,7)+'_v'+version+'.sav', /compress
  endelse
  tmp_yd = get_next_yyyydoy(tmp_yd)
endwhile
print, 'End time combine_fism_daily_v2: ', !stime
end
