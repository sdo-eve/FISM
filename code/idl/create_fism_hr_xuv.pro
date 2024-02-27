;
; NAME: create_fism_hr_xuv
;
; PURPOSE: 
;
; HISTORY:
;       VERSION 2_01
;       04/16/2020, PCC, Eliminating IP from XUV/XPS model, only
;       linear GP flare component
;
;
;
pro create_fism_hr_xuv, styr=styr, stdoy=stdoy, edyr=edyr, eddoy=eddoy, zero_offset=zero_offset, $
       debug=debug, st_wv=st_wv, end_wv=end_wv, binsize=binsize, update=update, w_uncert=w_uncert

print, 'Running create_fism_hr_xuv ', !stime
if not keyword_set(styr) then styr=2003;1982 ;2017
if not keyword_set(stdoy) then stdoy=001;002 ; 249
if not keyword_set(st_wv) then st_wv=0.05
if not keyword_set(end_wv) then end_wv=39.95
if not keyword_set(binsize) then binsize=0.1 ; 0.1 nm bins
if keyword_set(eddoy) then end_yd = fix((strmid(edyr, 4, 4) + strmid(eddoy, 5, 3)), type=3)
ydoy=styr*fix(1000,type=3)+stdoy
if keyword_set(update) then begin
  tdy=long(strmid(get_current_yyyydoy(), 7,8))
  ydoy=get_prev_yyyydoy(tdy,90) ; run for the past 60 days
endif
styd=strtrim(ydoy,2)
yrst=strmid(ydoy,5,4)

; Restore the Version File
restore, expand_path('$fism_save')+'/fism_version_file.sav'

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
FILE_MKDIR, expand_path('$fism_results') + '/flare_data/xuv_flare/'

; Setup array for 5 days worth of 'daily' data at high cadence
fl_pth = expand_path('$fism_data')
resfl=fl_pth+'/lasp/sorce/sorce_xps/hr_goes_xps_wv/hr_goes_xps_comp.sav'
restore, resfl
nwvs=400
sec_step=60
fism_daily_5days=fltarr(nwvs, 5)
time_daily_5days=findgen(5)
time_daily_5days=time_daily_5days*86400+86400/2 ; middle of day timestamp
num_hc=86400/sec_step
fism_hc_daily_5days=fltarr(nwvs, 5.*num_hc)
time_hc_daily_5days=dindgen(5.*num_hc)*sec_step

