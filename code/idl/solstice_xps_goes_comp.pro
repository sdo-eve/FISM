;
; NAME: solstice_xps_goes_comp
;
; PURPOSE: 
;
; HISTORY:
;       VERSION 2_01
;
;
;
pro solstice_xps_goes_comp, debug=debug, res_data=res_data, plt_only=plt_only, $
                        res_noaa=res_noaa, st_wv=st_wv,end_wv=end_wv, no_ip_sub=no_ip_sub, $
                        zero_offset=zero_offset
                        
print, 'Running solstice_xps_goes_comp ', !stime
set_plot, 'Z'
if not keyword_set(st_wv) then st_wv=0.05
if not keyword_set(end_wv) then end_wv=39.95
if keyword_set(res_noaa) then goto, noaa_res
if keyword_set(plt_only) then goto, pltonly

; Use 2003 for processing if /yr is not specified in keywords
cur_utc=bin_date(systime(/utc))
cur_dy = get_current_yyyydoy()
cur_yr=fix(cur_dy/1000)

; Get GOES XRS 1-min data from FISM path (Should update to use GOES 3
; sec data)
;  NOTE: This is also ran under 'solstice_goes_comp.pro' for fuv
;    so may be able to just set keyword '/res_noaa'
;    Time is in GPS time
goes_flnm='$fism_data/lasp/goes_xrs/goes_1mdata_widx_2003.sav' ; Get first year to define arrays
restore, goes_flnm
dgoes_dt=(goes.long-shift(goes.long,1))/(goes.time-shift(goes.time,1))>0.0
goes_tm=goes.time
goes_long=goes.long
nyrs=cur_yr-2003
for k=2004,cur_yr-1 do begin
   if keyword_set(debug) then print, 'GOES Events '+strtrim(k,2)
  goes_flnm='$fism_data/lasp/goes_xrs/goes_1mdata_widx_'+strtrim(k,2)+'.sav' ; Get next years to concat arrays
  restore, goes_flnm
  goes_tm=[goes_tm,goes.time]   ; gps time
  goes_long=[goes_long,goes.long]
  dgoes_dt=[dgoes_dt,(goes.long-shift(goes.long,1))/(goes.time-shift(goes.time,1))]>0.0
endfor

; Restore the NOAA Event File savesets to get flare location
;  NOTE: This is also ran under 'solstice_goes_comp.pro' for fuv
;    so may be able to just set keyword '/res_noaa'
restore, '$fism/tmp/noaa_flr_data_2003.sav' ; Define arrays
ngevents=n_elements(noaa_flare_dat.yyyydoy)
fl_dist_noaa=fltarr(ngevents)
fl_dist_key=intarr(ngevents)
noaa_flare_dat_yyyydoy=noaa_flare_dat.yyyydoy
noaa_flare_dat_starttimes=noaa_flare_dat.strt_time
for g=0,ngevents-1 do begin
   ;print, string(g) + ' of ' + string(ngevents)
   fl_lat=fix(strmid(noaa_flare_dat[g].locat,1,2))
   fl_long=fix(strmid(noaa_flare_dat[g].locat,4,2))
   fl_dist_noaa[g]=sqrt(fl_lat^2.+fl_long^2.)
endfor
for k=2004,cur_yr do begin      ; Concat new years data
   ;print, k
   if keyword_set(debug) then print, 'NOAA Events '+strtrim(k,2)
   restore, '$fism/tmp/noaa_flr_data_'+strtrim(k,2)+'.sav'
   ngevents=n_elements(noaa_flare_dat.yyyydoy)
   for g=0,ngevents-1 do begin
      ;print, string(g) + ' of ' + string(ngevents)
      fl_lat=[fl_lat,fix(strmid(noaa_flare_dat[g].locat,1,2))]
      fl_long=[fl_long,fix(strmid(noaa_flare_dat[g].locat,4,2))]
      fl_dist_noaa=[fl_dist_noaa,sqrt(fl_lat^2.+fl_long^2.)]
   endfor
   noaa_flare_dat_yyyydoy=[noaa_flare_dat_yyyydoy,noaa_flare_dat.yyyydoy]
   noaa_flare_dat_starttimes=[noaa_flare_dat_starttimes,noaa_flare_dat.strt_time]
endfor

save, fl_dist_noaa, noaa_flare_dat_yyyydoy, goes_tm, goes_long, dgoes_dt, $
      noaa_flare_dat_starttimes, cur_yr, file='$src_sol/noaa_goes_fulltm.sav'

