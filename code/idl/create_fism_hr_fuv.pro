;
; NAME: create_fism_hr_fuv
;
; PURPOSE: 
;
; HISTORY:
;       VERSION 2_01
;
;
;
pro create_fism_hr_fuv, styr=styr, stdoy=stdoy, edyr=edyr, eddoy=eddoy, zero_offset=zero_offset, $
       debug=debug, st_wv=st_wv, end_wv=end_wv, binsize=binsize, update=update, w_uncert=w_uncert
print, 'Running create_fism_hr_fuv ', !stime

if not keyword_set(styr) then styr=2003;1982
;if not keyword_set(edyr) then styr=2003;1982
if not keyword_set(stdoy) then stdoy=001;002;249
if not keyword_set(st_wv) then st_wv=115.00
if not keyword_set(end_wv) then end_wv=189.87
if not keyword_set(binsize) then binsize=0.03 ; 0.03 nm bins
if keyword_set(eddoy) then end_yd = fix((strmid(edyr, 4, 4) + strmid(eddoy, 5, 3)), type=3)

; Restore the Version File
restore, expand_path('$fism_save')+'/fism_version_file.sav'


ydoy=styr*fix(1000,type=3)+stdoy
if keyword_set(update) then begin
  tdy=long(strmid(get_current_yyyydoy(), 7,8))
  ydoy=get_prev_yyyydoy(tdy,90) ; run for the past 60 days
endif
styd=strtrim(ydoy,2)
yrst=strmid(ydoy,5,4)
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
FILE_MKDIR, expand_path('$fism_results') + '/flare_data/fuv_flare_hr/'

; Restore the SORCE SOLSTICE Full spectral and temproal calibrated
; data - recieved via private communication w/Marty Snow, LASP
;ss_files=findfile('$src_sol_data/')
;n_ss_files=n_elements(ss_files)
; Concatenate files
;restore, '$src_sol_data/'+ss_files[0]
;solstice_fuv_microsec=solstice_fuv.microsecondssincegpsepoch
;solstice_fuv_wavelength=solstice_fuv.wavelength
;solstice_fuv_irradiance=solstice_fuv.irradiance
;for i=1,n_ss_files-1 do begin
;   restore, '$src_sol_data/'+ss_files[i]
;   solstice_fuv_microsec=[solstice_fuv_microsec,solstice_fuv.microsecondssincegpsepoch]
;   solstice_fuv_wavelength=[solstice_fuv_wavelength,solstice_fuv.wavelength]
;   solstice_fuv_irradiance=[solstice_fuv_irradiance,solstice_fuv.irradiance]
;endfor
; Some are out of order (?Bad time stamp?)
;srt_ss=sort(solstice_fuv_microsec)
;solstice_fuv_microsec=solstice_fuv_microsec(srt_ss)
;solstice_fuv_wavelength=solstice_fuv_wavelength(srt_ss)
;solstice_fuv_irradiance=solstice_fuv_irradiance(srt_ss)

; Convert solstice time to utc
;gps_to_utc, solstice_fuv_microsec/1d6, 13, syyyy, sdoy, sutc, smonth, sday, shh, smm, sss, auto=1, julian=jd
;sydoy=syyyy*fix(1000,type=3)+sdoy

