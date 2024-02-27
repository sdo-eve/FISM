;
; NAME: solstice_goes_comp
;
; PURPOSE: 
;
; HISTORY:
;       VERSION 2_01
;
;
;
pro solstice_goes_comp, debug=debug, res_data=res_data, plt_only=plt_only, $
                        res_noaa=res_noaa, st_wv=st_wv,end_wv=end_wv, no_ip_sub=no_ip_sub, $
                        zero_offset=zero_offset, binsize=binsize, process_wv=process_wv
if not keyword_set(process_wv) then print, 'Running solstice_goes_comp ', !stime

if not keyword_set(st_wv) then st_wv=115.00
if not keyword_set(end_wv) then end_wv=190.0
if not keyword_set(binsize) then binsize=0.03
if keyword_set(plt_only) or keyword_set(process_wv) then goto, pltonly
if keyword_set(res_noaa) then goto, noaa_res
set_plot, 'Z'
; Use 2003 for processing if /yr is not specified in keywords
cur_utc=bin_date(systime(/utc))
cur_dy = get_current_yyyydoy()
cur_yr=fix(cur_dy/1000)

; Get GOES XRS 1-min data from FISM path (Should update to use GOES 3
; sec data)
;    Time is in GPS time
goes_flnm='$fism_data/lasp/goes_xrs/goes_1mdata_widx_2003.sav' ; Get first year to define arrays
restore, goes_flnm
dgoes_dt=(goes.long-shift(goes.long,1))/(goes.time-shift(goes.time,1))>0.0
goes_tm=goes.time
goes_long=goes.long
nyrs=cur_yr-2003
for k=2004,cur_yr do begin
   if keyword_set(debug) then print, 'GOES Events '+strtrim(k,2)
  goes_flnm='$fism_data/lasp/goes_xrs/goes_1mdata_widx_'+strtrim(k,2)+'.sav' ; Get next years to concat arrays
  restore, goes_flnm
  goes_tm=[goes_tm,goes.time]   ; gps time
  goes_long=[goes_long,goes.long]
  dgoes_dt=[dgoes_dt,(goes.long-shift(goes.long,1))/(goes.time-shift(goes.time,1))]>0.0
endfor

; Restore the NOAA Event File savesets to get flare location
restore, '$fism/tmp/noaa_flr_data_2003.sav' ; Define arrays
ngevents=n_elements(noaa_flare_dat.yyyydoy)
fl_dist_noaa=fltarr(ngevents)
fl_dist_key=intarr(ngevents)
noaa_flare_dat_yyyydoy=noaa_flare_dat.yyyydoy
noaa_flare_dat_starttimes=noaa_flare_dat.strt_time
for g=0,ngevents-1 do begin
   ;print, strmid(noaa_flare_dat[g].locat,1,2)
   fl_lat=uint(strmid(noaa_flare_dat[g].locat,1,2))
   fl_long=uint(strmid(noaa_flare_dat[g].locat,4,2))
   fl_dist_noaa[g]=sqrt(fl_lat^2.+fl_long^2.)
endfor
for k=2004,cur_yr do begin      ; Concat new years data
   if keyword_set(debug) then print, 'NOAA Events '+strtrim(k,2)
   restore, '$fism/tmp/noaa_flr_data_'+strtrim(k,2)+'.sav'
   ngevents=n_elements(noaa_flare_dat.yyyydoy)
   for g=0,ngevents-1 do begin
      ;print, string(g) + 'of' + string(ngevents)
      fl_lat=[fl_lat,fix(strmid(noaa_flare_dat[g].locat,1,2))]
      fl_long=[fl_long,fix(strmid(noaa_flare_dat[g].locat,4,2))]
      fl_dist_noaa=[fl_dist_noaa,sqrt(fl_lat^2.+fl_long^2.)]
   endfor
   noaa_flare_dat_yyyydoy=[noaa_flare_dat_yyyydoy,noaa_flare_dat.yyyydoy]
   noaa_flare_dat_starttimes=[noaa_flare_dat_starttimes,noaa_flare_dat.strt_time]
endfor
save, fl_dist_noaa, noaa_flare_dat_yyyydoy, goes_tm, goes_long, dgoes_dt, $
      noaa_flare_dat_starttimes, cur_yr, file=expand_path('$tmp_dir') +'/noaa_goes_fulltm.sav'

noaa_res:
if keyword_set(res_noaa) then begin
   restore, expand_path('$tmp_dir') + '/noaa_goes_fulltm.sav'
   cur_dy = get_current_yyyydoy()
   cur_yr=fix(cur_dy/1000)
endif

; Restore the SORCE SOLSTICE Full spectral and temproal calibrated
; data - recieved via private communication w/Marty Snow, LASP
ss_files=findfile('$src_sol_data/')
n_ss_files=n_elements(ss_files)
; Concatenate files
restore, '$src_sol_data/'+ss_files[0]
solstice_fuv_microsec=solstice_fuv.microsecondssincegpsepoch
solstice_fuv_wavelength=solstice_fuv.wavelength
solstice_fuv_irradiance=solstice_fuv.irradiance
if keyword_set(debug) then begin
   plot, solstice_fuv.wavelength, ph2watt(solstice_fuv.wavelength,solstice_fuv.irradiance), /ylog, $
         yr=[1e-5,1e-2], xr=[st_wv-0.5,st_wv+0.5], psym=1 ; xr=[139.1,139.6]
;   cc=rainbow(n_ss_files)
endif
for i=1,n_ss_files-1 do begin
   restore, '$src_sol_data/'+ss_files[i]
   solstice_fuv_microsec=[solstice_fuv_microsec,solstice_fuv.microsecondssincegpsepoch]
   solstice_fuv_wavelength=[solstice_fuv_wavelength,solstice_fuv.wavelength]
   solstice_fuv_irradiance=[solstice_fuv_irradiance,solstice_fuv.irradiance]
   if keyword_set(debug) then begin
      oplot, solstice_fuv.wavelength, ph2watt(solstice_fuv.wavelength,solstice_fuv.irradiance), psym=1;, color=cc[i-1]
   endif
endfor
; Some are out of order (?Bad time stamp?)
srt_ss=sort(solstice_fuv_microsec)
solstice_fuv_microsec=solstice_fuv_microsec(srt_ss)
solstice_fuv_wavelength=solstice_fuv_wavelength(srt_ss)
solstice_fuv_irradiance=solstice_fuv_irradiance(srt_ss)

; Convert solstice time to utc
gps_to_utc, solstice_fuv_microsec/1d6, 13, yyyy, doy, utc, month, day, hh, mm, ss, auto=1, julian=jd
ydoy=yyyy*fix(1000,type=3)+doy

; Restore the L3 daily average SORCE SOLSTICE data
;src_pth=getenv('fism_data')
read_netcdf, expand_path('$fism_data') + '/lasp/sorce/solstice_daily/SORCE_SOLSTICE_L3_HR_V15_2003.nc', src_l3 ; start with 2003
src_l3_nominal_date_jd=src_l3.nominal_date_jd
src_l3_standard_wavelengths=src_l3.standard_wavelengths
src_l3_irradiance=transpose(src_l3.irradiance)
for k=2004,2017 do begin      ; Concat new years data (only have up to 2017 for now)
   read_netcdf, expand_path('$fism_data') +'/lasp/sorce/solstice_daily/SORCE_SOLSTICE_L3_HR_V15_'+strtrim(k,2)+'.nc', src_l3 
   src_l3_nominal_date_jd=[src_l3_nominal_date_jd,src_l3.nominal_date_jd]
   ;src_l3_standard_wavelengths=[src_l3_standard_wavelengths,src_l3.standard_wavelengths]
   src_l3_irradiance=[src_l3_irradiance,transpose(src_l3.irradiance)]