noaa_res:
if keyword_set(res_noaa) then begin
   restore, '$src_sol/noaa_goes_fulltm.sav'
   cur_dy = get_current_yyyydoy()
   cur_yr=fix(cur_dy/1000)
endif

; Restore the SORCE XPS 0.1 Full spectral data
;  http://lasp.colorado.edu/home/sorce/data/
;src_pth=getenv('fism_data')
;ss_files=findfile(src_pth+'/sorce_xps/sorce_xps*')
ss_files=findfile('$fism_data/lasp/sorce/sorce_xps/full/sorce_xps*')
n_ss_files=n_elements(ss_files)
; Concatenate files
read_netcdf, ss_files[0], src_xps

xps_sod=src_xps.time
xps_ydoy=src_xps.date
xps_wv=findgen(400)/10.+0.05
xps_irr=transpose(src_xps.modelflux)
for i=1,n_ss_files-1 do begin
   read_netcdf, ss_files[i], src_xps
   xps_sod=[xps_sod,src_xps.time]
   xps_ydoy=[xps_ydoy,src_xps.date]
   xps_irr=[xps_irr,transpose(src_xps.modelflux)]
endfor

; Restore the L3 daily average SORCE XPS merged data
;src_pth=getenv('fism_data')
read_netcdf, expand_path('$fism_data') + '/lasp/sorce/sorce_xps/sorce_xps_L4_c24h_r0.1nm_latest.ncdf', src_dy ; start with 2003

; Find cotemporal arrays of GOES and SORCE for each 0.1 wavelength bin
nxps=n_elements(xps_sod)
goes_long_src=fltarr(nxps)
dgoes_long_src=fltarr(nxps)
fl_dist_src=fltarr(nxps)
e_xps=fltarr(nxps,400)
fl_tmp_loc=45.

; Convert GOES GPS times
gps_to_utc, goes_tm, 13, gyyyy, gdoy, gutc, gmonth, gday, ghh, gmm, gss, /auto
gydoy=gyyyy*fix(1000,type=3)+gdoy

for j=0,nxps-1 do begin
      ;print, j, 'of', nxps
      ; Find the GOES value at the time of the SORCE XPS Observation
      wgoes=where(gydoy eq xps_ydoy[j] and gutc ge xps_sod[j]-90. and gutc lt xps_sod[j]+90.)
      if wgoes[0] ne -1 then begin
         if n_elements(wgoes) eq 1 then begin
            goes_long_src[j]=goes_long[wgoes[0]]
            dgoes_long_src[j]=dgoes_dt[wgoes[0]]
         endif else begin       ; more than one time found, so average goes
            goes_long_src[j]=mean(goes_long[wgoes])
            dgoes_long_src[j]=mean(dgoes_dt[wgoes])
         endelse
      endif
      ; Find the Flare location at the time of the SORCE Observation
      wfl_loc_dy=where(noaa_flare_dat_yyyydoy eq xps_ydoy[j])
      if wfl_loc_dy[0] ne -1 then begin
         wfl_loc_utc=where(noaa_flare_dat_starttimes[wfl_loc_dy] le xps_sod[j])
         if wfl_loc_utc[0] ne -1 then begin
            wfl_loc_valid=where(fl_dist_noaa[wfl_loc_dy[wfl_loc_utc]] gt 0. and fl_dist_noaa[wfl_loc_dy[wfl_loc_utc]] lt 200.)
            if wfl_loc_valid[0] ne -1 then begin 
               nval=n_elements(wfl_loc_valid)
               fl_tmp_loc=fl_dist_noaa[wfl_loc_dy[wfl_loc_utc[wfl_loc_valid[nval-1]]]] ; update to current good fl loctation
               ;if keyword_set(debug) then print, noaa_flare_dat[wfl_loc_dy[wfl_loc_utc[wfl_loc_valid[nval-1]]]].yyyydoy, ydoy_gd[j], fl_tmp_loc, $
               ;        noaa_flare_dat[wfl_loc_dy[wfl_loc_utc[wfl_loc_valid[nval-1]]]].strt_time, utc_gd[j]
            endif
         endif
      endif
      fl_dist_src[j]=fl_tmp_loc
      ;if keyword_set(debug) and ydoy_gd[j] eq 2003301 then stop

      ; Subtract of the daily XPS values
      wxps_daily=where(src_dy.date eq xps_ydoy[j])
      e_xps[j,*]=xps_irr[j,*]-src_dy[wxps_daily].modelflux
      
endfor

; Save the cotemporal GOES and XPS data
save, goes_long_src, dgoes_long_src, fl_dist_src, e_xps, xps_ydoy, xps_sod, $
      file='$fism_save/xps_goes_data.sav'