while tmp_yd lt end_yd do begin
  ydoy=fix(strmid(tmp_yd, 0, 7), type=3)
  styd = strmid(strtrim(tmp_yd,2), 0, 7)
  styr=strmid(styd,0,4)
  yrst=strmid(ydoy,5,4)
  ;print, string(tmp_yd) + ' of ' + string(end_yd)
  ; Get and use SORCE XPS L4 Daily spectrum and smooth it out to higher time
        ;        cadence to remove daily boundary 'steps' in the flare product
        pr_yd=get_prev_yyyydoy(tmp_yd,2)
        restore, '$fism_results/daily_data/xuv_daily/'+strmid(strtrim(pr_yd,2),0,4)+'/FISM_daily_'+strtrim(pr_yd,2)+'_xuv_'+version+'.sav'
        fism_daily_5days[*,0]=fism_pred[0:nwvs-1]
        pr_yd=get_prev_yyyydoy(tmp_yd,1)
        restore, '$fism_results/daily_data/xuv_daily/'+strmid(strtrim(pr_yd,2),0,4)+'/FISM_daily_'+strtrim(pr_yd,2)+'_xuv_'+version+'.sav'
        fism_daily_5days[*,1]=fism_pred[0:nwvs-1]
        restore, '$fism_results/daily_data/xuv_daily/'+strmid(strtrim(tmp_yd,2),0,4)+'/FISM_daily_'+strtrim(tmp_yd,2)+'_xuv_'+version+'.sav'
        fism_daily_5days[*,2]=fism_pred[0:nwvs-1]
        nx_yd=get_next_yyyydoy(tmp_yd,1)
        restore, '$fism_results/daily_data/xuv_daily/'+strmid(strtrim(nx_yd,2),0,4)+'/FISM_daily_'+strtrim(nx_yd,2)+'_xuv_'+version+'.sav'
        fism_daily_5days[*,3]=fism_pred[0:nwvs-1]
        nx_yd=get_next_yyyydoy(tmp_yd,2)
        restore, '$fism_results/daily_data/xuv_daily/'+strmid(strtrim(nx_yd,2),0,4)+'/FISM_daily_'+strtrim(nx_yd,2)+'_xuv_'+version+'.sav'
        fism_daily_5days[*,4]=fism_pred[0:nwvs-1]
        ; Spline fit daily values to high cadence values
        for f=0,nwvs-1 do begin
           fism_hc_daily_5days[f,*]=interpol(fism_daily_5days[f,*],time_daily_5days,time_hc_daily_5days,/spline)
        endfor
        ; Pull out the central day (tmp_yd) to use as the high cadence 'daily' data
        fism_daily_tmpyd=fism_hc_daily_5days[*,(2*num_hc):(3*num_hc-1)]
  
  ;wdoy_l4_xps=where(xps_l4.date eq ydoy)
  if fix(strmid(tmp_yd,5,4)) ge 1996 then begin
    ; Get the NOAA Events data
    restore, '$fism/tmp/noaa_flr_data_'+strtrim(styr,2)+'.sav'
    gdnoaady=where(noaa_flare_dat.yyyydoy eq ydoy)
    if gdnoaady[0] ne -1 then begin
       ngevents=n_elements(gdnoaady)
       fl_dist_noaa=fltarr(ngevents)
       for g=0,ngevents-1 do begin
          fl_lat=fix(strmid(noaa_flare_dat[gdnoaady[g]].locat,1,2))
          fl_long=fix(strmid(noaa_flare_dat[gdnoaady[g]].locat,4,2))
          fl_dist_noaa[g]=sqrt(fl_lat^2.+fl_long^2.)
       endfor
       fl_dist_noaa_avg=mean(fl_dist_noaa) ; just use average distance of all events for the day
    endif else fl_dist_noaa_avg=0.0
  endif else begin
  fl_dist_noaa_avg=0.0
  endelse
  
  ; Get the GOES XRS data
  goes_flnm='$fism_data/lasp/goes_xrs/goes_1mdata_widx_'+styr+'.sav' 
  restore, goes_flnm
  dgoes_dt_all=(goes.long-shift(goes.long,1))/(goes.time-shift(goes.time,1))>0.0
  ; Get GOES XRS data for the specified day
  ; Convert GOES time to utc
  gps_to_utc,goes.time, 13, gyyyy, gdoy, gutc, gmonth, gday, ghh, gmm, gss, auto=1, julian=jd
  gydoy=gyyyy*1000+gdoy
  gdgoesdy=where(gydoy eq tmp_yd)
  dgoes_dt=dgoes_dt_all[gdgoesdy]
  goes_long=goes[gdgoesdy].long
  utc_xuv=gutc[gdgoesdy]
  ; Check to make sure there is GOES data for every 60 sec, if not interpolate
  ntms=n_elements(utc_xuv)
  if ntms ne 1440 then begin
     utc_xuv=dindgen(1440)*60d
     dgoes_dt=interpol(dgoes_dt,gutc[gdgoesdy],utc_xuv)
     goes_long=interpol(goes_long,gutc[gdgoesdy],utc_xuv)
  endif
  
  ntimes=n_elements(goes_long)
  fism_daily_xuv_hr=fism_daily_tmpyd ; put int the daily interpolated array
  fism_ip_xuv_hr=fltarr(nwvs,ntimes)
  fism_gp_xuv_hr=fltarr(nwvs,ntimes)
  fism_pred_xuv_hr=fltarr(nwvs,ntimes)
  fism_sigma_ip_xuv_hr=fltarr(nwvs,ntimes)
  fism_sigma_gp_xuv_hr=fltarr(nwvs,ntimes)
  fism_sigma_xuv_hr=fltarr(nwvs,ntimes)
  fism_wv_xuv_hr=fltarr(nwvs)
  
  for i=0,nwvs-1 do begin         ; 0.1nm bins
     fism_wv_xuv_hr[i]=(i/10.)+0.05
     if keyword_set(debug) then print, fism_wv_xuv_hr[i]
  
     ; Compute FISM
     if fl_dist_noaa_avg ge 75 then begin
        ;coefs_ip=linfit_coefs_limb_ip[*,i]
        coefs_gp=linfit_coefs_limb[*,i]
        ;sigma_coefs_ip=sigma_linfit_coefs_limb_ip[*,i]
        ;sigma_coefs_gp=sigma_linfit_coefs_limb_gp[*,i]
        perer_gp=yer_gp_l[i]
     endif else if fl_dist_noaa_avg ge 45 and fl_dist_noaa_avg lt 75 then begin
        ;coefs_ip=linfit_coefs_mid_ip[*,i]
        coefs_gp=linfit_coefs_mid[*,i]
        ;sigma_coefs_ip=sigma_linfit_coefs_mid_ip[*,i]
        ;sigma_coefs_gp=sigma_linfit_coefs_mid_gp[*,i]
        perer=yer_gp_m[i]
     endif else begin
        ;coefs_ip=linfit_coefs_cent_ip[*,i]
        coefs_gp=linfit_coefs_cent[*,i]
        ;sigma_coefs_ip=sigma_linfit_coefs_cent_ip[*,i]
        ;sigma_coefs_gp=sigma_linfit_coefs_cent_gp[*,i]
        perer=yer_gp_c[i]
     endelse
     if keyword_set(zero_offset) then begin
        ;fism_ip_xuv_hr[i,*]=(coefs_ip[0]+coefs_ip[1]*dgoes_dt)>0.0
        fism_gp_xuv_hr[i,*]=(coefs_gp[0]+coefs_gp[1]*goes_long)>0.0
        ;fism_sigma_ip_xuv_hr[i,*]=(sigma_coefs_ip[0]+sigma_coefs_ip[1]*dgoes_dt)>0.0
        ;fism_sigma_gp_xuv_hr[i,*]=(sigma_coefs_gp[0]+sigma_coefs_gp[1]*goes_long)>0.0
        fism_sigma_gp_xuv_hr[i,*]=fism_gp_xuv_hr[i,*]*perer
     endif else begin
        ;fism_ip_xuv_hr[i,*]=(coefs_ip[1]*dgoes_dt)>0.0
        fism_gp_xuv_hr[i,*]=(coefs_gp[1]*goes_long)>0.0
        ;fism_sigma_ip_xuv_hr[i,*]=(sigma_coefs_ip[1]*dgoes_dt)>0.0
        ;fism_sigma_gp_xuv_hr[i,*]=(sigma_coefs_gp[1]*goes_long)>0.0
        fism_sigma_gp_xuv_hr[i,*]=fism_gp_xuv_hr[i,*]*perer
     endelse
     fism_pred_xuv_hr[i,*]=fism_gp_xuv_hr[i,*]+fism_daily_xuv_hr[i,*] ;+fism_ip_xuv_hr[i,*] No longer including IP
     ;fism_ip_rel_err=(fism_sigma_ip_xuv_hr[i,*]/fism_ip_xuv_hr[i,*])>0. ; 1sig Relative error (E.G. X100 is % error)
     ;fism_gp_rel_err=(fism_sigma_gp_xuv_hr[i,*]/fism_gp_xuv_hr[i,*])>0. ; 1sig Relative error (E.G. X100 is % error)
     ;fism_sigma_xuv_hr[i,*]=sqrt(fism_ip_rel_err*fism_ip_rel_err+$  
     ;                           fism_gp_rel_err*fism_gp_rel_err+$
     ;                           fism_error[i]*fism_error[i])
     daily_abs_er=fism_error[i]*fism_daily_xuv_hr[i,*] ; relative error*irradiance=abs_error
     fism_flare_rss_abs_error=sqrt(daily_abs_er*daily_abs_er+fism_sigma_gp_xuv_hr[i,*]*fism_sigma_gp_xuv_hr[i,*])
     fism_sigma_xuv_hr[i,*]=fism_flare_rss_abs_error/fism_pred_xuv_hr[i,*] ; 1sig Relative error (E.G. X100 is % error)
     
     if keyword_set(debug) then begin
        if keyword_set(w_uncert) then !p.multi=[0,1,2]
        cc=independent_color()
        plot, utc_xuv/3600., fism_pred_xuv_hr[i,*], thick=2, xtitle='Hours on DOY: '+styd, charsize=1.5, $
              ytitle='W/m!E2!N/nm', title=strtrim(fism_wv_xuv_hr[i],2)+' nm'
        ;oplot,utc_xuv/3600., fism_ip_xuv_hr[i,*]+fism_daily_xuv_hr[i], color=cc.blue
        oplot, utc_xuv/3600., fism_gp_xuv_hr[i,*]+fism_daily_xuv_hr[i], color=cc.green
        oplot, [0,25], [fism_daily_xuv_hr[i],fism_daily_xuv_hr[i]], color=cc.light_blue
        ;oplot, sutc[gdsol]/3600., ph2watt(solstice_fuv_wavelength[gdsol],solstice_fuv_irradiance[gdsol]), psym=2, $
        ;       color=cc.red, symsize=3
        xyouts, 0.7, 0.9, 'Black: FISM Total (Daily+IP+GP)', charsize=1.5, /normal;, color=cc.red
        ;xyouts, 0.7, 0.85, 'Blue: FISM IP', charsize=1.5, /normal, color=cc.blue
        xyouts, 0.7, 0.8, 'Green: FISM GP', charsize=1.5, /normal, color=cc.green
        xyouts, 0.7, 0.75, 'Light Blue: FISM Daily', charsize=1.5, /normal, color=cc.light_blue
        ans=''
        if keyword_set(w_uncert) then begin
           plot, utc_xuv/3600., fism_sigma_xuv_hr[i,*]*100., thick=2, xtitle='Hours on DOY: '+styd, charsize=1.5, $
                 ytitle='Uncertainty (%)'
        endif
        
        read, ans, prompt='Next (or 2 to stop)? '
        if ans eq 2 then stop
     endif
  
  endfor
  yr = strmid(tmp_yd,5,4)
  doy = strmid(tmp_yd,9,3)
  subDir = expand_path('$fism_results') + '/flare_data/xuv_flare/' + strmid(tmp_yd,5,4)
  FILE_MKDIR, string(subDir)
  save, fism_pred_xuv_hr, fism_gp_xuv_hr, fism_daily_xuv_hr, fism_wv_xuv_hr, yr, doy, utc_xuv, $
        fism_sigma_xuv_hr, fism_sigma_gp_xuv_hr, $ ;fism_ip_xuv_hr, fism_sigma_ip_xuv_hr, 
        file='$fism_results' + '/flare_data/xuv_flare/' + strmid(tmp_yd,5,4) + '/fism_xuv_' + strmid(tmp_yd,5,7) +'_hr.sav'
  tmp_yd = get_next_yyyydoy(tmp_yd)
endwhile
if keyword_set(debug) then stop
print, 'End time create_fism_hr_xuv: ', !stime
end