;anyd:
; Setup array for 5 days worth of 'daily' data at high cadence
resfl='$fism_data/lasp/sorce/solstice_daily/hr_goes_sols_wv/hr_goes_sol_comp_*'
gdresfl=file_search(resfl)
nwvs=n_elements(gdresfl)
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
  ; Get the FISM FUV Daily spectrum (created from comp_fism_daily_fuv.pro) smooth it out to higher time
        ;        cadence to remove daily boundary 'steps' in the flare product
        pr_yd=get_prev_yyyydoy(tmp_yd,2)
        restore, '$fism_results/daily_data/fuv_daily_hr/'+strmid(strtrim(pr_yd,2),0,4)+'/FISM_daily_'+strtrim(pr_yd,2)+'_fuv_'+version+'_hr.sav'
        fism_daily_5days[*,0]=fism_pred[0:nwvs-1]
        pr_yd=get_prev_yyyydoy(tmp_yd,1)
        restore, '$fism_results/daily_data/fuv_daily_hr/'+strmid(strtrim(pr_yd,2),0,4)+'/FISM_daily_'+strtrim(pr_yd,2)+'_fuv_'+version+'_hr.sav'
        fism_daily_5days[*,1]=fism_pred[0:nwvs-1]
        restore, '$fism_results/daily_data/fuv_daily_hr/'+strmid(strtrim(tmp_yd,2),0,4)+'/FISM_daily_'+strtrim(tmp_yd,2)+'_fuv_'+version+'_hr.sav'
        fism_daily_5days[*,2]=fism_pred[0:nwvs-1]
        nx_yd=get_next_yyyydoy(tmp_yd,1)
        restore, '$fism_results/daily_data/fuv_daily_hr/'+strmid(strtrim(nx_yd,2),0,4)+'/FISM_daily_'+strtrim(nx_yd,2)+'_fuv_'+version+'_hr.sav'
        fism_daily_5days[*,3]=fism_pred[0:nwvs-1]
        nx_yd=get_next_yyyydoy(tmp_yd,2)
        restore, '$fism_results/daily_data/fuv_daily_hr/'+strmid(strtrim(nx_yd,2),0,4)+'/FISM_daily_'+strtrim(nx_yd,2)+'_fuv_'+version+'_hr.sav'
        fism_daily_5days[*,4]=fism_pred[0:nwvs-1]
        ; Spline fit daily values to high cadence values
        for f=0,nwvs-1 do begin
           fism_hc_daily_5days[f,*]=interpol(fism_daily_5days[f,*],time_daily_5days,time_hc_daily_5days,/spline)
        endfor
        ; Pull out the central day (tmp_yd) to use as the high cadence 'daily' data
        fism_daily_tmpyd=fism_hc_daily_5days[*,(2*num_hc):(3*num_hc-1)]

  ; Get the NOAA Events data
  if fix(strmid(tmp_yd,5,4)) ge 1996 then begin
    restore, '$fism/tmp/noaa_flr_data_'+strmid(tmp_yd,5,4)+'.sav'
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
  utc_fuv=gutc[gdgoesdy]
  ; Check to make sure there is GOES data for every 60 sec, if not interpolate
  ntms=n_elements(utc_fuv)
  if ntms ne 1440 then begin
     utc_fuv=dindgen(1440)*60d
     dgoes_dt=interpol(dgoes_dt,gutc[gdgoesdy],utc_fuv)
     goes_long=interpol(goes_long,gutc[gdgoesdy],utc_fuv)
  endif
 
  ntimes=n_elements(goes_long)
  ;fism_daily_fuv_hr=fltarr(nwvs)
  fism_daily_fuv_hr=fltarr(nwvs,ntimes) ; now have interpolated daily values
  fism_ip_fuv_hr=fltarr(nwvs,ntimes)
  fism_gp_fuv_hr=fltarr(nwvs,ntimes)
  fism_pred_fuv_hr=fltarr(nwvs,ntimes)
  sigma_fism_ip_fuv_hr=fltarr(nwvs,ntimes)
  sigma_fism_gp_fuv_hr=fltarr(nwvs,ntimes)
  sigma_fism_pred_fuv_hr=fltarr(nwvs,ntimes)
  fism_ip_fuv_hr_xlog=fltarr(nwvs,ntimes)
  fism_gp_fuv_hr_xlog=fltarr(nwvs,ntimes)
  fism_pred_fuv_hr_xlog=fltarr(nwvs,ntimes)
  sigma_fism_ip_fuv_hr_xlog=fltarr(nwvs,ntimes)
  sigma_fism_gp_fuv_hr_xlog=fltarr(nwvs,ntimes)
  sigma_fism_pred_fuv_hr_xlog=fltarr(nwvs,ntimes)
  fism_wv_fuv_hr=fltarr(nwvs)
  
  for i=0,nwvs-1 do begin         ; 0.03nm bins
     ; Restore fit coef savesets created by 'solstice_goes_comp.pro' 
     
     restore, gdresfl[i] ; includes wv variable
  
     if keyword_set(debug) then print, wv
     fism_wv_fuv_hr[i]=wv
  
  
     ; Get Daliy Value for this wavelength from FISM FUV daily Spectrum 
     wwv_fism_daily=where(fism_wv ge wv-binsize/2. and fism_wv lt wv+binsize/2.)
     ;fism_daily_fuv_hr[i]=mean(fism_pred[wwv_fism_daily])
     fism_daily_fuv_hr[i,*]=fism_daily_tmpyd[wwv_fism_daily,*]
   
     ; Compute FISM 
     ; IP fit is a linear fit from 120.5nm to 129.0nm, and power law elsewhere
     ;   due to the higher frequency SOLSTICE scans in this range
     ;   made for higher flare level measurements and constraints
     ;   on the linar fit (power is <1.0)
     if fl_dist_noaa_avg ge 75 then begin
        coefs_gp=linfit_coefs_limb
        ;sigma_coefs_gp=sigma_linfit_coefs_limb_gp
        perer_gp=yer_gp_l
        ;if wv ge 120.5 and wv le 129.0 then begin
           coefs_ip=linfit_coefs_limb_ip
           ;sigma_coefs_ip=sigma_linfit_coefs_limb_ip
           perer_ip=yer_ip_l
        ;endif else begin
        ;   coefs_ip=logfit_coefs_limb_ip
        ;   sigma_coefs_ip=sigma_logfit_coefs_limb_ip
        ;endelse
        
        ;coefs_ip_xlog=linfit_xlog_coefs_limb_ip
        ;coefs_gp_xlog=linfit_xlog_coefs_limb
        ;sigma_coefs_ip_xlog=sigma_linfit_xlog_coefs_limb_ip
        ;sigma_coefs_gp_xlog=sigma_linfit_xlog_coefs_limb_ip
        ;tp_gp=tp_gp_limb
        ;tp_ip=tp_ip_limb
     endif else if fl_dist_noaa_avg ge 45 and fl_dist_noaa_avg lt 75 then begin
        coefs_gp=linfit_coefs_mid
        ;sigma_coefs_gp=sigma_linfit_coefs_mid_gp
        perer_gp=yer_gp_m
        ;if wv ge 120.5 and wv le 129.0 then begin
           coefs_ip=linfit_coefs_mid_ip
           ;sigma_coefs_ip=sigma_linfit_coefs_mid_ip
           perer_ip=yer_ip_m
        ;endif else begin
        ;   coefs_ip=logfit_coefs_mid_ip
        ;   sigma_coefs_ip=sigma_logfit_coefs_mid_ip
        ;endelse
        
        ;coefs_ip_xlog=linfit_xlog_coefs_mid_ip
        ;coefs_gp_xlog=linfit_xlog_coefs_mid
        ;sigma_coefs_ip_xlog=sigma_linfit_xlog_coefs_mid_ip
        ;sigma_coefs_gp_xlog=sigma_linfit_xlog_coefs_mid_ip
        ;tp_gp=tp_gp_mid
        ;tp_ip=tp_ip_mid
     endif else begin
        coefs_gp=linfit_coefs_cent
        ;sigma_coefs_gp=sigma_linfit_coefs_cent_gp
        perer_gp=yer_gp_c
        ;if wv ge 120.5 and wv le 129.0 then begin
           coefs_ip=linfit_coefs_cent_ip
           ;sigma_coefs_ip=sigma_linfit_coefs_cent_ip
           perer_ip=yer_ip_c
        ;endif else begin
        ;   coefs_ip=logfit_coefs_cent_ip
        ;   sigma_coefs_ip=sigma_logfit_coefs_cent_ip
        ;endelse
        
        ;coefs_ip_xlog=linfit_xlog_coefs_cent_ip
        ;coefs_gp_xlog=linfit_xlog_coefs_cent
        ;sigma_coefs_ip_xlog=sigma_linfit_xlog_coefs_cent_ip
        ;sigma_coefs_gp_xlog=sigma_linfit_xlog_coefs_cent_ip
        ;tp_gp=tp_gp_cent
        ;tp_ip=tp_ip_cent
     endelse
     ; Make sure coefs are >0
     coefs_ip=coefs_ip>0.0
     coefs_gp=coefs_gp>0.0
     ;sigma_coefs_ip=sigma_coefs_ip>0.0
     ;sigma_coefs_gp=sigma_coefs_gp>0.0
     if keyword_set(zero_offset) then begin
        ;if wv ge 120.5 and wv le 129.0 then begin
           fism_ip_fuv_hr[i,*]=(coefs_ip[0]+coefs_ip[1]*dgoes_dt)>0.0
           ;sigma_fism_ip_fuv_hr[i,*]=(sigma_coefs_ip[0]+sigma_coefs_ip[1]*dgoes_dt)>0.0
           sigma_fism_ip_fuv_hr[i,*]=(fism_ip_fuv_hr[i,*]*perer_ip)>0.0
        ;endif else begin
        ;   fism_ip_fuv_hr[i,*]=(coefs_ip[0]*dgoes_dt^coefs_ip[1])>0.0
        ;   sigma_fism_ip_fuv_hr[i,*]=exp(sigma_coefs_ip[0]+coefs_ip[0])*dgoes_dt^(coefs_ip[1]-sigma_coefs_ip[1])-fism_ip_fuv_hr[i,*]
        ;endelse
        ; GP
        fism_gp_fuv_hr[i,*]=(coefs_gp[0]+coefs_gp[1]*goes_long)>0.0
        ;sigma_fism_gp_fuv_hr[i,*]=(sigma_coefs_gp[0]+sigma_coefs_gp[1]*goes_long)>0.0
        sigma_fism_gp_fuv_hr[i,*]=(fism_gp_fuv_hr[i,*]*perer_gp)>0.0
     endif else begin
        ;if wv ge 120.5 and wv le 129.0 then begin
           fism_ip_fuv_hr[i,*]=(coefs_ip[1]*dgoes_dt)>0.0
           ;sigma_fism_ip_fuv_hr[i,*]=(sigma_coefs_ip[1]*dgoes_dt)>0.0
           sigma_fism_ip_fuv_hr[i,*]=(fism_ip_fuv_hr[i,*]*perer_ip)>0.0
        ;endif else begin ; power law doesn't matter if /zero_offset is set
        ;   fism_ip_fuv_hr[i,*]=(coefs_ip[0]*dgoes_dt^coefs_ip[1])>0.0
        ;   sigma_fism_ip_fuv_hr[i,*]=exp(sigma_coefs_ip[0]+coefs_ip[0])*dgoes_dt^(coefs_ip[1]-sigma_coefs_ip[1])-fism_ip_fuv_hr[i,*]
        ;endelse
        fism_gp_fuv_hr[i,*]=(coefs_gp[1]*goes_long)>0.0
        ;sigma_fism_gp_fuv_hr[i,*]=(sigma_coefs_gp[1]*goes_long)>0.0
        sigma_fism_gp_fuv_hr[i,*]=(fism_gp_fuv_hr[i,*]*perer_gp)>0.0
     endelse
     ; xlog always needs zero offset
     ;fism_ip_fuv_hr_xlog[i,*]=(coefs_ip_xlog[0]+coefs_ip_xlog[1]*alog10(dgoes_dt))>0.0
     ;fism_gp_fuv_hr_xlog[i,*]=(coefs_gp_xlog[0]+coefs_gp_xlog[1]*alog10(goes_long))>0.0
     ;sigma_fism_ip_fuv_hr_xlog[i,*]=((coefs_ip_xlog[0]+sigma_coefs_ip_xlog[0])+$
     ;                                (coefs_ip_xlog[1]+sigma_coefs_ip_xlog[1])*alog10(dgoes_dt))>0.0
     ;sigma_fism_gp_fuv_hr_xlog[i,*]=((coefs_gp_xlog[0]+sigma_coefs_gp_xlog[0])+$
     ;                                (coefs_gp_xlog[1]+sigma_coefs_gp_xlog[1])*alog10(goes_long))>0.0

     ; Combine the results to use xlog fits below the the transition point and linear fits after
     ;pltx_ip=findgen(1.d7)/1.e12 ; from solstice_goes_comp.pro
     ;pltx_gp=findgen(1.d6)/1.e7     ; from solstice_goes_comp.pro
     ;ab_tp_ip=pltx_ip[tp_ip]
     ;ab_tp_gp=pltx_gp[tp_gp]
     ;wlog_ip=where(dgoes_dt le ab_tp_ip)
     ;wlog_gp=where(goes_long le ab_tp_gp)
     ;fism_ip_fuv_hr[i,wlog_ip]=fism_ip_fuv_hr_xlog[i,wlog_ip]
     ;fism_gp_fuv_hr[i,wlog_gp]=fism_gp_fuv_hr_xlog[i,wlog_gp]
     ;sigma_fism_ip_fuv_hr[i,wlog_ip]=sigma_fism_ip_fuv_hr_xlog[i,wlog_ip]
     ;sigma_fism_gp_fuv_hr[i,wlog_gp]=sigma_fism_gp_fuv_hr_xlog[i,wlog_gp]

     ; Make it relative error and
     ; Add IP+GP+Daily=FISM Flare
                                ;if coefs_ip[1] and coefs_gp[1] le 0.0
                                ;then begin ; only daily component, no
                                ;flare component found
     ; Find the Daily error and populate all times
     fism_pred_fuv_hr[i,*]=fism_daily_fuv_hr[i,*] ; start with interpolated daily values, then add on valid IP or GP later
     sigma_fism_pred_fuv_hr[i,*]=fism_error[wwv_fism_daily]
     fism_daily_abs_err=reform(fism_daily_fuv_hr[i,*])*fism_error[wwv_fism_daily[0]]; find daily absolute daily error
        
     if coefs_ip[1] gt 0.0 and coefs_gp[1] le 0.0 then begin ; only ip flare component
        wgd_ip_sigma=where(dgoes_dt gt 0.0)                    ; find where dgoes_dt > 0.0 
        fism_pred_fuv_hr[i,wgd_ip_sigma]=fism_pred_fuv_hr[i,wgd_ip_sigma]+fism_ip_fuv_hr[i,wgd_ip_sigma] ; only popluate where good dgoes_dt
        ; find RSS of absolute sigma values, e.g. abs_rss=sqrt(daily_abs_sig^2+IP_abs_sigma^2)
        sigma_fism_rss=sqrt(fism_daily_abs_err[wgd_ip_sigma]*fism_daily_abs_err[wgd_ip_sigma]+$
                            sigma_fism_ip_fuv_hr[i,wgd_ip_sigma]*sigma_fism_ip_fuv_hr[i,wgd_ip_sigma])
        sigma_fism_pred_fuv_hr[i,wgd_ip_sigma]=sigma_fism_rss/fism_pred_fuv_hr[i,wgd_ip_sigma] ; Divide by the absolute irradiance to make relative error
        sigma_fism_ip_fuv_hr[i,wgd_ip_sigma]=sigma_fism_ip_fuv_hr[i,wgd_ip_sigma]/fism_ip_fuv_hr[i,wgd_ip_sigma]  ; Convert to relative IP error
        sigma_fism_gp_fuv_hr[i,*]=0.0
     endif else if coefs_ip[1] le 0.0 and coefs_gp[1] gt 0.0 then begin ; only gp flare component
        wgd_gp_sigma=where(goes_long gt 0.0) ; find where goes_long > 0.0
        fism_pred_fuv_hr[i,wgd_gp_sigma]=fism_pred_fuv_hr[i,wgd_gp_sigma]+fism_gp_fuv_hr[i,wgd_gp_sigma] ; only popluate where good goes_long
        ; find RSS of absolute sigma values, e.g. abs_rss=sqrt(daily_abs_sig^2+GP_abs_sigma^2)
        sigma_fism_rss=sqrt(fism_daily_abs_err[wgd_gp_sigma]*fism_daily_abs_err[wgd_gp_sigma]+$
                            sigma_fism_gp_fuv_hr[i,wgd_gp_sigma]*sigma_fism_gp_fuv_hr[i,wgd_gp_sigma])
        sigma_fism_pred_fuv_hr[i,wgd_gp_sigma]=sigma_fism_rss/fism_pred_fuv_hr[i,wgd_gp_sigma] ; Divide by the absolute irradiance to make relative error
        sigma_fism_gp_fuv_hr[i,wgd_gp_sigma]=sigma_fism_gp_fuv_hr[i,wgd_gp_sigma]/fism_gp_fuv_hr[i,wgd_gp_sigma]  ; Convert to relative IP error
        sigma_fism_ip_fuv_hr[i,*]=0.0 ; No ip error if no ip component
     endif else if coefs_ip[1] gt 0.0 and coefs_gp[1] gt 0.0 then begin  ; both ip and gp flare component
        wgd_ip_sigma=where(dgoes_dt gt 0.0 and goes_long le 0.0)                    ; find where dgoes_dt > 0.0 and goes_long < 0.0 (only ip)
        fism_pred_fuv_hr[i,wgd_ip_sigma]=fism_pred_fuv_hr[i,wgd_ip_sigma]+fism_ip_fuv_hr[i,wgd_ip_sigma] ; only popluate where good dgoes_dt
        ; find RSS of absolute sigma values, e.g. abs_rss=sqrt(daily_abs_sig^2+IP_abs_sigma^2)
        sigma_fism_rss=sqrt(fism_daily_abs_err[wgd_ip_sigma]*fism_daily_abs_err[wgd_ip_sigma]+ $
                            sigma_fism_ip_fuv_hr[i,wgd_ip_sigma]*sigma_fism_ip_fuv_hr[i,wgd_ip_sigma])
        sigma_fism_pred_fuv_hr[i,wgd_ip_sigma]=sigma_fism_rss/fism_pred_fuv_hr[i,wgd_ip_sigma] ; Divide by the absolute irradiance to make relative error
        sigma_fism_ip_fuv_hr[i,wgd_ip_sigma]=sigma_fism_ip_fuv_hr[i,wgd_ip_sigma]/fism_ip_fuv_hr[i,wgd_ip_sigma]  ; Convert to relative IP error
        sigma_fism_gp_fuv_hr[i,wgd_ip_sigma]=0.0 ; no gp error if no gp component

        wgd_gp_sigma=where(goes_long gt 0.0 and dgoes_dt le 0.0)              ; find where goes_long > 0.0 and dgoes_dt < 0.0 (only gp)
        fism_pred_fuv_hr[i,wgd_gp_sigma]=fism_pred_fuv_hr[i,wgd_gp_sigma]+fism_gp_fuv_hr[i,wgd_gp_sigma] ; only popluate where good goes_long
        ; find RSS of absolute sigma values, e.g. abs_rss=sqrt(daily_abs_sig^2+GP_abs_sigma^2)
        sigma_fism_rss=sqrt(fism_daily_abs_err[wgd_gp_sigma]*fism_daily_abs_err[wgd_gp_sigma]+$
                            sigma_fism_gp_fuv_hr[i,wgd_gp_sigma]*sigma_fism_gp_fuv_hr[i,wgd_gp_sigma])
        sigma_fism_pred_fuv_hr[i,wgd_gp_sigma]=sigma_fism_rss/fism_pred_fuv_hr[i,wgd_gp_sigma] ; Divide by the absolute irradiance to make relative error
        sigma_fism_gp_fuv_hr[i,wgd_gp_sigma]=sigma_fism_gp_fuv_hr[i,wgd_gp_sigma]/fism_gp_fuv_hr[i,wgd_gp_sigma]  ; Convert to relative GP error
        sigma_fism_ip_fuv_hr[i,*]=0.0        ; No ip error if no ip component

        wgd_gp_ip_sigma=where(goes_long gt 0.0 and dgoes_dt gt 0.0) ; find where goes_long > 0.0 and dgoes_dt > 0.0 (both ip and gp)
        fism_pred_fuv_hr[i,wgd_gp_ip_sigma]=fism_pred_fuv_hr[i,wgd_gp_ip_sigma]+fism_gp_fuv_hr[i,wgd_gp_ip_sigma] + $
                                fism_ip_fuv_hr[i,wgd_gp_ip_sigma]; only popluate where good goes_long and good dgoes_dt
        ; find RSS of absolute sigma values, e.g. abs_rss=sqrt(daily_abs_sig^2+GP_abs_sigma^2+IP_abs_sigma^2)
        sigma_fism_rss=sqrt(fism_daily_abs_err[wgd_gp_ip_sigma]*fism_daily_abs_err[wgd_gp_ip_sigma]+$
                            sigma_fism_gp_fuv_hr[i,wgd_gp_ip_sigma]*sigma_fism_gp_fuv_hr[i,wgd_gp_ip_sigma]+$
                            sigma_fism_ip_fuv_hr[i,wgd_gp_ip_sigma]*sigma_fism_ip_fuv_hr[i,wgd_gp_ip_sigma])
        sigma_fism_pred_fuv_hr[i,wgd_gp_ip_sigma]=sigma_fism_rss/fism_pred_fuv_hr[i,wgd_gp_ip_sigma] ; Divide by the absolute irradiance to make relative error
        sigma_fism_gp_fuv_hr[i,wgd_gp_ip_sigma]=sigma_fism_gp_fuv_hr[i,wgd_gp_ip_sigma]/fism_gp_fuv_hr[i,wgd_gp_ip_sigma]  ; Convert to relative GP error
        sigma_fism_ip_fuv_hr[i,wgd_gp_ip_sigma]=sigma_fism_ip_fuv_hr[i,wgd_gp_ip_sigma]/fism_ip_fuv_hr[i,wgd_gp_ip_sigma]  ; Convert to relative IP error
        
     endif 
     
             
     if keyword_set(debug) then begin
        if keyword_set(w_uncert) then !p.multi=[0,1,2]
        cc=independent_color()
        ymn=0.95*min(fism_daily_fuv_hr[i])
        ymx=1.05*max(fism_pred_fuv_hr[i,*])
        plot, utc_fuv/3600., fism_pred_fuv_hr[i,*], thick=2, xtitle='Hours on DOY: '+styd, charsize=1.5, $
              ytitle='W/m!E2!N/nm', title=strtrim(wv,2)+' nm', xr=[0,24], yr=[ymn,ymx]
        oplot, utc_fuv/3600., fism_ip_fuv_hr[i,*]+fism_daily_fuv_hr[i,*], color=cc.blue
        oplot, utc_fuv/3600., fism_gp_fuv_hr[i,*]+fism_daily_fuv_hr[i,*], color=cc.green
        oplot, utc_fuv/3600., fism_daily_fuv_hr[i,*], color=cc.light_blue
        ;oplot, sutc[gdsol]/3600., ph2watt(solstice_fuv_wavelength[gdsol],solstice_fuv_irradiance[gdsol]), psym=2, $
        ;       color=cc.red, symsize=3
        xyouts, 0.7, 0.9, 'Black: FISM Total (Daily+IP+GP)', charsize=1.5, /normal
        xyouts, 0.7, 0.85, 'Blue: FISM IP', charsize=1.5, /normal, color=cc.blue
        xyouts, 0.7, 0.8, 'Green: FISM GP', charsize=1.5, /normal, color=cc.green
        xyouts, 0.7, 0.75, 'Light Blue: FISM Daily', charsize=1.5, /normal, color=cc.light_blue
        plot, utc_fuv/3600., sigma_fism_pred_fuv_hr[i,*]*100., thick=2, xtitle='Hours on DOY: '+styd, charsize=1.5, $
              ytitle='% Error', title=strtrim(wv,2)+' nm', xr=[0,24];, yr=[ymn,ymx]
        ;if max(sigma_fism_pred_fuv_hr[i,*]*100.) gt 100. then stop
        ans=''
        read, ans, prompt='Ret to cont, 2 to stop'
        if ans eq 2 then stop
     endif
  
  endfor
  if keyword_set(debug) then stop
  yr = strmid(tmp_yd,5,4)
  doy = strmid(tmp_yd,9,3)
  subDir = expand_path('$fism_results') + '/flare_data/fuv_flare_hr/' + strmid(tmp_yd,5,4)
  FILE_MKDIR, string(subDir)
  save, fism_pred_fuv_hr, fism_ip_fuv_hr, fism_gp_fuv_hr, fism_daily_fuv_hr, fism_wv_fuv_hr, yr, doy, utc_fuv, $
        sigma_fism_ip_fuv_hr, sigma_fism_gp_fuv_hr, sigma_fism_pred_fuv_hr, $
        file='$fism_results' + '/flare_data/fuv_flare_hr/' +strmid(tmp_yd,5,4)+ '/fism_fuv_'+strmid(tmp_yd,5,7)+'_hr.sav'
  tmp_yd = get_next_yyyydoy(tmp_yd)
endwhile
if keyword_set(debug) then stop
print, 'End time create_fism_hr_fuv: ', !stime
end