pltonly:
if keyword_set(plt_only) then restore, '$fism_save/xps_goes_data.sav'

linfit_coefs=fltarr(2,400) ;gp
sigma_linfit_coefs_gp=fltarr(2,400)
linfit_coefs_ip=fltarr(2,400)
sigma_linfit_coefs_ip=fltarr(2,400)
linfit_xlog_coefs_all=fltarr(2,400)
linfit_xlog_coefs_cent=fltarr(2,400)
linfit_xlog_coefs_mid=fltarr(2,400)
linfit_xlog_coefs_limb=fltarr(2,400)
linfit_coefs_limb_ip=fltarr(2,400)
sigma_linfit_coefs_limb_ip=fltarr(2,400)
linfit_coefs_mid_ip=fltarr(2,400)
sigma_linfit_coefs_mid_ip=fltarr(2,400)
linfit_coefs_cent_ip=fltarr(2,400)
sigma_linfit_coefs_cent_ip=fltarr(2,400)
linfit_coefs_limb=fltarr(2,400)
sigma_linfit_coefs_limb_gp=fltarr(2,400)
linfit_coefs_mid=fltarr(2,400)
sigma_linfit_coefs_mid_gp=fltarr(2,400)
linfit_coefs_cent=fltarr(2,400)
sigma_linfit_coefs_cent_gp=fltarr(2,400)
yer_gp=fltarr(400)
yer_gp_c=fltarr(400)
yer_gp_l=fltarr(400)
yer_gp_m=fltarr(400)
yer_ip=fltarr(400)
yer_ip_c=fltarr(400)
yer_ip_l=fltarr(400)
yer_ip_m=fltarr(400)

   ; Also save the maximum value measured for each wavelength
max_val=fltarr(400)