endfor
src_l3_irradiance=transpose(src_l3_irradiance)
if keyword_set(debug) then begin
   cc=independent_color()
   oplot, src_l3_standard_wavelengths, src_l3_irradiance[*,100], color=cc.red
endif
;
; Find cotemporal arrays of GOES and SORCE for each wavelength bin
;

; Find number of wavelength bins
nwv_bins=fix((end_wv-st_wv)/binsize)
for m=0,nwv_bins do begin     
   i=(m*binsize)+st_wv
   ; with ~0.085 bandpass, only use data with nominal wavelengths
   ;   within +/- 0.015 of center, fine with ~0.035 nm steps
   gd_src=where(solstice_fuv_wavelength ge i-0.015 and solstice_fuv_wavelength lt i+0.015 and $
               solstice_fuv_irradiance gt 0.0)
   ngd=n_elements(gd_src)
   ydoy_gd=ydoy[gd_src]
   utc_gd=utc[gd_src]
   ; Find l3 daily value and subtract off for each data point
   src_ir=solstice_fuv_irradiance[gd_src]
   src_ir_orig=solstice_fuv_irradiance[gd_src]
   src_ir_daily=solstice_fuv_irradiance[gd_src]
   for k=0,ngd-1 do begin
      gd_dy=where(src_l3_nominal_date_jd eq jd[gd_src[k]]-0.5); ge jd[gd_src[k]]-0.5 and src_l3_nominal_date_jd lt jd[gd_src[k]]+0.5)
      gd_l3_src_wv=where(src_l3_standard_wavelengths ge i-0.07 and src_l3_standard_wavelengths lt i+0.07)
      if n_elements(gd_l3_src_wv) le 3 then begin
         gd_l3_src_wv=where(src_l3_standard_wavelengths ge i-0.14 and src_l3_standard_wavelengths lt i+0.14)
      endif
      src_interp=interpol(src_l3_irradiance[gd_l3_src_wv,gd_dy[0]],src_l3_standard_wavelengths[gd_l3_src_wv],$
                          solstice_fuv_wavelength[gd_src[k]],/spline)
      ;if (ph2watt(i,src_ir[k])-src_interp) gt 0.0002 then stop
      src_ir[k]=(ph2watt(i,src_ir[k])-src_interp);>0.0
      src_ir_orig[k]=(ph2watt(i,src_ir_orig[k])) ;>0.0
      src_ir_daily[k]=src_interp
   endfor
   src_gps=solstice_fuv_microsec[gd_src]
   goes_long_src=fltarr(ngd)
   dgoes_long_src=fltarr(ngd)
   fl_dist_src=fltarr(ngd)
   fl_tmp_loc=45.
   for j=0,ngd-1 do begin
      ; Find the GOES value at the time of the SORCE SOLSTICE Observation
      wgoes=where(goes_tm ge src_gps[j]/1d6-30 and goes_tm lt src_gps[j]/1d6+30)
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
      wfl_loc_dy=where(noaa_flare_dat_yyyydoy eq ydoy_gd[j])
      if wfl_loc_dy[0] ne -1 then begin
         wfl_loc_utc=where(noaa_flare_dat_starttimes[wfl_loc_dy] le utc_gd[j])
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
   endfor

   pltonly:
   if keyword_set(plt_only) or keyword_set(process_wv) then begin
      wv=0.0
      if not keyword_set(process_wv) then debug=1
      if not keyword_set(process_wv) then read, wv, prompt='Enter Wavelength (nm, must be multiple of 0.03): ' $
         else wv=process_wv
      i=wv
      bd_wv_fl:
      resfl='$fism_data/lasp/sorce/solstice_daily/hr_goes_sols_wv/hr_goes_sol_comp_'+strmid(strtrim(wv,2),0,6)+'nm.sav'
      gdresfl=findfile(resfl)
      if strlen(gdresfl) eq 0 then begin
         wv=wv+0.01
         if wv gt i+2 then begin
            print, 'No valid sol/xps comparison files, need to abort'
         endif         
         goto, bd_wv_fl
      endif
      i=wv
      
      ;stop
      restore, resfl
   endif

   src_ir=src_ir_orig-smooth(src_ir_orig,120)

   ; Set the maximum st. dev. percentage for a valid IP fit
   mx_std_per=2000. ; 1000% is a factor of 10
   
   ; 
   ; Implusive Phase Linear fit - Find first so can subtract off before
   ;    finding GP if not keyword_set(no_ip_sub)
   ; higher GOES cutoff for range where high frequency scans as it observed higher flares
      ; observed a lot more non-flares
   if i ge 120.4 and i le 129.0 then begin 
      gd_src_goes_ip=where(dgoes_long_src gt 3.e-9 and dgoes_long_src lt 1.e-5 and src_ir gt 0.0) ; and goes_long_src gt 1.e-5)
   endif else begin
      gd_src_goes_ip=where(dgoes_long_src gt 1.e-10 and dgoes_long_src lt 1.e-5 and src_ir gt 0.0) ; and goes_long_src gt 1.e-5)
   endelse
   
   ; Linear Fit
   a_ip=poly_fit(dgoes_long_src[gd_src_goes_ip],src_ir[gd_src_goes_ip],1,sigma=sigma_a_ip,measure_errors=sqrt(abs(src_ir[gd_src_goes_ip])), $
                      yband=yband_ip, yfit=yfit_ip, status=status)
   ; re-fit with standard deviations of each point to the fit
   ;a_ip=poly_fit(dgoes_long_src[gd_src_goes_ip],src_ir[gd_src_goes_ip],1,sigma=sigma_a_ip,measure_errors=yband_ip, $
   ;              yband=yband_ip2, yfit=yfit_ip, status=status)
   ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
   ;  it is a bad fit and there is no real IP
   ip_x1=1.e-7*a_ip[1]; +a_ip[0]
   sig_ip_x1=1.e-6*sigma_a_ip[1] ; +sigma_a_ip[0]
   ; Calculate the percent error
   mody=yfit_ip
   measy=src_ir[gd_src_goes_ip]
   gder=where((mody-measy)/measy lt 10.)
   perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
   yer_ip=perirerr

   onesig_per=yer_ip*100.;(sig_ip_x1/ip_x1)*100.
   if keyword_set(debug) then print, onesig_per, ' IP'
   if a_ip[1] lt 0.0 or onesig_per gt mx_std_per then begin ; if slope is negative or to high of st. dev.
      a_ip[*]=0.0
      sigma_a_ip[0]=0.0
      yer_ip=0.0
   endif
   ; Log Fit
   ;lna_ip_init=poly_fit(alog(dgoes_long_src[gd_src_goes_ip]),alog(src_ir[gd_src_goes_ip]),1,sigma=lnsigma_a_ip_init,$
   ;                     measure_errors=sqrt(abs(alog(src_ir[gd_src_goes_ip]))), $
   ;                   yband=lnyband_ip, yfit=lnyfit_ip, status=status)
   ; re-fit with standard deviations of each point to the fit
   ;lna_ip=poly_fit(alog(dgoes_long_src[gd_src_goes_ip]),alog(src_ir[gd_src_goes_ip]),1,sigma=lnsigma_a_ip,measure_errors=lnyband_ip, $
   ;                yband=lnyband_ip2, yfit=lnyfit_ip, status=status)
   ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
   ;  it is a bad fit and there is no real IP
   ;lnip_x1=exp(lna_ip[0])*(1.e-6^lna_ip[1])
   ;lnsig_ip_x1=exp(lnsigma_a_ip[0]+lna_ip[0])+1.e-6*(lnsigma_a_ip[1]+lna_ip[1])
   ;lnonesig_per=(lnsig_ip_x1-lnip_x1)/lnip_x1*100.
   ;if lna_ip[1] lt 0.0 or lnonesig_per gt mx_std_per then begin
   ;   lna_ip[*]=0.0
   ;   lnsigma_a_ip[*]=0.0
   ;endif

   ; Set up the plot x-axis
   pltx_ip=findgen(1.d7)/1.e12
   
   if keyword_set(zero_offset) then begin
      plty_ip=a_ip[0]+a_ip[1]*pltx_ip
      plty_ip_pls_sig=plty_ip*(1+yer_ip);(a_ip[0]+sigma_a_ip[0])+(a_ip[1]+sigma_a_ip[1])*pltx_ip
      plty_ip_min_sig=plty_ip*(1-yer_ip);(a_ip[0]-sigma_a_ip[0])+(a_ip[1]-sigma_a_ip[1])*pltx_ip      
   ;   lnplty_ip=exp(lna_ip[0])*pltx_ip^lna_ip[1]
   ;   lnplty_ip_pls_sig=exp(lna_ip[0]+lnsigma_a_ip[0])*pltx_ip^(lna_ip[1]-lnsigma_a_ip[1])
   endif else begin
      plty_ip=a_ip[1]*pltx_ip
      plty_ip_pls_sig=plty_ip*(1+yer_ip);(a_ip[1]+sigma_a_ip[1])*pltx_ip
      plty_ip_min_sig=plty_ip*(1+yer_ip);(a_ip[1]-sigma_a_ip[1])*pltx_ip      
   ;   lnplty_ip=exp(lna_ip[0])*pltx_ip^lna_ip[1] ; zero offset doesn't apply to ln fit
   ;   lnplty_ip_pls_sig=exp(lna_ip[0]+lnsigma_a_ip[0])*pltx_ip^(lna_ip[1]-sigma_a_ip[1])
   endelse

   ; Center IP Fit
   
   wcent_ip=where(fl_dist_src[gd_src_goes_ip] lt 45)
   if wcent_ip[0] ne -1 and n_elements(wcent_ip) ge 5 then begin
      ; Linear Fit
      b_cent_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wcent_ip]],src_ir[gd_src_goes_ip[wcent_ip]],1,sigma=sigma_b_cent_ip, $
                        measure_errors=sqrt(abs(src_ir[gd_src_goes_ip[wcent_ip]])), yband=yband_cip, status=status_lin, yfit=yfit_ip_cent)
      ;b_cent_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wcent_ip]],src_ir[gd_src_goes_ip[wcent_ip]],1,sigma=sigma_b_cent_ip, $
      ;                  measure_errors=yband_cip, yband=yband_cip2, status=status_lin)
      ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
      ;  it is a bad fit and there is no real IP
      ip_x1=1.e-7*b_cent_ip[1]; +b_cent_ip[0]
      sig_ip_x1=1.e-6*sigma_b_cent_ip[1]; +sigma_b_cent_ip[0]
      ; Calculate the percent error
      mody=yfit_ip_cent
      measy=src_ir[gd_src_goes_ip[wcent_ip]]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_ip_c=perirerr
      onesig_per=yer_ip_c*100.;(sig_ip_x1/ip_x1)*100.

      ; Log Fit
      ;lnb_cent_ip_init=poly_fit(alog(dgoes_long_src[gd_src_goes_ip[wcent_ip]]),alog(src_ir[gd_src_goes_ip[wcent_ip]]),1,$
      ;                  sigma=lnsigma_b_cent_ip_init, status=status, $
      ;                  measure_errors=sqrt(abs(alog(src_ir[gd_src_goes_ip[wcent_ip]]))), yband=lnyband_cip)
      ;lnb_cent_ip=poly_fit(alog(dgoes_long_src[gd_src_goes_ip[wcent_ip]]),alog(src_ir[gd_src_goes_ip[wcent_ip]]),1,$
      ;                  sigma=lnsigma_b_cent_ip, status=status_log, $
      ;                     measure_errors=lnyband_cip, yband=lnyband_cip2)
      ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
      ;  it is a bad fit and there is no real IP
      ;lnip_x1=exp(lnb_cent_ip[0])*(1.e-6^lnb_cent_ip[1])
      ;lnsig_ip_x1=exp(lnsigma_b_cent_ip[0]+lnb_cent_ip[0])+1.e-6*(lnsigma_b_cent_ip[1]+lnb_cent_ip[1])
      ;lnonesig_per=(lnsig_ip_x1-lnip_x1)/lnip_x1*100.

   endif
   ; not enough points to fit or invalid fit 
   if wcent_ip[0] eq -1 or n_elements(wcent_ip) lt 5 or status_lin ne 0 or onesig_per gt mx_std_per then begin 
      b_cent_ip=a_ip
      sigma_b_cent_ip=sigma_a_ip
      yer_ip_c=yer_ip
   endif   
   ;if wcent_ip[0] eq -1 or n_elements(wcent_ip) lt 5 or status_log ne 0 or lnonesig_per gt mx_std_per then begin 
   ;   lnb_cent_ip=lna_ip
   ;   lnsigma_b_cent_ip=lnsigma_a_ip
   ;endif   

   ; Mid IP Fit
   
   wmid_ip=where(fl_dist_src[gd_src_goes_ip] ge 45 and fl_dist_src[gd_src_goes_ip] lt 75)
   if wmid_ip[0] ne -1 and n_elements(wmid_ip) ge 5 then begin
      ; Lin Fit
      b_mid_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wmid_ip]],src_ir[gd_src_goes_ip[wmid_ip]],1,sigma=sigma_b_mid_ip, $
                       measure_errors=sqrt(abs(src_ir[gd_src_goes_ip[wmid_ip]])), yband=yband_mip, status=status_lin, yfit=yfit_ip_mid)
      ;b_mid_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wmid_ip]],src_ir[gd_src_goes_ip[wmid_ip]],1,sigma=sigma_b_mid_ip, $
      ;                 measure_errors=yband_mip, yband=yband_mip2, status=status_lin)
      ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
      ;  it is a bad fit and there is no real IP
      ip_x1=1.e-7*b_mid_ip[1]; +b_mid_ip[0]
      sig_ip_x1=1.e-6*sigma_b_mid_ip[1]; +sigma_b_mid_ip[0]
      ; Calculate the percent error
      mody=yfit_ip_mid
      measy=src_ir[gd_src_goes_ip[wmid_ip]]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_ip_m=perirerr
      onesig_per=yer_ip_m*100.;(sig_ip_x1/ip_x1)*100.

      ; Log Fit
      ;lnb_mid_ip_init=poly_fit(alog(dgoes_long_src[gd_src_goes_ip[wmid_ip]]),alog(src_ir[gd_src_goes_ip[wmid_ip]]),1,$
      ;                  sigma=lnsigma_b_mid_ip_init, status=status, $
      ;                  measure_errors=sqrt(abs(alog(src_ir[gd_src_goes_ip[wmid_ip]]))), yband=lnyband_mip)
      ;lnb_mid_ip=poly_fit(alog(dgoes_long_src[gd_src_goes_ip[wmid_ip]]),alog(src_ir[gd_src_goes_ip[wmid_ip]]),1,$
      ;                  sigma=lnsigma_b_mid_ip, status=status_log, $
      ;                    measure_errors=lnyband_mip, yband=lnyband_mip2)
      ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
      ;  it is a bad fit and there is no real IP
      ;lnip_x1=exp(lnb_mid_ip[0])*(1.e-6^lnb_mid_ip[1])
      ;lnsig_ip_x1=exp(lnsigma_b_mid_ip[0]+lnb_mid_ip[0])+1.e-6*(lnsigma_b_mid_ip[1]+lnb_mid_ip[1])
      ;lnonesig_per=(lnsig_ip_x1-lnip_x1)/lnip_x1*100.

   endif
   if wmid_ip[0] eq -1 or n_elements(wmid_ip) lt 5 or status_lin ne 0 or onesig_per gt mx_std_per then begin
      b_mid_ip=a_ip
      sigma_b_mid_ip=sigma_a_ip
      yer_ip_m=yer_ip
   endif
   ;if wmid_ip[0] eq -1 or n_elements(wmid_ip) lt 5 or status_log ne 0 or lnonesig_per gt mx_std_per then begin
   ;   lnb_mid_ip=lna_ip
   ;   lnsigma_b_mid_ip=lnsigma_a_ip
   ;endif

   ; Limb IP Fit
   
   wlimb_ip=where(fl_dist_src[gd_src_goes_ip] ge 75)
   if wlimb_ip[0] ne -1 and n_elements(wlimb_ip) ge 5 then begin
      ; Linear Fit
      b_limb_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wlimb_ip]],src_ir[gd_src_goes_ip[wlimb_ip]],1,sigma=sigma_b_limb_ip, $
                        measure_errors=sqrt(abs(src_ir[gd_src_goes_ip[wlimb_ip]])),yband=yband_lip, status=status_lin, yfit=yfit_ip_limb)
      ;b_limb_ip=poly_fit(dgoes_long_src[gd_src_goes_ip[wlimb_ip]],src_ir[gd_src_goes_ip[wlimb_ip]],1,sigma=sigma_b_limb_ip, $
      ;                  measure_errors=yband_lip,yband=yband_lip2, status=status_lin)
      ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
      ;  it is a bad fit and there is no real IP
      ip_x1=1.e-7*b_limb_ip[1];+b_limb_ip[0]
      sig_ip_x1=1.e-6*sigma_b_limb_ip[1];+sigma_b_limb_ip[0]
      ; Calculate the percent error
      mody=yfit_ip_limb
      measy=src_ir[gd_src_goes_ip[wlimb_ip]]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_ip_l=perirerr
      onesig_per=yer_ip_l*100.;(sig_ip_x1/ip_x1)*100.
      
      ; Log Fit
      ;lnb_limb_ip_init=poly_fit(alog(dgoes_long_src[gd_src_goes_ip[wlimb_ip]]),alog(src_ir[gd_src_goes_ip[wlimb_ip]]),1,$
      ;                  sigma=lnsigma_b_limb_ip_init, status=status, $
      ;                  measure_errors=sqrt(abs(alog(src_ir[gd_src_goes_ip[wlimb_ip]]))), yband=lnyband_lip)
      ;lnb_limb_ip=poly_fit(alog(dgoes_long_src[gd_src_goes_ip[wlimb_ip]]),alog(src_ir[gd_src_goes_ip[wlimb_ip]]),1,$
      ;                  sigma=lnsigma_b_limb_ip, status=status_log, $
      ;                  measure_errors=lnyband_lip, yband=lnyband_lip2)
      ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
      ;  it is a bad fit and there is no real IP
      ;lnip_x1=exp(lnb_limb_ip[0])*(1.e-6^lnb_limb_ip[1])
      ;lnsig_ip_x1=exp(lnsigma_b_limb_ip[0]+lnb_limb_ip[0])+1.e-6*(lnsigma_b_limb_ip[1]+lnb_limb_ip[1])
      ;lnonesig_per=(lnsig_ip_x1-lnip_x1)/lnip_x1*100.

   endif
   if wlimb_ip[0] eq -1 or n_elements(wlimb_ip) lt 5 or status_lin ne 0 or onesig_per gt mx_std_per then begin
      b_limb_ip=a_ip
      sigma_b_limb_ip=sigma_a_ip
      yer_ip_l=yer_ip
   endif
   ;if wlimb_ip[0] eq -1 or n_elements(wlimb_ip) lt 5 or status_log ne 0 or lnonesig_per gt mx_std_per then begin
   ;   lnb_limb_ip=lna_ip
   ;   lnsigma_b_limb_ip=lnsigma_a_ip
   ;endif
   
   ; Make sure mid and limb are not greater than center 
   if b_mid_ip[1] gt b_cent_ip[1] then begin
      b_mid_ip=b_cent_ip
      yer_ip_m=yer_ip_c
   endif   
   if b_limb_ip[1] gt b_cent_ip[1] then begin
      b_limb_ip=b_cent_ip
      yer_ip_l=yer_ip_c
   endif   
   ;if c_mid_ip[1] gt c_cent_ip[1] then c_mid_ip=c_cent_ip
   ;if c_limb_ip[1] gt c_cent_ip[1] then c_limb_ip=c_cent_ip
   ; If the mid or limb are greater than center, force all of 
   ;   the fits to be the 'all' fit
   if b_limb_ip[1] ge b_cent_ip[1] or b_mid_ip[1] ge b_cent_ip[1] then begin
      b_limb_ip=a_ip
      b_mid_ip=a_ip
      b_cent_ip=a_ip
      sigma_b_limb_ip=sigma_a_ip
      sigma_b_mid_ip=sigma_a_ip
      sigma_b_cent_ip=sigma_a_ip
      yer_ip_l=yer_ip
      yer_ip_c=yer_ip
      yer_ip_m=yer_ip
   endif
   ;if lnb_limb_ip[1] le 0.0 then begin 
   ;   lnb_limb_ip=lna_ip
   ;   lnsigma_b_limb_ip=lnsigma_a_ip
   ;endif
   ;if lnb_mid_ip[1] le 0.0 then begin 
   ;   lnb_mid_ip=lna_ip
   ;   lnsigma_b_mid_ip=lnsigma_a_ip
   ;endif
   ;if lnb_cent_ip[1] le 0.0 then begin 
   ;   lnb_cent_ip=lna_ip
   ;   lnsigma_b_cent_ip=lnsigma_a_ip
   ;endif
   ;if lnb_limb_ip[1] gt lnb_cent_ip[1] then begin ; power <1
   ;   lnb_limb_ip=lna_ip
   ;   lnb_cent_ip=lna_ip
   ;   lnsigma_b_limb_ip=lnsigma_a_ip
   ;   lnsigma_b_cent_ip=lnsigma_a_ip
   ;endif
   ;if lnb_mid_ip[1] gt lnb_cent_ip[1] then begin ; power <1
   ;   lnb_mid_ip=lna_ip
   ;   lnb_cent_ip=lna_ip
   ;   lnsigma_b_mid_ip=lnsigma_a_ip
   ;   lnsigma_b_cent_ip=lnsigma_a_ip
   ;endif
   ;if lnb_mid_ip[1] lt lnb_limb_ip[1] then begin ; power <1
   ;   lnb_limb_ip=lnb_mid_ip
   ;   lnsigma_b_limb_ip=lnsigma_b_mid_ip
   ;endif

   ;if c_limb_ip[1] ge c_cent_ip[1] and c_mid_ip[1] ge c_cent_ip[1] then begin
   ;   c_limb_ip=c_ip
   ;   c_mid_ip=c_ip
   ;   c_cent_ip=c_ip
   ;   sigma_c_limb_ip=sigma_c_ip
   ;   sigma_c_mid_ip=sigma_c_ip
   ;   sigma_c_cent_ip=sigma_c_ip
   ;endif
   
   if keyword_set(zero_offset) then begin
      plty_b_ip_cent=b_cent_ip[0]+(b_cent_ip[1]*pltx_ip)
      plty_b_ip_mid=b_mid_ip[0]+(b_mid_ip[1]*pltx_ip)
      plty_b_ip_limb=b_limb_ip[0]+(b_limb_ip[1]*pltx_ip)
      ;plty_c_ip_cent=c_cent_ip[0]+(c_cent_ip[1]*alog10(pltx_ip)) 
      ;plty_c_ip_mid=c_mid_ip[0]+(c_mid_ip[1]*alog10(pltx_ip))
      ;plty_c_ip_limb=c_limb_ip[0]+(c_limb_ip[1]*alog10(pltx_ip))
   endif else begin
      plty_b_ip_cent=b_cent_ip[1]*pltx_ip
      plty_b_ip_mid=b_mid_ip[1]*pltx_ip
      plty_b_ip_limb=b_limb_ip[1]*pltx_ip
      ;plty_c_ip_cent=c_cent_ip[0]+(c_cent_ip[1]*alog10(pltx_ip)) ; Always need zero offset in log
      ;plty_c_ip_mid=c_mid_ip[0]+(c_mid_ip[1]*alog10(pltx_ip))
      ;plty_c_ip_limb=c_limb_ip[0]+(c_limb_ip[1]*alog10(pltx_ip))
   endelse
   ;lnplty_ip_cent=exp(lnb_cent_ip[0])*pltx_ip^lnb_cent_ip[1] ; zero offset doesn't apply to ln fit
   ;lnplty_ip_cent_pls_sig=exp(lnb_cent_ip[0]+lnsigma_b_cent_ip[0])*pltx_ip^(lnb_cent_ip[1]-lnsigma_b_cent_ip[1])
   ;lnplty_ip_mid=exp(lnb_mid_ip[0])*pltx_ip^lnb_mid_ip[1] ; zero offset doesn't apply to ln fit
   ;lnplty_ip_mid_pls_sig=exp(lnb_mid_ip[0]+lnsigma_b_mid_ip[0])*pltx_ip^(lnb_mid_ip[1]-lnsigma_b_mid_ip[1])
   ;lnplty_ip_limb=exp(lnb_limb_ip[0])*pltx_ip^lnb_limb_ip[1] ; zero offset doesn't apply to ln fit
   ;lnplty_ip_limb_pls_sig=exp(lnb_limb_ip[0]+lnsigma_b_limb_ip[0])*pltx_ip^(lnb_limb_ip[1]-lnsigma_b_limb_ip[1])

   ; Find the transition point from the log10(goes) fit to the goes fit
   ;tp_ip_all=where(plty_ip gt plty_ip_c and pltx_ip gt 1e-8)
   ;tp_ip=tp_ip_all[0]
   ;tp_ip_all_cent=where(plty_b_ip_cent gt plty_c_ip_cent and pltx_ip gt 1e-8)
   ;tp_ip_cent=tp_ip_all_cent[0]
   ;tp_ip_all_mid=where(plty_b_ip_mid gt plty_c_ip_mid and pltx_ip gt 1e-8)
   ;tp_ip_mid=tp_ip_all_mid[0]
   ;tp_ip_all_limb=where(plty_b_ip_limb gt plty_c_ip_limb and pltx_ip gt 1e-8)
   ;tp_ip_limb=tp_ip_all_limb[0]
   
   if keyword_set(debug) then begin
      cc=independent_color()
      window,0
      ip_ymin=min(src_ir[gd_src_goes_ip])
      ip_ymax=max(src_ir[gd_src_goes_ip])
      plot, dgoes_long_src,src_ir, /xlog, /ylog, psym=4, title=strtrim(i,2)+'nm', charsize=1.5, yr=[ip_ymin,ip_ymax], $
            xtitle='dGOES XRS-B/dt', ytitle='SORCE SOLSTICE HR', symsize=2, thick=2, xr=[1e-11,1e-5]
      oplot, dgoes_long_src[gd_src_goes_ip[wcent_ip]],src_ir[gd_src_goes_ip[wcent_ip]], psym=4, $
            color=cc.green, symsize=2, thick=2
      oplot, dgoes_long_src[gd_src_goes_ip[wmid_ip]],src_ir[gd_src_goes_ip[wmid_ip]], psym=4, color=cc.light_blue, $
            symsize=2, thick=2
      oplot, dgoes_long_src[gd_src_goes_ip[wlimb_ip]],src_ir[gd_src_goes_ip[wlimb_ip]], psym=4, color=cc.orange, $
            symsize=2, thick=2
      ;oplot, pltx_ip, lnplty_ip, thick=2, color=cc.blue
      ;oplot, pltx_ip, lnplty_ip_pls_sig, thick=2, color=cc.blue, linestyle=1
      if a_ip[1] gt 0.0 then begin
         oplot, pltx_ip, plty_ip, thick=3, color=cc.red
         oplot, pltx_ip, plty_ip_pls_sig, thick=3, color=cc.red, linestyle=1
         oplot, pltx_ip, plty_ip_min_sig, thick=3, color=cc.red, linestyle=1
      endif
      ;if c_ip[1] gt 0.0 then begin
      ;   oplot, pltx_ip, plty_ip_c, thick=3, color=cc.blue
      ;   oplot, pltx_ip, plty_ip_c_pls_sig, thick=3, color=cc.blue, linestyle=1
      ;   oplot, pltx_ip, plty_ip_c_min_sig, thick=3, color=cc.blue, linestyle=1
      ;endif
      ; Overplot all linear fits
      ;if b_cent_ip[1] gt 0.0 then oplot, pltx_ip, plty_b_ip_cent, thick=2, color=cc.green
      ;if b_mid_ip[1] gt 0.0 then oplot, pltx_ip, plty_b_ip_mid, thick=2, color=cc.light_blue
      ;if b_limb_ip[1] gt 0.0 then oplot, pltx_ip, plty_b_ip_limb, thick=2, color=cc.orange
      ;if c_cent_ip[1] gt 0.0 then oplot, pltx_ip, plty_c_ip_cent, thick=2, color=cc.green, linestyle=2
      ;if c_mid_ip[1] gt 0.0 then oplot, pltx_ip, plty_c_ip_mid, thick=2, color=cc.light_blue, linestyle=2
      ;if c_limb_ip[1] gt 0.0 then oplot, pltx_ip, plty_c_ip_limb, thick=2, color=cc.orange, linestyle=2
      ;if lnb_cent_ip[1] gt 0.0 then oplot, pltx_ip, lnplty_ip_cent, thick=2, color=cc.green 
      ;if lnb_mid_ip[1] gt 0.0 then oplot, pltx_ip, lnplty_ip_mid, thick=2, color=cc.light_blue
      ;if lnb_limb_ip[1] gt 0.0 then oplot, pltx_ip, lnplty_ip_limb, thick=2, color=cc.orange
      xyouts, 0.7, 0.9, 'Blue: All (with +/- 1 sig)', color=cc.blue, /normal, charsize=1.5
      xyouts, 0.7, 0.85, 'Green: Center', color=cc.green, /normal, charsize=1.5
      xyouts, 0.7, 0.8, 'Light_Blue: Mid', color=cc.light_blue, /normal, charsize=1.5
      xyouts, 0.7, 0.75, 'Orange: Limb', color=cc.orange, /normal, charsize=1.5
                                ;xyouts, 0.7, 0.7, 'Dashed: log10(GOES)',/normal, charsize=1.5
      
   endif
   
   ; 
   ; Gradual Phase Linear fit - First to subtract off IP before
   ;    finding GP unless keyword /no_ip_sub is set
   
   ; Re-set the maximum st. dev. percentage for a valid GP fit
   mx_std_per_gp=300.             ; 1000% is a factor of 10

   ; Subtract of IP results
   if keyword_set(zero_offset) then begin
      cent_ip=b_cent_ip[0]+b_cent_ip[1]*dgoes_long_src
      mid_ip=b_mid_ip[0]+b_mid_ip[1]*dgoes_long_src
      limb_ip=b_limb_ip[0]+b_limb_ip[1]*dgoes_long_src
   endif else begin
      cent_ip=b_cent_ip[1]*dgoes_long_src
      mid_ip=b_mid_ip[1]*dgoes_long_src
      limb_ip=b_limb_ip[1]*dgoes_long_src
   endelse
   wlimb=where(fl_dist_src ge 75)
   wmid=where(fl_dist_src ge 45 and fl_dist_src lt 75)
   wcent=where(fl_dist_src lt 45)
   if not keyword_set(no_ip_sub) then begin
      src_ir[wlimb]=src_ir[wlimb]-limb_ip[wlimb]
      src_ir[wcent]=src_ir[wcent]-cent_ip[wcent]
      src_ir[wmid]=src_ir[wmid]-mid_ip[wmid]
   endif
   ;bdsrc=where(src_ir lt -0.1)
   ;src_ir[bdsrc]=0.0
   src_ir=src_ir>0.0
   
   gd_src_goes=where(goes_long_src gt 1.e-5 and src_ir gt 0.0); and goes_long_src gt 1.e-5)
   
   ;for m=0,n_elements(gd_src_goes)-1 then begin

   ; All GP Fit
   
   a=poly_fit(goes_long_src[gd_src_goes],src_ir[gd_src_goes],1, sigma=sigma_a_gp,measure_errors=sqrt(abs(src_ir[gd_src_goes])), $
                   yband=ybanda,yfit=yfit_a, status=status)   
   ;a=poly_fit(goes_long_src[gd_src_goes],src_ir[gd_src_goes],1, sigma=sigma_a_gp,measure_errors=ybanda, $
   ;                yband=ybanda2,yfit=yfita2, status=status)
   ;a2=poly_fit(goes_long_src[gd_src_goes],src_ir[gd_src_goes],1, sigma=sigma_a_gp2,measure_errors=0.1*src_ir[gd_src_goes])
   ;la_init=poly_fit(alog(goes_long_src[gd_src_goes]),alog(src_ir[gd_src_goes]),1, sigma=lsigma_a_gp_init,measure_errors=sqrt(abs(alog(src_ir[gd_src_goes]))), $
   ;           yband=yband_la, yfit=yfit_la)
   ;la=poly_fit(alog(goes_long_src[gd_src_goes]),alog(src_ir[gd_src_goes]),1, sigma=lsigma_a_gp,measure_errors=yband_la, $
   ;           yband=yband_la2, yfit=yfit_la2)

   ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
   ;  it is a bad fit and there is no real IP
   gp_x1=1.e-4*a[1] ;+a[0]
   sig_gp_x1=1.e-4*sigma_a_gp[1] ;+sigma_a_gp[0]
   ; Calculate the percent error
   mody=yfit_a
   measy=src_ir[gd_src_goes]
   gder=where((mody-measy)/measy lt 10.)
   perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
   yer_gp=perirerr
   onesig_per=yer_gp*100.;(sig_gp_x1/gp_x1)*100.
   if keyword_set(debug) then print, onesig_per
   if a[1] lt 0.0 or onesig_per gt mx_std_per_gp then begin ; if negative fit then no real fit or gp so set coefs to zero.
      a[*]=0.0
      sigma_a_gp[*]=0.0
      yer_gp=0.0
   endif
   pltx=findgen(1.e5)/1.e7
   if keyword_set(zero_offset) then begin
      plty=a[0]+a[1]*pltx
      ;plty2=a2[0]+a2[1]*pltx
      ;lplty=exp(la[0])*(pltx^la[1])
      ;lplty_sig=exp(la[0]+lsigma_a_gp[0])*(pltx^(la[1]-lsigma_a_gp[1]))
      plty_pls_sig=plty*(1+yer_gp);(a[0]+sigma_a_gp[0])+(a[1]+sigma_a_gp[1])*pltx
      ;plty_pls_sig2=(a2[0]+sigma_a_gp2[0])+(a2[1]+sigma_a_gp2[1])*pltx
      plty_min_sig=plty*(1-yer_gp);(a[0]-sigma_a_gp[0])+(a[1]-sigma_a_gp[1])*pltx
   endif else begin
      plty=a[1]*pltx
      ;plty2=a2[1]*pltx
      ;lplty=exp(la[0])*pltx^la[1]
      ;lplty_sig=exp(la[0]+lsigma_a_gp[0])*(pltx^(la[1]-lsigma_a_gp[1]))
      plty_pls_sig=plty*(1+yer_gp);(a[1]+sigma_a_gp[1])*pltx
      ;plty_pls_sig2=(a2[1]+sigma_a_gp2[1])*pltx
      plty_min_sig=plty*(1-yer_gp);(a[1]-sigma_a_gp[1])*pltx
   endelse
   ;b=poly_fit(alog10(goes_long_src[gd_src_goes]),src_ir[gd_src_goes],1,sigma=sigma_b_gp)

   ; Center GP Fit

   wcent=where(fl_dist_src[gd_src_goes] lt 45)
   if wcent[0] ne -1 and n_elements(wcent) ge 5 then begin
      ;b_cent=poly_fit(alog10(goes_long_src[gd_src_goes[wcent]]),src_ir[gd_src_goes[wcent]],1,sigma=sigma_b_cent_gp)
      a_cent=poly_fit(goes_long_src[gd_src_goes[wcent]],src_ir[gd_src_goes[wcent]],1,sigma=sigma_a_cent_gp, $
                      measure_errors=sqrt(abs(src_ir[gd_src_goes[wcent]])), yband=yband_cgp, status=status, yfit=yfit_gp_c)
      ;a_cent=poly_fit(goes_long_src[gd_src_goes[wcent]],src_ir[gd_src_goes[wcent]],1,sigma=sigma_a_cent_gp, $
      ;               measure_errors=yband_cgp, status=status)
      ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
      ;  it is a bad fit and there is no real IP
      gp_x1=1.e-4*a_cent[1] ;+a_cent[0]
      sig_gp_x1=1.e-4*sigma_a_cent_gp[1] ;+sigma_a_cent_gp[0]
      ; Calculate the percent error
      mody=yfit_gp_c
      measy=src_ir[gd_src_goes[wcent]]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_gp_c=perirerr
      onesig_per=yer_gp_c*100.;(sig_gp_x1/gp_x1)*100.
   endif
   if wcent[0] eq -1 or n_elements(wcent) lt 5 or status ne 0 or onesig_per gt mx_std_per_gp then begin
      ;b_cent=b
      ;sigma_b_cent_gp=sigma_b_gp
      a_cent=a
      sigma_a_cent_gp=sigma_a_gp
      yer_gp_c=yer_gp
   endif

   ; Mid GP Fit
   
   wmid=where(fl_dist_src[gd_src_goes] ge 45 and fl_dist_src[gd_src_goes] lt 75)
   if wmid[0] ne -1 and n_elements(wmid) ge 5 then begin
      ;b_mid=poly_fit(alog10(goes_long_src[gd_src_goes[wmid]]),src_ir[gd_src_goes[wmid]],1,sigma=sigma_b_mid_gp)
      a_mid=poly_fit(goes_long_src[gd_src_goes[wmid]],src_ir[gd_src_goes[wmid]],1,sigma=sigma_a_mid_gp, $
                    measure_errors=sqrt(abs(src_ir[gd_src_goes[wmid]])),yband=yband_mgp, status=status, yfit=yfit_gp_m)
      ;a_mid=poly_fit(goes_long_src[gd_src_goes[wmid]],src_ir[gd_src_goes[wmid]],1,sigma=sigma_a_mid_gp, $
      ;              measure_errors=yband_mgp, status=status)
      ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
      ;  it is a bad fit and there is no real IP
      gp_x1=1.e-4*a_mid[1] ;+a_mid[0]
      sig_gp_x1=1.e-4*sigma_a_mid_gp[1] ;+sigma_a_mid_gp[0]
      ; Calculate the percent error
      mody=yfit_gp_m
      measy=src_ir[gd_src_goes[wmid]]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_gp_m=perirerr
      onesig_per=yer_gp_m*100;(sig_gp_x1/gp_x1)*100.
   endif
   if wmid[0] eq -1 or n_elements(wmid) lt 5 or status ne 0 or onesig_per gt mx_std_per_gp then begin
      ;b_mid=b
      ;sigma_b_mid_gp=sigma_b_gp
      a_mid=a
      sigma_a_mid_gp=sigma_a_gp
      yer_gp_m=yer_gp
   endif

   ; Limb GP Fit

   wlimb=where(fl_dist_src[gd_src_goes] ge 75)
   if wlimb[0] ne -1 and n_elements(wlimb) ge 5 then begin
      ;b_limb=poly_fit(alog10(goes_long_src[gd_src_goes[wlimb]]),src_ir[gd_src_goes[wlimb]],1,sigma=sigma_b_limb_gp)
      a_limb=poly_fit(goes_long_src[gd_src_goes[wlimb]],src_ir[gd_src_goes[wlimb]],1,sigma=sigma_a_limb_gp, $
                     measure_errors=sqrt(abs(src_ir[gd_src_goes[wlimb]])), yband=yband_lgp, status=status, yfit=yfit_gp_l)
      ;a_limb=poly_fit(goes_long_src[gd_src_goes[wlimb]],src_ir[gd_src_goes[wlimb]],1,sigma=sigma_a_limb_gp, $
      ;               measure_errors=yband_lgp, status=status)
      ; find stdev at ~X1 IP level, and if greater than mx_std_per% then 
      ;  it is a bad fit and there is no real IP
      gp_x1=1.e-4*a_limb[1]; +a_limb[0]
      sig_gp_x1=1.e-4*sigma_a_limb_gp[1] ;+sigma_a_limb_gp[0]
      ; Calculate the percent error
      mody=yfit_gp_l
      measy=src_ir[gd_src_goes[wlimb]]
      gder=where((mody-measy)/measy lt 10.)
      perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
      yer_gp_l=perirerr
      onesig_per=yer_gp_l*100.;(sig_gp_x1/gp_x1)*100.
   endif
   if wlimb[0] eq -1 or n_elements(wlimb) lt 5 or status eq 0 or onesig_per gt mx_std_per_gp then begin
      ;b_limb=b
      ;sigma_b_limb_gp=sigma_b_gp
      a_limb=a
      sigma_a_limb_gp=sigma_a_gp
      yer_gp_l=yer_gp
   endif

   ; Make sure mid and limb are not greater than center 
   ;if b_mid[1] gt b_cent[1] then b_mid=b_cent
   ;if b_limb[1] gt b_cent[1] then b_limb=b_cent
   if a_mid[1] gt a_cent[1] then begin
      a_mid=a_cent
      yer_gp_m=yer_gp_c
   endif
   if a_limb[1] gt a_cent[1] then begin
      a_limb=a_cent
      yer_gp_l=yer_gp_c
   endif
   
   ; If both mid and limb are greater than center, force all of 
   ;   the fits to be the 'all' fit
   ;if b_limb[1] ge b_cent[1] and b_mid[1] ge b_cent[1] then begin
   ;   b_limb=b
   ;   b_mid=b
   ;   b_cent=b
   ;   sigma_b_limb_gp=sigma_b_gp
   ;   sigma_b_mid_gp=sigma_b_gp
   ;   sigma_b_cent_gp=sigma_b_gp
   ;endif
   if a_limb[1] ge a_cent[1] and a_mid[1] ge a_cent[1] then begin
      a_limb=a
      a_mid=a
      a_cent=a
      sigma_a_limb_gp=sigma_a_gp
      sigma_a_mid_gp=sigma_a_gp
      sigma_a_cent_gp=sigma_a_gp
      yer_gp_l=yer_gp
      yer_gp_c=yer_gp
      yer_gp_m=yer_gp
   endif

   pltx=findgen(1.d6)/1.e7
   if keyword_set(zero_offset) then begin
      plty=a[0]+a[1]*pltx
      ;plty_b=b[0]+(b[1]*alog10(pltx))
      plty_a_cent=a_cent[0]+(a_cent[1]*pltx)
      plty_a_mid=a_mid[0]+(a_mid[1]*pltx)
      plty_a_limb=a_limb[0]+(a_limb[1]*pltx)
      ;plty_b_cent=b_cent[0]+(b_cent[1]*alog10(pltx))
      ;plty_b_mid=b_mid[0]+(b_mid[1]*alog10(pltx))
      ;plty_b_limb=b_limb[0]+(b_limb[1]*alog10(pltx))
   endif else begin
      plty=a[1]*pltx
      ;plty_b=b[0]+b[1]*alog10(pltx)
      plty_a_cent=a_cent[1]*pltx
      plty_a_mid=a_mid[1]*pltx
      plty_a_limb=a_limb[1]*pltx
      ;plty_b_cent=b_cent[0]+b_cent[1]*alog10(pltx) ; Need zero offset in logspace
      ;plty_b_mid=b_mid[0]+b_mid[1]*alog10(pltx)
      ;plty_b_limb=b_limb[0]+b_limb[1]*alog10(pltx)
   endelse

   ; Find the transition point from the log10(goes) fit to the goes fit
   ;tp_gp_all=where(plty gt plty_b and pltx gt 1e-5)
   ;tp_gp=tp_gp_all[0]
   ;tp_gp_all_cent=where(plty_a_cent gt plty_b_cent and pltx gt 1e-5)
   ;tp_gp_cent=tp_gp_all_cent[0]
   ;tp_gp_all_mid=where(plty_a_mid gt plty_b_mid and pltx gt 1e-5)
   ;tp_gp_mid=tp_gp_all_mid[0]
   ;tp_gp_all_limb=where(plty_a_limb gt plty_b_limb and pltx gt 1e-5)
   ;tp_gp_limb=tp_gp_all_limb[0]

   if keyword_set(debug) then begin
      cc=independent_color()
      window,1
      gp_ymin=min(src_ir[gd_src_goes])
      gp_ymax=max(src_ir[gd_src_goes])
      plot, goes_long_src,src_ir, /xlog, /ylog, psym=4, title=strtrim(i,2)+'nm', charsize=1.5, yr=[gp_ymin,gp_ymax], $
            xtitle='GOES XRS-B', ytitle='SORCE SOLSTICE HR', symsize=2, thick=2, xr=[1e-8,1e-2]
      oplot, goes_long_src[gd_src_goes[wcent]],src_ir[gd_src_goes[wcent]], psym=4, $
            color=cc.green, symsize=2, thick=2
      oplot, goes_long_src[gd_src_goes[wmid]],src_ir[gd_src_goes[wmid]], psym=4, color=cc.light_blue, $
            symsize=2, thick=2
      oplot, goes_long_src[gd_src_goes[wlimb]],src_ir[gd_src_goes[wlimb]], psym=4, color=cc.orange, $
            symsize=2, thick=2
      ;if b[1] gt 0.0 then oplot, pltx, plty_b, thick=2, color=cc.blue, linestyle=2
      ;if b_cent[1] gt 0.0 then oplot, pltx, plty_b_cent, thick=2, color=cc.green, linestyle=2
      ;if b_mid[1] gt 0.0 then oplot, pltx, plty_b_mid, thick=2, color=cc.light_blue, linestyle=2
      ;if b_limb[1] gt 0.0 then oplot, pltx, plty_b_limb, thick=2, color=cc.orange, linestyle=2
      if a[1] gt 0.0 then begin
         oplot, pltx, plty, thick=2, color=cc.blue
         oplot, pltx, plty_pls_sig, thick=2, color=cc.blue, linestyle=1
         oplot, pltx, plty_min_sig, thick=2, color=cc.blue, linestyle=1
      endif
      if a_cent[1] gt 0.0 then oplot, pltx, plty_a_cent, thick=2, color=cc.green
      if a_cent[1] gt 0.0 then oplot, pltx, plty_a_cent*(1+yer_gp_c), thick=2, color=cc.green, linestyle=1
      if a_mid[1] gt 0.0 then oplot, pltx, plty_a_mid, thick=2, color=cc.light_blue
      if a_limb[1] gt 0.0 then oplot, pltx, plty_a_limb, thick=2, color=cc.orange
      xyouts, 0.8, 0.9, 'Blue: All', color=cc.blue, /normal, charsize=1.5
      xyouts, 0.8, 0.85, 'Green: Center', color=cc.green, /normal, charsize=1.5
      xyouts, 0.8, 0.8, 'Light_Blue: Mid', color=cc.light_blue, /normal, charsize=1.5
      xyouts, 0.8, 0.75, 'Orange: Limb', color=cc.orange, /normal, charsize=1.5
      ;xyouts, 0.8, 0.7, 'Solid: GOES, Dashed: log(GOES)', /normal, charsize=1.5
      ans=''
      if keyword_set(debug) then read, ans, prompt='Next Wavelength (or 2 to stop)? '
      if ans eq '2' then stop
      ;if keyword_set(debug) then stop
   endif

   if keyword_set(plt_only) and not keyword_set(process_wv) then goto, pltonly
      
   wv=i
   linfit_coefs=a
   sigma_linfit_coefs_gp=sigma_a_gp
   linfit_coefs_ip=a_ip
   sigma_linfit_coefs_ip=sigma_a_ip

   ;linfit_xlog_coefs_all=b
   ;sigma_linfit_xlog_coefs_all_gp=sigma_b_gp
   ;linfit_xlog_coefs_cent=b_cent
   ;sigma_linfit_xlog_coefs_cent_gp=sigma_b_cent_gp
   ;linfit_xlog_coefs_mid=b_mid
   ;sigma_linfit_xlog_coefs_mid_gp=sigma_b_mid_gp
   ;linfit_xlog_coefs_limb=b_limb
   ;sigma_linfit_xlog_coefs_limb_gp=sigma_b_limb_gp

   ; Lin fit coefs ip
   linfit_coefs_limb_ip=b_limb_ip
   sigma_linfit_coefs_limb_ip=sigma_b_limb_ip
   linfit_coefs_mid_ip=b_mid_ip
   sigma_linfit_coefs_mid_ip=sigma_b_mid_ip
   linfit_coefs_cent_ip=b_cent_ip
   sigma_linfit_coefs_cent_ip=sigma_b_cent_ip

   ; lin fit coefs gp
   linfit_coefs_limb=a_limb
   sigma_linfit_coefs_limb_gp=sigma_a_limb_gp
   linfit_coefs_mid=a_mid
   sigma_linfit_coefs_mid_gp=sigma_a_mid_gp
   linfit_coefs_cent=a_cent
   sigma_linfit_coefs_cent_gp=sigma_a_cent_gp
   
   ; alog fit coefs ip
   ;logfit_coefs_ip=lna_ip
   ;sigma_logfit_coefs_ip=lnsigma_a_ip
   ;logfit_coefs_limb_ip=lnb_limb_ip
   ;sigma_logfit_coefs_limb_ip=lnsigma_b_limb_ip 
   ;logfit_coefs_mid_ip=lnb_mid_ip
   ;sigma_logfit_coefs_mid_ip=lnsigma_b_mid_ip
   ;logfit_coefs_cent_ip=lnb_cent_ip
   ;sigma_logfit_coefs_cent_ip=lnsigma_b_cent_ip

   ; IP for alog10(dgoes/dt)
   ;linfit_xlog_coefs_all_ip=c_ip
   ;sigma_linfit_xlog_coefs_all_ip=sigma_c_ip
   ;linfit_xlog_coefs_cent_ip=c_cent_ip
   ;sigma_linfit_xlog_coefs_cent_ip=sigma_c_cent_ip
   ;linfit_xlog_coefs_mid_ip=c_mid_ip
   ;sigma_linfit_xlog_coefs_mid_ip=sigma_c_mid_ip
   ;linfit_xlog_coefs_limb_ip=c_limb_ip
   ;sigma_linfit_xlog_coefs_limb_ip=sigma_c_limb_ip

   ; Also save the maximum value measured for each wavelength
   max_val=max(src_ir[gd_src_goes])
   FILE_MKDIR, expand_path('$fism_data') + '/lasp/sorce/solstice_daily/hr_goes_sols_wv'
   save, goes_long_src, src_ir, src_ir_orig, src_gps, wv, linfit_coefs, fl_dist_src, $ ;linfit_xlog_coefs_all, 
         src_ir_daily, max_val, $ ;linfit_xlog_coefs_cent, linfit_xlog_coefs_mid, linfit_xlog_coefs_limb, 
         linfit_coefs_ip, dgoes_long_src, linfit_coefs_limb_ip, linfit_coefs_cent_ip, $; tp_gp, tp_gp_cent, tp_gp_mid, tp_gp_limb, $
         linfit_coefs_mid_ip, linfit_coefs_cent, linfit_coefs_mid, linfit_coefs_limb, $; tp_ip, tp_ip_cent, tp_ip_mid, tp_ip_limb, $
         sigma_linfit_coefs_gp, sigma_linfit_coefs_ip, $ ;sigma_linfit_xlog_coefs_all_gp, sigma_linfit_xlog_coefs_cent_gp,
         sigma_linfit_coefs_limb_ip, sigma_linfit_coefs_mid_ip, $ ;sigma_linfit_xlog_coefs_mid_gp, sigma_linfit_xlog_coefs_limb_gp, 
         sigma_linfit_coefs_cent_ip, sigma_linfit_coefs_limb_gp, sigma_linfit_coefs_mid_gp, sigma_linfit_coefs_cent_gp, $
         yer_gp, yer_gp_l, yer_gp_m, yer_gp_c, yer_ip, yer_ip_l, yer_ip_m, yer_ip_c, $
         file= expand_path('$fism_data') + '/lasp/sorce/solstice_daily/hr_goes_sols_wv/hr_goes_sol_comp_'+strmid(strtrim(wv,2),0,6)+'nm.sav'
         ;logfit_coefs_ip, sigma_logfit_coefs_ip, logfit_coefs_limb_ip, sigma_logfit_coefs_limb_ip, logfit_coefs_mid_ip, $
         ;sigma_logfit_coefs_mid_ip, logfit_coefs_cent_ip, sigma_logfit_coefs_cent_ip, $
         ;linfit_xlog_coefs_all_ip, sigma_linfit_xlog_coefs_all_ip, linfit_xlog_coefs_cent_ip, sigma_linfit_xlog_coefs_cent_ip, $
         ;linfit_xlog_coefs_mid_ip, sigma_linfit_xlog_coefs_mid_ip, linfit_xlog_coefs_limb_ip, sigma_linfit_xlog_coefs_limb_ip, $

   if keyword_set(debug) and not keyword_set(process_wv) then stop
   if keyword_set(process_wv) then begin
      ;print, 'Wavelength: ', strmid(strtrim(wv,2),0,6)
      goto, process_wv_end
   endif
   
endfor

            
print, 'End time solstice_goes_comp: ', !stime

process_wv_end:


end

