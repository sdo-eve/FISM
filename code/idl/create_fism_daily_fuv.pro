; Need to run 'concat_fism_daily_fuv.pro' first
;
; NAME: create_fism_daily_fuv
;
; PURPOSE: Generate a non hr version of the fuv portion of the spectrum for use in the FISM
;   daily combined files
;
; HISTORY:
;       VERSION 2_01
;
;
;
pro create_fism_daily_fuv, styr=styr, doy=doy, edyr=edyr, eddoy=eddoy, $
       debug=debug, st_wv=st_wv, end_wv=end_wv, binsize=binsize, update=update

if not keyword_set(styr) then styr=1947;2017
if not keyword_set(doy) then doy=045;249
if not keyword_set(st_wv) then st_wv=115.05
if not keyword_set(end_wv) then end_wv=189.95
if not keyword_set(binsize) then binsize=0.1 ; 0.1 nm bins
restore, expand_path('$fism_save') + '/fism_version_file.sav'

ydoy=styr*fix(1000,type=3)+doy

start_yd=strtrim(ydoy,2)

tdy=fix(get_current_yyyydoy(),type=3)
if keyword_set(update) then begin
   ;tdy=long(strmid(get_current_yyyydoy(), 7,8))
   end_yd=fix(get_prev_yyyydoy(tdy,1),type=3)
   start_yd=fix(get_prev_yyyydoy(tdy,90),type=3) ; run for the past 60 days
   ydoy=get_prev_yyyydoy(tdy,90) ; run for the past 60 days
endif
if keyword_set(edyr) and keyword_set(eddoy) and not keyword_set(update) then  end_yd = edyr*fix(1000,type=3)+eddoy
if not keyword_set(edyr) and not keyword_set(update) then end_yd=fix(get_prev_yyyydoy(tdy,90),type=3)

;if not keyword_set(edyr) or not keyword_set(eddoy) then begin
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
;endif else begin
;  end_yd = edyr*fix(1000,type=3)+eddoy
;endelse
tmp_yd = start_yd; fix(styd, type=3)
print, end_yd, 'create_fuv'
while tmp_yd le end_yd do begin
  yrst=strmid(tmp_yd,5,4)  
  ; Restore 0.03 nm files from 'concat_fism_daily_fuv.pro'
  file='$fism_results/daily_data/fuv_daily_hr/'+yrst+'/FISM_daily_'+strmid(tmp_yd,5,7)+'_fuv_' + version + '_hr.sav'
  restore, file
  
  nwvs=fix((end_wv-st_wv)/binsize)+2
  
  ntimes=n_elements(utc)
  fism_pred_fuv=fltarr(nwvs,ntimes)
  fism_err_fuv=fltarr(nwvs,ntimes)
  fism_wv_fuv=fltarr(nwvs)*binsize+st_wv
  
  for i=0,nwvs-1 do begin         ; 0.1nm bins
     fism_wv_fuv[i]=st_wv+(i*binsize)
     wwv_fism_hr=where(fism_wv ge fism_wv_fuv[i]-binsize/2. and fism_wv lt fism_wv_fuv[i]+binsize/2.)
  
     if keyword_set(debug) then print, fism_wv_fuv[i]
  
     for j=0,ntimes-1 do begin
        fism_pred_fuv[i,j]=mean(fism_pred[wwv_fism_hr])
        fism_err_fuv[i,j]=mean(fism_error[wwv_fism_hr])
     endfor
     
  endfor
 FILE_MKDIR, '$fism_results/daily_data/fuv_daily/'+yrst
  save, fism_pred_fuv, fism_wv_fuv, fism_err_fuv, yrst, doy, file='$fism_results/daily_data/fuv_daily/'+yrst+'/FISM_daily_'+strmid(tmp_yd,5,7)+'_fuv_'+version+'.sav'
  tmp_yd = get_next_yyyydoy(tmp_yd)
endwhile
if keyword_set(debug) then stop

end