for i=0,399 do begin
   ; 
   ; Implusive Phase Linear fit - Find first to subtract off before
   ;    finding GP
   gd_src_goes_ip=where(dgoes_long_src gt 1.e-8 and e_xps[*,i] gt 0.0)
   ;ln_dgoes_long_src=alog(dgoes_long_src)
   ;ln_e_xps=alog(e_xps)

   ; All IP fit

   a_ip=poly_fit(dgoes_long_src[gd_src_goes_ip],e_xps[gd_src_goes_ip,i],1, sigma=sigma_all, status=status, $
                measure_errors=sqrt(abs(e_xps[gd_src_goes_ip,i])),yband=yband_all_ip, yfit=yf_a)
   ;a_ip=poly_fit(dgoes_long_src[gd_src_goes_ip],e_xps[gd_src_goes_ip,i],1, sigma=sigma_all, status=status, $
   ;             measure_errors=yband_all_ip,yband=yband_all_ip2)
   ;a_ip=poly_fit(ln_dgoes_long_src[gd_src_goes_ip],ln_e_xps[gd_src_goes_ip,i],1, sigma=sigma_all)
   ;a_ip[0]=exp(a_ip[0]) ; fit a is actually ln(a), so a=exp(ln(a))
   sigma_linfit_coefs_ip[*,i]=sigma_all ;[exp(sigma_all[0]),sigma_all[1]]
   ; Calculate the percent error
   mody=yf_a
   measy=e_xps[gd_src_goes_ip,i]
   gder=where((mody-measy)/measy lt 10.)
   perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
   yer_ip[i]=perirerr
 
   pltx_ip=findgen(1.d7)/1.e11
   plty_ip=a_ip[0]+a_ip[1]*pltx_ip; a_ip[0]*pltx_ip^a_ip[1]
   sigma_plty_ip=(sigma_all[0]+a_ip[0])+(sigma_all[1]+a_ip[1])*pltx_ip; a_ip[0]*pltx_ip^a_ip[1]

   ; Center IP fit

   wcent_ip=where(fl_dist_src[gd_src_goes_ip] lt 45)
   if wcent_ip[0] ne -1 then begin
      ;b_cent_ip=poly_fit(ln_dgoes_long_src[gd_src_goes_ip[wcent_ip]],ln_e_xps[gd_src_goes_ip[wcent_ip],i],1,sigma=sigma)
      b_cent_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wcent_ip]],e_xps[gd_src_goes_ip[wcent_ip],i],1,sigma=sigma, $
                         measure_errors=sqrt(abs(e_xps[gd_src_goes_ip[wcent_ip],i])),status=status, yband=yband_b_cent_ip, $
                        yfit=yf_c)
      ;b_cent_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wcent_ip]],e_xps[gd_src_goes_ip[wcent_ip],i],1,sigma=sigma, $
      ;                   measure_errors=yband_b_cent_ip,status=status)
      ;b_cent_ip[0]=exp(b_cent_ip[0]) ; fit a is actually ln(a), so a=exp(ln(a))
      sigma_linfit_coefs_cent_ip[*,i]=sigma ;[exp(sigma[0]),sigma[1]]
      ; Calculate the percent error
      mody=yf_c
      measy=e_xps[gd_src_goes_ip[wcent_ip],i]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_ip_c[i]=perirerr
   endif else begin
      b_cent_ip=a_ip
      sigma_linfit_coefs_cent_ip[*,i]=sigma_all ;[exp(sigma_all[0]),sigma_all[1]]
      yer_ip_c[i]=yer_ip[i]
   endelse

   ; Mid IP Fit

   wmid_ip=where(fl_dist_src[gd_src_goes_ip] ge 45 and fl_dist_src[gd_src_goes_ip] lt 75)
   if wmid_ip[0] ne -1 then begin
      ;b_mid_ip=poly_fit(ln_dgoes_long_src[gd_src_goes_ip[wmid_ip]],ln_e_xps[gd_src_goes_ip[wmid_ip],i],1,sigma=sigma)
      ;b_mid_ip[0]=exp(b_mid_ip[0]) ; fit a is actually ln(a), so a=exp(ln(a))
      b_mid_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wmid_ip]],e_xps[gd_src_goes_ip[wmid_ip],i],1,sigma=sigma, $
                        measure_errors=sqrt(abs(e_xps[gd_src_goes_ip[wmid_ip],i])), status=status, yband=yband_b_mid_ip, $
                       yfit=yf_m)
      ;b_mid_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wmid_ip]],e_xps[gd_src_goes_ip[wmid_ip],i],1,sigma=sigma, $
      ;                  measure_errors=yband_b_mid_ip, status=status)
      sigma_linfit_coefs_mid_ip[*,i]=sigma ;[exp(sigma[0]),sigma[1]]
      ; Calculate the percent error
      mody=yf_m
      measy=e_xps[gd_src_goes_ip[wmid_ip],i]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_ip_m[i]=perirerr
   endif else begin
      b_mid_ip=a_ip
      sigma_linfit_coefs_mid_ip[*,i]=sigma_all ;[exp(sigma_all[0]),sigma_all[1]]
      yer_ip_m[i]=yer_ip[i]
   endelse

   ; Limb IP Fit

   wlimb_ip=where(fl_dist_src[gd_src_goes_ip] ge 75)
   if wlimb_ip[0] ne -1 then begin
      ;b_limb_ip=poly_fit(ln_dgoes_long_src[gd_src_goes_ip[wlimb_ip]],ln_e_xps[gd_src_goes_ip[wlimb_ip],i],1,sigma=sigma)
      ;b_limb_ip[0]=exp(b_limb_ip[0]) ; fit a is actually ln(a), so a=exp(ln(a))
      b_limb_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wlimb_ip]],e_xps[gd_src_goes_ip[wlimb_ip],i],1,sigma=sigma, $
                         measure_errors=sqrt(abs(e_xps[gd_src_goes_ip[wlimb_ip],i])), status=status, yband=yband_b_limb_ip, $
                        yfit=yf_l)
      ;b_limb_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wlimb_ip]],e_xps[gd_src_goes_ip[wlimb_ip],i],1,sigma=sigma, $
      ;                   measure_errors=yband_b_limb_ip, status=status, yband=yband_b_limb_ip2)
      sigma_linfit_coefs_limb_ip[*,i]=sigma ;[exp(sigma[0]),sigma[1]]
      ; Calculate the percent error
      mody=yf_l
      measy=e_xps[gd_src_goes_ip[wlimb_ip],i]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_ip_l[i]=perirerr
   endif else begin
      b_limb_ip=a_ip
      sigma_linfit_coefs_limb_ip[*,i]=sigma_all ;[exp(sigma_all[0]),sigma_all[1]]
      yer_ip_l[i]=yer_ip[i]
   endelse
   
      
   ; Make sure mid and limb are not greater than center 
   if b_mid_ip[1] gt b_cent_ip[1] then b_mid_ip=b_cent_ip
   if b_limb_ip[1] gt b_cent_ip[1] then b_limb_ip=b_cent_ip
   ; If both mid and limb are greater than center, force all of 
   ;   the fits to be the 'all' fit
   if b_limb_ip[1] ge b_cent_ip[1] and b_mid_ip[1] ge b_cent_ip[1] then begin
      b_limb_ip=a_ip
      b_mid_ip=a_ip
      b_cent_ip=a_ip
      yer_ip_l[i]=yer_ip[i]
      yer_ip_c[i]=yer_ip[i]
      yer_ip_m[i]=yer_ip[i]
   endif
   

   if keyword_set(debug) then begin
      window,0
      cc=independent_color()
      plty_b_ip_cent=b_cent_ip[0]+pltx_ip*b_cent_ip[1]
      plty_b_ip_mid=b_mid_ip[0]+pltx_ip*b_mid_ip[1]
      plty_b_ip_limb=b_limb_ip[0]+pltx_ip*b_limb_ip[1]

      plot, dgoes_long_src,e_xps[*,i], /xlog, psym=4, title=strtrim(i/10.,2)+'nm', charsize=1.5, $
            xtitle='dGOES XRS-B/dt', ytitle='SORCE XPS', symsize=2, thick=2, xr=[1e-11,1e-4], /ylog
      oplot, dgoes_long_src[gd_src_goes_ip[wcent_ip]],e_xps[gd_src_goes_ip[wcent_ip],i], psym=4, $
            color=cc.green, symsize=2, thick=2
      oplot, dgoes_long_src[gd_src_goes_ip[wmid_ip]],e_xps[gd_src_goes_ip[wmid_ip],i], psym=4, color=cc.light_blue, $
            symsize=2, thick=2
      oplot, dgoes_long_src[gd_src_goes_ip[wlimb_ip]],e_xps[gd_src_goes_ip[wlimb_ip],i], psym=4, color=cc.orange, $
            symsize=2, thick=2
      oplot, pltx_ip, plty_ip, thick=2, color=cc.red
      ;oplot, pltx_ip, sigma_plty_ip, thick=2, color=cc.red, linestyle=1
      oplot, pltx_ip, plty_ip*(1+yer_ip[i]), thick=2, color=cc.red, linestyle=1
      if a_ip[1] gt 0.0 then oplot, pltx_ip, plty_ip, thick=3, color=cc.blue
      if b_cent_ip[1] gt 0.0 then oplot, pltx_ip, plty_b_ip_cent, thick=2, color=cc.green
      if b_cent_ip[1] gt 0.0 then oplot, pltx_ip, plty_b_ip_cent*(1+yer_ip_c[i]), thick=2, color=cc.green, linestyle=1
      if b_mid_ip[1] gt 0.0 then oplot, pltx_ip, plty_b_ip_mid, thick=2, color=cc.light_blue
      if b_limb_ip[1] gt 0.0 then oplot, pltx_ip, plty_b_ip_limb, thick=2, color=cc.orange
      xyouts, 0.2, 0.9, 'Blue: All', color=cc.blue, /normal, charsize=1.5
      xyouts, 0.2, 0.85, 'Green: Center', color=cc.green, /normal, charsize=1.5
      xyouts, 0.2, 0.8, 'Light_Blue: Mid', color=cc.light_blue, /normal, charsize=1.5
      xyouts, 0.2, 0.75, 'Orange: Limb', color=cc.orange, /normal, charsize=1.5
   endif
   
   ; 
   ; Gradual Phase Linear fit - First to subtract off IP before
   ;    finding GP unless keyword /no_ip_sub is set

   ; Subtract of IP results
   cent_ip=b_cent_ip[0]+dgoes_long_src*b_cent_ip[1]
   mid_ip=b_mid_ip[0]+dgoes_long_src*b_mid_ip[1]
   limb_ip=b_limb_ip[0]+dgoes_long_src*b_limb_ip[1]

   wlimb=where(fl_dist_src ge 75)
   wmid=where(fl_dist_src ge 45 and fl_dist_src lt 75)
   wcent=where(fl_dist_src lt 45)
   if not keyword_set(no_ip_sub) then begin
      e_xps[wlimb,i]=e_xps[wlimb,i]-limb_ip[wlimb]
      e_xps[wcent,i]=e_xps[wcent,i]-cent_ip[wcent]
      e_xps[wmid,i]=e_xps[wmid,i]-mid_ip[wmid]
   endif
   
   gd_src_goes=where(goes_long_src gt 1.e-5 and e_xps[*,i] gt 0.0)   ; and src_ir gt 0.0 and goes_long_src gt 1.e-5)
   mes_er=sqrt(abs(e_xps))
   ;for m=0,n_elements(gd_src_goes)-1 then begin

   ; All GP Fit

   a=poly_fit(goes_long_src[gd_src_goes],e_xps[gd_src_goes,i],1,sigma=sigma_all,chisq=chisq, $
             measure_errors=mes_er[gd_src_goes,i], status=status, yband=yband_a_init, yfit=yf_a)
   ;a=poly_fit(goes_long_src[gd_src_goes],e_xps[gd_src_goes,i],1,sigma=sigma_all,chisq=chisq, $
   ;          measure_errors=yband_a_init, status=status)
   sigma_linfit_coefs_gp[*,i]=sigma_all
   ; Calculate the percent error
   mody=yf_a
   measy=e_xps[gd_src_goes,i]
   gder=where((mody-measy)/measy lt 10.)
   perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
   yer_gp[i]=perirerr
 
   pltx=findgen(1.e5)/1.e7
   if keyword_set(zero_offset) then plty=a[0]+a[1]*pltx else plty=a[1]*pltx
   ;b=poly_fit(alog10(goes_long_src[gd_src_goes]),e_xps[gd_src_goes,i],1)

   ; Cent GP Fit

   wcent=where(fl_dist_src[gd_src_goes] lt 45)
   if wcent[0] ne -1 then begin
      ;b_cent=poly_fit(alog10(goes_long_src[gd_src_goes[wcent]]),e_xps[gd_src_goes[wcent],i],1)
      a_cent=poly_fit(goes_long_src[gd_src_goes[wcent]],e_xps[gd_src_goes[wcent],i],1,sigma=sigma, $
             measure_errors=mes_er[gd_src_goes[wcent],i], status=status, yband=yband_a_cent, yfit=yf_c)
      ;a_cent=poly_fit(goes_long_src[gd_src_goes[wcent]],e_xps[gd_src_goes[wcent],i],1,sigma=sigma, $
      ;       measure_errors=yband_a_cent, status=status)
      sigma_linfit_coefs_cent_gp[*,i]=sigma
      ; Calculate the percent error
      mody=yf_c
      measy=e_xps[gd_src_goes[wcent],i]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_gp_c[i]=perirerr
   endif else begin
      ;b_cent=b
      a_cent=a
      sigma_linfit_coefs_cent_gp[*,i]=sigma_all
      yer_gp_c[i]=yer_gp[i]
   endelse

   ; Mid GP Fit

   wmid=where(fl_dist_src[gd_src_goes] ge 45 and fl_dist_src[gd_src_goes] lt 75)
   if wmid[0] ne -1 then begin
      ;b_mid=poly_fit(alog10(goes_long_src[gd_src_goes[wmid]]),e_xps[gd_src_goes[wmid],i],1)
      a_mid=poly_fit(goes_long_src[gd_src_goes[wmid]],e_xps[gd_src_goes[wmid],i],1,sigma=sigma, $
             measure_errors=mes_er[gd_src_goes[wmid],i], status=status, yband=yband_a_mid, yfit=yf_m)
      ;a_mid=poly_fit(goes_long_src[gd_src_goes[wmid]],e_xps[gd_src_goes[wmid],i],1,sigma=sigma, $
      ;       measure_errors=yband_a_mid, status=status)
      sigma_linfit_coefs_mid_gp[*,i]=sigma
      ; Calculate the percent error
      mody=yf_m
      measy=e_xps[gd_src_goes[wmid],i]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_gp_m[i]=perirerr
   endif else begin
      ;b_mid=b
      a_mid=a
      sigma_linfit_coefs_mid_gp[*,i]=sigma_all
      yer_gp_m[i]=yer_gp[i]
   endelse

   ; Limb GP Fit

   wlimb=where(fl_dist_src[gd_src_goes] ge 75)
   if wlimb[0] ne -1 then begin
      ;b_limb=poly_fit(alog10(goes_long_src[gd_src_goes[wlimb]]),e_xps[gd_src_goes[wlimb],i],1)
      a_limb=poly_fit(goes_long_src[gd_src_goes[wlimb]],e_xps[gd_src_goes[wlimb],i],1,sigma=sigma, $
             measure_errors=mes_er[gd_src_goes[wlimb],i], status=status, yband=yband_a_limb, yfit=yf_l)
      ;a_limb=poly_fit(goes_long_src[gd_src_goes[wlimb]],e_xps[gd_src_goes[wlimb],i],1,sigma=sigma, $
      ;       measure_errors=yband_a_limb, status=status)
      sigma_linfit_coefs_limb_gp[*,i]=sigma
      ; Calculate the percent error
      mody=yf_l
      measy=e_xps[gd_src_goes[wlimb],i]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_gp_l[i]=perirerr
   endif else begin
     ; b_limb=b
      a_limb=a
      sigma_linfit_coefs_limb_gp[*,i]=sigma_all
      yer_gp_l[i]=yer_gp[i]
   endelse

   ; Make sure mid and limb are not greater than center 
   ;if b_mid[1] gt b_cent[1] then begin
   ;   b_mid=b_cent
   ;   sigma_linfit_coefs_mid_gp[*,i]=sigma_linfit_coefs_cent_gp[*,i]
   ;endif
   ;if b_limb[1] gt b_cent[1] then begin
   ;   b_limb=b_cent
   ;   sigma_linfit_coefs_limb_gp[*,i]=sigma_linfit_coefs_cent_gp[*,i]
   ;endif
   if a_mid[1] gt a_cent[1] then begin
      a_mid=a_cent
      sigma_linfit_coefs_mid_gp[*,i]=sigma_linfit_coefs_cent_gp[*,i]
      yer_gp_m[i]=yer_gp_c[i]
   endif
   if a_limb[1] gt a_cent[1] then begin
      a_limb=a_cent
      sigma_linfit_coefs_limb_gp[*,i]=sigma_linfit_coefs_cent_gp[*,i]
      yer_gp_l[i]=yer_gp_c[i]
   endif
   ; If both mid and limb are greater than center, force all of 
   ;   the fits to be the 'all' fit
   ;if b_limb[1] ge b_cent[1] and b_mid[1] ge b_cent[1] then begin
   ;   b_limb=b
   ;   b_mid=b
   ;   b_cent=b
   ;endif
   if a_limb[1] ge a_cent[1] and a_mid[1] ge a_cent[1] then begin
      a_limb=a
      sigma_linfit_coefs_limb_gp[*,i]=sigma_linfit_coefs_gp[*,i]
      yer_gp_l[i]=yer_gp[i]
      a_mid=a
      sigma_linfit_coefs_mid_gp[*,i]=sigma_linfit_coefs_gp[*,i]
      yer_gp_m[i]=yer_gp[i]
      a_cent=a
      sigma_linfit_coefs_cent_gp[*,i]=sigma_linfit_coefs_gp[*,i]
      yer_gp_c[i]=yer_gp[i]
   endif

   if keyword_set(debug) then begin
      pltx=findgen(1.d6)/1.e7
      if keyword_set(zero_offset) then begin
         plty=a[0]+a[1]*pltx
         ;splty=sigma_all[0]+a[0]+(sigma_all[1]+a[1])*pltx
         splty=plty*(1+yer_gp[i])
         ;plty_b=b[0]+(b[1]*alog10(pltx))
         plty_a_cent=a_cent[0]+(a_cent[1]*pltx)
         splty_cent=plty_a_cent*(1+yer_gp_c[i])
         plty_a_mid=a_mid[0]+(a_mid[1]*pltx)
         plty_a_limb=a_limb[0]+(a_limb[1]*pltx)
         ;plty_b_cent=b_cent[0]+(b_cent[1]*alog10(pltx))
         ;plty_b_mid=b_mid[0]+(b_mid[1]*alog10(pltx))
         ;plty_b_limb=b_limb[0]+(b_limb[1]*alog10(pltx))
      endif else begin
         plty=a[1]*pltx
         ;splty=(sigma_all[1]+a[1])*pltx
         splty=plty*(1+yer_gp[i])
         ;plty_b=b[1]*alog10(pltx)
         plty_a_cent=a_cent[1]*pltx
         splty_cent=plty_a_cent*(1+yer_gp_c[i])
         plty_a_mid=a_mid[1]*pltx
         plty_a_limb=a_limb[1]*pltx
         ;plty_b_cent=b_cent[1]*alog10(pltx)
         ;plty_b_mid=b_mid[1]*alog10(pltx)
         ;plty_b_limb=b_limb[1]*alog10(pltx)
      endelse      
      cc=independent_color()
      window,1
      plot, goes_long_src,e_xps[*,i], /xlog, psym=4, title=strtrim(i/10.,2)+'nm', charsize=1.5, $
            xtitle='GOES XRS-B', ytitle='SORCE XPS', symsize=2, thick=2, xr=[1e-8,1e-2], /ylog, ys=1
      oplot, goes_long_src[gd_src_goes],e_xps[gd_src_goes,i], psym=4, $
            color=cc.red, symsize=2, thick=2
      oplot, goes_long_src[gd_src_goes[wcent]],e_xps[gd_src_goes[wcent],i], psym=4, $
            color=cc.green, symsize=2, thick=2
      oplot, goes_long_src[gd_src_goes[wmid]],e_xps[gd_src_goes[wmid],i], psym=4, color=cc.light_blue, $
            symsize=2, thick=2
      oplot, goes_long_src[gd_src_goes[wlimb]],e_xps[gd_src_goes[wlimb],i], psym=4, color=cc.orange, $
            symsize=2, thick=2
      oplot, pltx, plty, thick=2, color=cc.red
      oplot, pltx, splty, thick=2, color=cc.red, linestyle=1
      ;if b[1] gt 0.0 then oplot, pltx, plty_b, thick=2, color=cc.blue, linestyle=2
      ;if b_cent[1] gt 0.0 then oplot, pltx, plty_b_cent, thick=2, color=cc.green, linestyle=2
      ;if b_mid[1] gt 0.0 then oplot, pltx, plty_b_mid, thick=2, color=cc.light_blue, linestyle=2
      ;if b_limb[1] gt 0.0 then oplot, pltx, plty_b_limb, thick=2, color=cc.orange, linestyle=2
      if a[1] gt 0.0 then oplot, pltx, plty, thick=2, color=cc.blue
      if a_cent[1] gt 0.0 then oplot, pltx, plty_a_cent, thick=2, color=cc.green
      if a_cent[1] gt 0.0 then oplot, pltx, splty_cent, thick=2, color=cc.green, linestyle=1
      if a_mid[1] gt 0.0 then oplot, pltx, plty_a_mid, thick=2, color=cc.light_blue
      if a_limb[1] gt 0.0 then oplot, pltx, plty_a_limb, thick=2, color=cc.orange
      xyouts, 0.8, 0.4, 'Blue: All', color=cc.blue, /normal, charsize=1.5
      xyouts, 0.8, 0.35, 'Green: Center', color=cc.green, /normal, charsize=1.5
      xyouts, 0.8, 0.3, 'Light_Blue: Mid', color=cc.light_blue, /normal, charsize=1.5
      xyouts, 0.8, 0.25, 'Orange: Limb', color=cc.orange, /normal, charsize=1.5
      ;xyouts, 0.8, 0.7, 'Solid: GOES, Dashed: log(GOES)', /normal, charsize=1.5

      ans=''
      ;read, ans, prompt='Next Wavelength? '
   endif
      
   wv=i
   linfit_coefs[*,i]=a
   linfit_coefs_ip[*,i]=a_ip
   ;linfit_xlog_coefs_all[*,i]=b
   ;linfit_xlog_coefs_cent[*,i]=b_cent
   ;linfit_xlog_coefs_mid[*,i]=b_mid
   ;linfit_xlog_coefs_limb[*,i]=b_limb
   ;linfit_coefs_limb_ip[*,i]=b_limb_ip
   ;linfit_coefs_mid_ip[*,i]=b_mid_ip
   ;linfit_coefs_cent_ip[*,i]=b_cent_ip
   linfit_coefs_limb[*,i]=a_limb
   linfit_coefs_mid[*,i]=a_mid
   linfit_coefs_cent[*,i]=a_cent

   ; Also save the maximum value measured for each wavelength
   max_val[i]=max(e_xps[gd_src_goes,i])
   

   if keyword_set(debug) then stop
