;
; NAME: combine_fism_flare_v2
;
; PURPOSE: combine results for fuv, euv, and xuv into a single save file for flare data
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
pro combine_fism_flare_v2, stydoy=stydoy, edydoy=edydoy, update=update, ncdf=ncdf

print, 'Running combine_fism_flare_v2 ...', !stime
if not keyword_set(stydoy) then stydoy=2003001; 1982002;2017249
if keyword_set(update) then begin
  tdy=long(strmid(get_current_yyyydoy(), 7,8))
  stydoy=get_prev_yyyydoy(tdy,90) ; run for the past 60 days
endif

styd=strtrim(stydoy,2)
styr=strmid(styd,0,4)
dir = expand_path('$fism_results') + '/flare_hr_data'

restore, expand_path('$fism_save') + '/fism_version_file.sav'
FILE_MKDIR, string(dir)

if not keyword_set(edydoy) then begin
  ;get the current day and subtract 5 for sorce data
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
if keyword_set(edydoy) then end_yd = fix(edydoy, type=3)
; this is due to the comp fism flare only being able to update for a day in the past
end_yd = get_prev_yyyydoy(end_yd, 2)
while tmp_yd lt end_yd do begin 
  styd=strmid(tmp_yd,5,7)
  styr=strmid(tmp_yd,5,4)
  ydoy=fix(strmid(tmp_yd, 5, 7), type=3)
  ; setup fism final structure
  fism_pred_all=fltarr(1900,1440)     ; 0.05-189.95 nm, 0.1nm bins, 1 minute
  fism_error_all=fltarr(1900,1440)     ; 0.05-189.95 nm, 0.1nm bins, 1 minute
  fism_wv_all=findgen(1900,increment=0.1,start=0.05);/10.+0.05
  
 
  ; Populate FUV from create_fism_fuv.pro
    restore, '$fism_results/flare_data/fuv_flare/' + styr + '/fism_fuv_'+styd+'.sav'
    if ydoy eq 2017253 then begin ; remove ip for over the limb event
       fism_pred_all[1150:1899,*]=fism_pred_fuv-fism_ip_fuv 
    endif else begin
       fism_pred_all[1150:1899,*]=fism_pred_fuv
    endelse
    fism_error_all[1150:1899,*]=fism_sigma_fuv
 
  test = file_test('$fism_results/flare_data/euv/'+styr+'/FISM_60sec_'+styd+'_'+version+'.sav')
  if test eq 1 then begin
  ; Populate EUV from comp_fism_flare.pro
    restore, '$fism_results/flare_data/euv/'+styr+'/FISM_60sec_'+styd+'_'+version+'.sav'
    if ydoy eq 2017253 or ydoy eq 2017254 then begin ; remove ip for over the limb event
       fism_pred_all[60:1059,*]=transpose(fism_pred);-imp_flare)
    endif else begin
       fism_pred_all[60:1059,*]=transpose(fism_pred)
    endelse
    fism_error_all[60:1059,*]=transpose(fism_error)
  endif else begin
    fism_pred_all[60:1059,*]=0
  endelse
  ; Populate XUV from create_fism_hr_xuv.pro
  restore, '$fism_results/flare_data/xuv_flare/' + styr + '/fism_xuv_'+styd+'_hr.sav'
  fism_pred_all[0:59,*]=fism_pred_xuv_hr[0:59,*]
  fism_error_all[0:59,*]=fism_sigma_xuv_hr[0:59,*]
  
  ; Interpolate over 106-115 to fill gap between MEGS-B and SOLSTICE
  st_int_pre=1047
  end_int_pre=1055
  st_int_post=1150
  end_int_post=1165
  wv_pre_post=[fism_wv_all[st_int_pre:end_int_pre],fism_wv_all[st_int_post:end_int_post]]
  wv_interp=fism_wv_all[end_int_pre+1:st_int_post-1]
  for i=0,1439 do begin ; time loop
     int_irr=[smooth(fism_pred_all[st_int_pre:end_int_pre,i],3),smooth(fism_pred_all[st_int_post:end_int_post,i],3)]
     fism_pred_all[end_int_pre+1:st_int_post-1,i]=interpol(int_irr,wv_pre_post,wv_interp)
  endfor
  
  
  fism_pred=fism_pred_all
  fism_wv=fism_wv_all
  fism_error=fism_error_all
  ;print, 'Saving for: ' + string(tmp_yd)
  ; make directory for folder these are put on 
  irradiance = fism_pred
  wavelength = fism_wv
  uncertainty = fism_error

  ; compute Julian date for each sample
  jd = yd2jd(ydoy) + (utc_fuv / 86400d)
  
  if keyword_set(ncdf) then begin
    dir = expand_path('$fism_results') + '/flare_hr_data/netcdf/' + strmid(tmp_yd,5,4)
    FILE_MKDIR, dir
    ;name of the file being created
    ncdf_file = NCDF_CREATE(expand_path('$fism_results') + '/flare_hr_data/netcdf/' + strmid(tmp_yd,5,4) + '/FISM_60sec_' + strmid(tmp_yd, 5, 7) + '_v' + version + '.nc', /CLOBBER, /NETCDF4_FORMAT)

    NCDF_CONTROL, ncdf_file, /FILL
    
    ;create dimensions
    wvid = NCDF_DIMDEF(ncdf_file, 'wavelength', 1900)
    utcid = NCDF_DIMDEF(ncdf_file, 'utc', 1440)
    timeid = NCDF_DIMDEF(ncdf_file, 'date', 1)
    jddid = NCDF_DIMDEF(ncdf_file, 'jd', 1440)
    
    ; create variables
    predid = NCDF_VARDEF(ncdf_file, 'irradiance', [wvid, utcid], gzip=4, /FLOAT)
    errid = NCDF_VARDEF(ncdf_file, 'uncertainty', [wvid, utcid],  gzip=4, /float)
    wavid = NCDF_VARDEF(ncdf_file, 'wavelength', [wvid], gzip=4, /float)
    utcid = NCDF_VARDEF(ncdf_file, 'utc', [utcid], gzip=4, /long)
    doyid = NCDF_VARDEF(ncdf_file, 'date', [timeid], gzip=4, /string)
    jdvid = NCDF_VARDEF(ncdf_file, 'jd', [jddid], gzip=4, /DOUBLE)
    
    ;create global and variable attributes
    NCDF_ATTPUT, ncdf_file, /GLOBAL, 'title', 'FISM2 is an empirical model of the Solar Spectral Irradiance from 0.01-190nm at 0.1 nm spectral bins. This is the flare product with one spectrum every 60 seconds.'
    NCDF_ATTPUT, ncdf_file, /GLOBAL, 'product_version', '2.0'
    
    NCDF_ATTPUT, ncdf_file, predid, 'units', 'W/m^2/nm', /CHAR
    NCDF_ATTPUT, ncdf_file, predid, 'long_name', 'FISM Prediction', /CHAR
    
    NCDF_ATTPUT, ncdf_file, wavid, 'units', 'nm', /CHAR
    NCDF_ATTPUT, ncdf_file, wavid, 'long_name', 'FISM Wavelength', /CHAR
    
    NCDF_ATTPUT, ncdf_file, utcid, 'units', 'Seconds after 00:00', /CHAR
    NCDF_ATTPUT, ncdf_file, utcid, 'long_name', 'Coordinated Universal Time', /CHAR
    
    NCDF_ATTPUT, ncdf_file, doyid, 'units', 'YYYYDDD', /CHAR
    NCDF_ATTPUT, ncdf_file, doyid, 'long_name', 'Year - Day of year', /CHAR
    
    NCDF_ATTPUT, ncdf_file, errid, 'units', '', /CHAR
    NCDF_ATTPUT, ncdf_file, errid, 'long_name', 'FISM Error', /CHAR

    NCDF_ATTPUT, ncdf_file, jdvid, 'units', 'Julian date', /CHAR
    NCDF_ATTPUT, ncdf_file, jdvid, 'long_name', 'Julian date', /CHAR

    NCDF_CONTROL, ncdf_file, /ENDEF
    ; put data into variables
    NCDF_VARPUT, ncdf_file, predid, irradiance
    NCDF_VARPUT, ncdf_file, wavid, wavelength
    NCDF_VARPUT, ncdf_file, utcid, utc_fuv
    NCDF_VARPUT, ncdf_file, doyid, ydoy
    NCDF_VARPUT, ncdf_file, errid, uncertainty
    NCDF_VARPUT, ncdf_file, jdvid, jd

    NCDF_CLOSE, ncdf_file
  endif else begin
    FILE_MKDIR, '$fism_results/flare_hr_data/' + strmid(tmp_yd,5,4)
  utc = utc_fuv
  save, irradiance, wavelength, uncertainty, ydoy, utc, jd, file='$fism_results/flare_hr_data/' + strmid(tmp_yd,5,4) + '/FISM_60sec_'+strmid(tmp_yd,5,7)+'_v' + version +'.sav', /compress
  
    
  endelse
  tmp_yd = get_next_yyyydoy(tmp_yd)
endwhile

print, 'End time combine_fism_flare_v2: ', !stime
end
