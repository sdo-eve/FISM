; Need to run 'create_fism_fuv_hr.pro' first
;
; NAME: create_fism_fuv
;
; PURPOSE: 
;
; HISTORY:
;       VERSION 2_01
;
;
;
pro create_fism_fuv, styr=styr, doy=doy, edyr=edyr, eddoy=eddoy, $
       debug=debug, st_wv=st_wv, end_wv=end_wv, binsize=binsize, update= update
print, 'Running create_fism_fuv ', !stime

if not keyword_set(styr) then styr=2003;1982;2017
if not keyword_set(doy) then doy=001;002;249
if not keyword_set(st_wv) then st_wv=115.05
if not keyword_set(end_wv) then end_wv=189.95
if not keyword_set(binsize) then binsize=0.1 ; 0.1 nm bins


ydoy=styr*fix(1000,type=3)+doy
if keyword_set(update) then begin
  tdy=long(strmid(get_current_yyyydoy(), 7,8))
  ydoy=get_prev_yyyydoy(tdy,90) ; run for the past 60 days
endif
styd=strtrim(ydoy,2)
if not keyword_set(edyr) or not keyword_set(eddoy) then begin
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

if keyword_set(eddoy) then end_yd = fix((strmid(edyr, 4, 4) + strmid(eddoy, 5, 3)), type=3)
while tmp_yd lt end_yd do begin 
; Restore 0.03 nm files from 'create_fism_hr_fuv.pro'
  yrst=strmid(tmp_yd,5,4)  
  file='fism_fuv_'+strmid(tmp_yd, 5, 7)+'_hr.sav'
  restore, expand_path('$fism_results') + '/flare_data/fuv_flare_hr/' + yrst + '/'+ file
  nwvs=fix((end_wv-st_wv)/binsize) + 2
  ntimes=n_elements(utc_fuv)
  fism_daily_fuv=fltarr(nwvs,ntimes)
  fism_ip_fuv=fltarr(nwvs,ntimes)
  fism_gp_fuv=fltarr(nwvs,ntimes)
  fism_pred_fuv=fltarr(nwvs,ntimes)
  fism_sigma_fuv=fltarr(nwvs,ntimes)
  fism_wv_fuv=fltarr(nwvs)*binsize+st_wv
  
  for i=0,nwvs-1 do begin         ; 0.1nm bins
     fism_wv_fuv[i]=st_wv+(i*binsize)
     wwv_fism_hr=where(fism_wv_fuv_hr ge fism_wv_fuv[i]-binsize/2. and fism_wv_fuv_hr lt fism_wv_fuv[i]+binsize/2.)
  
     if keyword_set(debug) then print, fism_wv_fuv[i]
    
     for j=0,ntimes-1 do begin
        fism_ip_fuv[i,j]=mean(fism_ip_fuv_hr[wwv_fism_hr,j])
        fism_gp_fuv[i,j]=mean(fism_gp_fuv_hr[wwv_fism_hr,j])
        fism_daily_fuv[i,j]=mean(fism_daily_fuv_hr[wwv_fism_hr])
        fism_pred_fuv[i,j]=mean(fism_pred_fuv_hr[wwv_fism_hr,j])
        fism_sigma_fuv[i,j]=mean(sigma_fism_pred_fuv_hr[wwv_fism_hr,j])
     endfor
     
     if keyword_set(debug) then begin
        cc=independent_color()
        plot, utc_fuv/3600., fism_pred_fuv[i,*], thick=2, xtitle='Hours on DOY: '+styd, charsize=1.5, $
              ytitle='W/m!E2!N/nm', title=strtrim(fism_wv_fuv[i],2)+' nm'
        oplot, utc_fuv/3600., fism_pred_fuv[i,*]+fism_sigma_fuv[i,*], linstyle=1
        oplot, utc_fuv/3600., fism_pred_fuv[i,*]-fism_sigma_fuv[i,*], linstyle=1
        oplot, utc_fuv/3600., fism_ip_fuv[i,*]+fism_daily_fuv[i,*], color=cc.blue
        oplot, utc_fuv/3600., fism_gp_fuv[i,*]+fism_daily_fuv[i,*], color=cc.green
        oplot, utc_fuv/3600., fism_daily_fuv[i,*], color=cc.light_blue
        ;oplot, sutc[gdsol]/3600., ph2watt(solstice_fuv_wavelength[gdsol],solstice_fuv_irradiance[gdsol]), psym=2, $
        ;       color=cc.red, symsize=3
        xyouts, 0.7, 0.9, 'Black: FISM Total (Daily+IP+GP), with 1sigma uncertainties', charsize=1.5, /normal
        xyouts, 0.7, 0.85, 'Blue: FISM IP', charsize=1.5, /normal, color=cc.blue
        xyouts, 0.7, 0.8, 'Green: FISM GP', charsize=1.5, /normal, color=cc.green
        xyouts, 0.7, 0.75, 'Light Blue: FISM Daily', charsize=1.5, /normal, color=cc.light_blue
     endif
  
  endfor
  yr = strmid(tmp_yd,5,4)
  doy = strmid(tmp_yd,9,3)
  subDir = expand_path('$fism_results') + '/flare_data/fuv_flare/' + strmid(tmp_yd,5,4)
  FILE_MKDIR, string(subDir)
  save, fism_pred_fuv, fism_ip_fuv, fism_gp_fuv, fism_daily_fuv, fism_wv_fuv, yr, doy, utc_fuv, fism_sigma_fuv, $
        file='$fism_results' + '/flare_data/fuv_flare/' + strmid(tmp_yd,5,4) + '/fism_fuv_'+strmid(tmp_yd,5,7)+'.sav'
  tmp_yd = get_next_yyyydoy(tmp_yd)
endwhile
if keyword_set(debug) then stop

print, 'End Time create_fism_fuv: ', !stime

end