endfor
FILE_MKDIR, expand_path('$fism_data') + '/lasp/sorce/sorce_xps/hr_goes_xps_wv'
save, goes_long_src, e_xps, xps_ydoy, xps_sod, wv, linfit_coefs, fl_dist_src, $ ;, linfit_xlog_coefs_all
      max_val, $ ;linfit_xlog_coefs_cent, linfit_xlog_coefs_mid, linfit_xlog_coefs_limb, 
      linfit_coefs_ip, dgoes_long_src, linfit_coefs_limb_ip, linfit_coefs_cent_ip, $
      linfit_coefs_mid_ip, linfit_coefs_cent, linfit_coefs_mid, linfit_coefs_limb, $
      sigma_linfit_coefs_limb_ip, sigma_linfit_coefs_limb_gp, sigma_linfit_coefs_mid_ip, $
      sigma_linfit_coefs_mid_gp, sigma_linfit_coefs_cent_ip, sigma_linfit_coefs_cent_gp, $
      sigma_linfit_coefs_ip, sigma_linfit_coefs_gp, yer_gp, yer_gp_l, yer_gp_c, yer_gp_m, $
      yer_ip, yer_ip_c, yer_ip_l, yer_ip_m, $
      file=expand_path('$fism_data') + '/lasp/sorce/sorce_xps/hr_goes_xps_wv/hr_goes_xps_comp.sav'
print, 'End time solstice_xps_goes_comp: ', !stime
end

