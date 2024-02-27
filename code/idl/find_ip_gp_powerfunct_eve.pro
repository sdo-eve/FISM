;
; NAME: find_gp_power_eve.pro
;
; PURPOSE: to model observed SEE gradual phase flares with the GOES long data
;
;  NOTE:  Need to run in SolarSoft environment for EVE read process to work
;
; MODIFICATION HISTORY:
;	PCC	11/20/04	Program Creation - 'get_see_goes_flare_data.pro'
;	PCC	11/21/04	Modified to model the gradual phase for certain
;		  SEE observed gradual phase flares - 'mod_see_goes_gp.pro'
;	PCC	3/22/04		Changed p_gp to be p_gp=(alog10(goes.long)+8)>0.
;	PCC	12/01/06	Updated for MacOSX 'find_gp_power.pro'
;
;       VERSION 2_01
;       PCC     6/21/12         Updated for SDO/EVE 'find_gp_power_eve.pro'
;       PCC     6/25/12         Combined 'find_gp_power.pro' nad 'mod_eve_goes_gp.pro'
;       PCC     7/23/12         Process for both GP and IP coef and power
;       PCC     7/23 12         Changed name to 'find_ip_gp_powfunct_eve.pro'

;just in case these do not compile correctly, moving them to the top of the file should 
;make it so they compile before the main part of the file runs
;pro pow_funct, x, a, f, pder
;  f=a[0]*(x^a[1])
;  pder1=x^(a[1])  ; df/da[0]
;  pder2=a[0]*(x^a[1])*alog(x) ;df/da[1]
;  pder=[[pder1],[pder2]]
  ;stop
;end

;pro pow_funct_2, x, a, f, pder ; Need to use this for the inverse function
;  f=a[0]*(x^(1./a[1]))  ; Found by running 'find_gp_power.pro'
;  pder=x^(1./a[1])  ; df/da[0]
;  ;stop
;end

;pro sq_funct, x, a, f, pder
;  f=a[0]*(x^8.)
;  pder=x^8.
;end

;pro lin_funct, x, a, f, pder
;  f=a[0]*x
;  pder=x
;end

; The following two are once the power coefficient is found and fixed
;pro pow_funct_fixpow, x, a, f, pder
;  restore, expand_path('$fism_save')+'/gp_power_coef.sav'
;  f=a[0]*(x^c_power)  ; Found by running with keyword '/find_cpow' first
;  pder=x^(c_power)  ; df/da[0]
;  ;stop
;end

;pro pow_funct_2_fixpow, x, a, f, pder ; Need to use this for the inverse function
;  restore, expand_path('$fism_save')+'/gp_power_coef.sav'
;  f=a[0]*(x^(1./c_power))  ; Found by running with keyword '/find_cpow' first
;  pder=x^(1./c_power)   ; df/da[0]
  ;stop
;end

pro find_ip_gp_powerfunct_eve, debug=debug, end_plts_only=end_plts_only, lnfunct=lnfunct, find_cpow=find_cpow, $
          no_new_flr_data=no_new_flr_data, ip_debug=ip_debug, ps_out=ps_out, ylog=ylog

print, 'Running find_ip_gp_powerfunct_eve ', !stime


; Restore the fixed power coefficient if already processed using the
; /find_cpow keyword
if not keyword_set(find_cpow) then restore, expand_path('$fism_save')+'/gp_power_coef.sav'

if keyword_set(no_new_flr_data) then goto, no_new_flrs ; skip reading in flr data
if keyword_set(end_plts_only) then goto, ep_only ; skip processing

print, 'Processing find_gp_power_eve.pro', !stime

if keyword_set(debug) then plot_it=1 else plot_it=0;Set to nonzero for plots
;plot_it=0
ps_out=0 ; Set to nonzero to save .ps plots as 'see_data_rst.ps'
;   ***NOTE: Need to also have plot_it set to nonzero for ps_out to trigger***

;
; Flare Days YYYYDOY and UTC time (sec of day) from 'prgev_to_sav.pro'
;
;t_utc= time in seconds of day of the EVE flare, may be usefull later
restore, expand_path('$fism_save')+'/eve_flare_info.sav'
goes_utc_start=goes_hr_start*3600l+goes_min_start*60
goes_utc_end=goes_hr_end*3600l+goes_min_end*60l
goes_utc_peak=goes_hr_peak*3600l+goes_min_peak*60l

n_flrs=n_elements(yd)

; Get current year day
cur_yd=get_current_yyyydoy()
cur_yr=fix(cur_yd/1000)
; Get GOES 1-min data
nyears=cur_yr-2010
yrs=indgen(nyears+1)+2010;
goes=concat_goes_yrs(yrs)
gps_to_utc_see,goes.time,13,gyear,gdoy,gutc,gmonth,gday,ghour,gmin,gsec
gyd=gyear*1000+gdoy
;stop

; Get GOES daily values
restore, expand_path('$fism_save')+'/goes_daily_pred.sav'
gyd_min=dy_ar

; Restore the fixed power coefficient if already processed using the
; /find_cpow keyword
if not keyword_set(find_cpow) then restore, expand_path('$fism_save')+'/gp_power_coef.sav'

; Get the EVE L3 daily 1a merged file
l3mer_flnm=expand_path('$fism_data')+'/lasp/eve/latest_EVE_L3_merged_1a.ncdf'
read_netcdf, l3mer_flnm, eve, s, a
nwvs=n_elements(eve.spectrummeta.wavelength)
;print, nwvs
wv=eve.spectrummeta.wavelength
fism_wv=wv

ans=''
rat_ar=fltarr(n_flrs,nwvs)
eve_data=fltarr(n_flrs,nwvs)
eve_data_ip=fltarr(n_flrs,nwvs)
eve_day_data=fltarr(n_flrs,nwvs)
flr_peak_delay=fltarr(n_flrs,nwvs)
flr_ip_peak_prev=fltarr(n_flrs,nwvs)
eve_err=fltarr(n_flrs,nwvs)
eve_err_ip=fltarr(n_flrs,nwvs)
goes_data=fltarr(n_flrs)
goes_data_ip=fltarr(n_flrs)
goes_day_data=fltarr(n_flrs)
p_gp=fltarr(n_flrs)
p_ip=fltarr(n_flrs)
e_gp=fltarr(n_flrs,nwvs)
e_ip=fltarr(n_flrs,nwvs)
goes_temp=fltarr(n_flrs,nwvs) ; GOES Temp at peak of EVE wv emission

for j=0,n_flrs-1 do begin ; 744 is 2013309 X flare
	;  Get EVE data and compile into a single array
   ;print, j, 'of', n_flrs
;   if j eq 82 then stop
        if keyword_set(debug) then print, j, ' of  ', n_flrs-1
        if goes_hr_start[j] le goes_hr_end[j] then begin 
           ;print, yd[j]
           two_day=0
           for k=goes_hr_start[j]-1,goes_hr_end[j]+1 do begin
            ;print, k
               yr_st=strmid(strtrim(yd[j],2),0,4)
               dy_st=strmid(strtrim(yd[j],2),4,3)
               if k lt 10 then hr_str='0'+strtrim(k,2) else hr_str=strtrim(k,2)
               if k ge 24 then begin ; for the following 2 hours if end of day
                     hr_str='0'+strtrim(k-24,2) 
                     dy_st=strmid(strtrim(get_next_yyyydoy(yd[j]),2),4,3)
               endif
               if k lt 0 then begin ; for previous hour if start hour 0
                     hr_str='23'
                     dy_st=strmid(strtrim(get_prev_yyyydoy(yd[j]),2),4,3)
               endif
               bdfl_cnt=0;0
               
               miss_eve_data1:
               ;print, expand_path('$EVE_DATA')+'/level2/'+yr_st+'/'+dy_st+'/EVS_L2_'+$
                      ;yr_st+dy_st+'_'+hr_str+'_006_02.fit.gz'
               fl_ex=file_test(expand_path('$EVE_DATA')+'/level2/'+yr_st+'/'+dy_st+'/EVS_L2_'+$
                      yr_st+dy_st+'_'+hr_str+'_006_02.fit.gz')
               
               if fl_ex eq 0 then goto, miss_eve_data
               l2_eve_flnm=file_search(expand_path('$EVE_DATA')+'/level2/'+yr_st+'/'+dy_st+'/EVS_L2_'+$
                      yr_st+dy_st+'_'+hr_str+'_006_02.fit.gz')
               ; check again for EVE data once, if not there then its not available.
               if strlen(l2_eve_flnm) lt 2 then begin
                  ;print, 'Getting file: '
                  ;print, expand_path('$eve_data')+'/level2/'+yr_st+'/'+dy_st+'/EVS_*_'+$
                  ;    hr_str+'_*.fit*'
                  ;get_eve_l2_flare_data, year=yr_st, doy=dy_st
                  ;bdfl_cnt=bdfl_cnt+1
                  ;print, bdfl_count
                  if bdfl_cnt eq 1 then goto, miss_eve_data1 else goto, miss_eve_data 
               endif
               eve_flr_data_orig=eve_read_whole_fits(l2_eve_flnm[0])
               ; Make sure the wv range is from 6-106 nm only, V5_01 was
               ;  from 3-107 nm.
               ;eve_v5_wv=where(eve_flr_data_orig.spectrummeta.wavelength ge 6.0 and $
               ;                eve_flr_data_orig.spectrummeta.wavelength le 106.0)
               if k eq goes_hr_start[j]-1 then begin ; first time through
                      eve_flr_data_tmp=eve_flr_data_orig.spectrum.irradiance;[eve_v5_wv,*]
                      eve_flr_prec_tmp=eve_flr_data_orig.spectrum.precision;[eve_v5_wv,*]
                      eve_flr_sod_tmp=eve_flr_data_orig.spectrum.sod
               endif else begin
                      eve_flr_data_tmp=[[eve_flr_data_tmp],[eve_flr_data_orig.spectrum.irradiance]];[eve_v5_wv,*]]]
                      eve_flr_prec_tmp=[[eve_flr_prec_tmp],[eve_flr_data_orig.spectrum.precision]];[eve_v5_wv,*]]]
                      eve_flr_sod_tmp=[eve_flr_sod_tmp,eve_flr_data_orig.spectrum.sod]
               endelse
            endfor
           
        endif else begin ; Cross Day Boundary
          
           sod_add=3600*24l ; add this to 2nd days' sod
           two_day=1
            for k=goes_hr_start[j]-1,23 do begin ; First Day
               yr_st=strmid(strtrim(yd[j],2),0,4)
               dy_st=strmid(strtrim(yd[j],2),4,3)
               if k lt 10 then hr_str='0'+strtrim(k,2) else hr_str=strtrim(k,2)
               if k lt 0 then begin ; for previous hour if start hour 0
                     hr_str='23'
                     dy_st=strmid(strtrim(yd[j]-1,2),4,3)
               endif
               bdfl_cnt=1;0
               miss_eve_data2:
               fl_ex=file_test(expand_path('$EVE_DATA')+'/level2/'+yr_st+'/'+dy_st+'/EVS_L2_'+$
                      yr_st+dy_st+'_'+hr_str+'_006_02.fit.gz')
               if fl_ex eq 0 then goto, miss_eve_data
               l2_eve_flnm=file_search(expand_path('$EVE_DATA')+'/level2/'+yr_st+'/'+dy_st+'/EVS_L2_'+$
                      yr_st+dy_st+'_'+hr_str+'_006_02.fit.gz')
               if strlen(l2_eve_flnm) lt 2 then begin
                  ;print, 'Getting file: '
                  ;print, expand_path('$eve_data')+'/level2/'+yr_st+'/'+dy_st+'/EVS_*_'+$
                  ;    hr_str+'_*.fit*'
                  ;get_eve_l2_flare_data, year=yr_st, doy=dy_st
                  ;bdfl_cnt=bdfl_cnt+1
                  if bdfl_cnt eq 1 then goto, miss_eve_data2 else goto, miss_eve_data 
               endif
               eve_flr_data_orig=eve_read_whole_fits(l2_eve_flnm[0])
               ; Make sure the wv range is from 6-106 nm only, V5_01 was
               ;  from 3-107 nm.
               eve_v5_wv=where(eve_flr_data_orig.spectrummeta.wavelength ge 6.0 and $
                               eve_flr_data_orig.spectrummeta.wavelength le 106.0)
               if k eq goes_hr_start[j]-1 then begin ; first time through
                      eve_flr_data_tmp=eve_flr_data_orig.spectrum.irradiance;[eve_v5_wv,*]
                      eve_flr_prec_tmp=eve_flr_data_orig.spectrum.precision;[eve_v5_wv,*]
                      eve_flr_sod_tmp=eve_flr_data_orig.spectrum.sod
               endif else begin
                      eve_flr_data_tmp=[[eve_flr_data_tmp],[eve_flr_data_orig.spectrum.irradiance]];[eve_v5_wv,*]]]
                      eve_flr_prec_tmp=[[eve_flr_prec_tmp],[eve_flr_data_orig.spectrum.precision]];[eve_v5_wv,*]]]
                      eve_flr_sod_tmp=[eve_flr_sod_tmp,eve_flr_data_orig.spectrum.sod]
               endelse
           endfor
            for k=0,goes_hr_end[j]+2 do begin ; Second Day, get 2 hours after
               yr_st=strmid(strtrim(get_next_yyyydoy(yd[j]),2),0,4)
               dy_st=strmid(strtrim(get_next_yyyydoy(yd[j]),2),4,3)
               if k lt 10 then hr_str='0'+strtrim(k,2) else hr_str=strtrim(k,2)
               if k ge 24 then begin ; for the following 2 hours
                      hr_str='0'+strtrim(k-24,2)
                      dy_st=strmid(strtrim(get_next_yyyydoy(yd[j]),2),4,3)
               endif
               bdfl_cnt=1;0
               miss_eve_data3:
               fl_ex=file_test(expand_path('$EVE_DATA')+'/level2/'+yr_st+'/'+dy_st+'/EVS_L2_'+$
                      yr_st+dy_st+'_'+hr_str+'_006_02.fit.gz')
               
               if fl_ex eq 0 then goto, miss_eve_data
               l2_eve_flnm=file_search(expand_path('$EVE_DATA')+'/level2/'+yr_st+'/'+dy_st+'/EVS_L2_'+$
                      yr_st+dy_st+'_'+hr_str+'_006_02.fit.gz')
               if strlen(l2_eve_flnm) lt 2 then begin
                  ;print, 'Getting file: '
                  ;print, expand_path('$eve_data')+'/level2/'+yr_st+'/'+dy_st+'/EVS_*_'+$
                  ;    hr_str+'_*.fit*'
                  ;get_eve_l2_flare_data, year=yr_st, doy=dy_st
                  ;bdfl_cnt=bdfl_cnt+1
                  if bdfl_cnt eq 1 then goto, miss_eve_data3 else goto, miss_eve_data 
               endif
               eve_flr_data_orig=eve_read_whole_fits(l2_eve_flnm[0])
               ;eve_v5_wv=where(eve_flr_data_orig.spectrummeta.wavelength ge 6.0 and $
               ;                eve_flr_data_orig.spectrummeta.wavelength le 106.0)
               eve_flr_data_tmp=[[eve_flr_data_tmp],[eve_flr_data_orig.spectrum.irradiance]];[eve_v5_wv,*]]]
               eve_flr_prec_tmp=[[eve_flr_prec_tmp],[eve_flr_data_orig.spectrum.precision]];[eve_v5_wv,*]]]
               eve_flr_sod_tmp=[eve_flr_sod_tmp,eve_flr_data_orig.spectrum.sod+sod_add]
               ;endelse
             endfor
        endelse
    
        ; Convert to 1A bins to match merged data and FISM2 output
        nsod=n_elements(eve_flr_sod_tmp)
        eve_flr_data_tmp_1a=fltarr(nwvs,nsod)
        eve_flr_prec_tmp_1a=fltarr(nwvs,nsod)
        for h=0,nwvs-1 do begin
           wgd_1a=where(eve_flr_data_orig.spectrummeta.wavelength ge wv[h]-0.05 and eve_flr_data_orig.spectrummeta.wavelength lt wv[h]+0.05)
           n1a=n_elements(wgd_1a) ; divide by this to keep as W/m^2/nm but a 1A bins
           eve_flr_data_tmp_1a[h,*]=total(eve_flr_data_tmp[wgd_1a,*],1)/n1a
           eve_flr_prec_tmp_1a[h,*]=total(eve_flr_prec_tmp[wgd_1a,*],1)/n1a/n1a ; mean()/n instead of sum()/n? two div is mean
        endfor


        eve_flr_data=eve_flr_data_tmp_1a  
        eve_flr_prec=eve_flr_prec_tmp_1a
        eve_flr_sod=eve_flr_sod_tmp
	flr_dy=yd[j]
        ; Save for uncertainty calculation performed in 'find_flare_error.pro'
        fism_tmp_dir=expand_path('$tmp_dir')+'/'+strmid(strtrim(yd[j],2),0,4)+'/'
        flnm=fism_tmp_dir+'eve_flr_data_'+strtrim(yd[j],2)+'.sav'
	save, eve_flr_data, eve_flr_prec, eve_flr_sod, flr_dy, file=flnm


	;Find the flare (f_* arrays) and daily average (d_*arrays data
	;
        ; Below line uses GOES peak time and He II 30.38 to find the
        ;  start time (half-way inbetween)

        ; Find peak of IP using 304 line
        ;wv304_tmp=where(wv ge 30.34)
        ;wv304=wv304_tmp[0]
        ;mx304=max(eve_flr_data[wv304,*],wmax_304)
	;if two_day eq 1 and goes_utc_peak[j] lt goes_utc_start[j] then begin
        ;      flr_inds=where(eve_flr_sod ge goes_utc_peak[j]+sod_add)         
        ;endif else begin
        ;      flr_inds=where(eve_flr_sod ge goes_utc_peak[j])
        ;endelse
        ;if wmax_304 lt flr_inds[0] then begin ; search starting halfway between 304 and goes peaks
        ;   st_ind=(flr_inds[0]-wmax_304)/2+wmax_304 ; GP start
        ;   st_ind_ip=wmax_304-(flr_inds[0]-wmax_304) ; IP start
        ;   if st_ind_ip lt 0 then st_ind_ip=0
        ;   end_ind_ip=st_ind ; end IP equals start of GP
        ;endif else begin ; 30.4 peak after goes, just use goes peak
        ;   st_ind=flr_inds[0]
        ;   ; IP is then the start of the goes GP and halfway between
        ;   ;   the start and the peak
        ;   flr_inds_ip=where(eve_flr_sod ge goes_utc_start[j])
        ;   st_ind_ip=flr_inds_ip[0]
        ;   end_ind_ip=st_ind+(st_ind-st_ind_ip)/2
        ;endelse
        ; Make sure to end the GP before the start of the next flare
        ;if j+1 ne n_flrs then begin ; make sure j+1 index is valid
        ;   if yd[j] eq yd[j+1] and eve_flr_sod[flr_inds[n_elements(flr_inds)-1]] gt goes_utc_start[j+1] then begin
        ;      end_ind_tmp=where(eve_flr_sod ge goes_utc_start[j+1])
        ;      end_ind=end_ind_tmp[0]
        ;      if end_ind lt st_ind then end_ind=st_ind+1 ; Only occur when next flare is 10 mins from peak 
        ;   endif else begin
        ;      end_ind=flr_inds[n_elements(flr_inds)-1]
        ;   endelse
        ;endif
        ;f_err=fltarr(nwvs)
        ;f_sp=fltarr(nwvs)
        ;f_sp_ip=fltarr(nwvs)
        ;f_err_ip=fltarr(nwvs)

	;
	; Get the GOES Data for the EVE observed flare
	;
	
	g_dy_min_ind=where(gyd_min eq yd[j])
	g_dy_min=goes_daily_l(g_dy_min_ind)
	goes_day_data[j]=g_dy_min
        if two_day eq 1 then begin
            goes_ind_1=where(gyd eq yd[j] and gutc ge goes_utc_start[j])
            if goes_ind_1[0] eq -1 then goto, nogoes
            goes_ind_2=where(gyd eq yd[j]+1 and gutc le goes_utc_end[j])
            if goes_ind_2[0] eq -1 then goto, nogoes
            goes_ind=[goes_ind_1,goes_ind_2]
            goes_flr_utc=[gutc[goes_ind_1],gutc[goes_ind_2]+(3600*24l)]
            if goes_utc_peak[j] gt goes_utc_start[j] then begin ; peak on first day
               goes_post_ind=where(goes_flr_utc ge goes_utc_peak[j])
            endif else begin ; peak on second day
               goes_post_ind=where(goes_flr_utc ge goes_utc_peak[j]+(3600*24l))
            endelse
        endif else begin
            goes_ind=where(gyd eq yd[j] and gutc ge goes_utc_start[j] and gutc $
		le goes_utc_end[j])        
            if goes_ind[0] eq -1 then goto, nogoes
            goes_flr_utc=gutc[goes_ind]
            goes_post_ind=where(goes_flr_utc ge goes_utc_peak[j])
        endelse
	goes_flr_flx=goes[goes_ind].long
        goes_flr_flx_short=goes[goes_ind].short
        goes_flr_sat=goes[goes_ind].sat
	peak_goes=max(goes_flr_flx)
       
        ; Get the EVE daily data
        d_weve=where(eve.mergeddata.yyyydoy eq yd[j])
	d_av=eve.mergeddata.sp_irradiance[*,d_weve]
	eve_day_data[j,*]=d_av

        ; Just use the maximum value for each wavlength for now; 
        ; Need to update with a time dependent decay based on GOES T
        ;for p=0,nwvs-1 do begin
        ;   ; only look after the GOES Peak to eliminate IP maxes
        ;   if end_ind-st_ind gt 6 then begin 
        ;      maxwv=max(smooth(eve_flr_data[p,st_ind:end_ind],5),wmax_wv)
        ;   endif else begin
        ;      maxwv=max(eve_flr_data[p,st_ind:end_ind],wmax_wv)
        ;   endelse
        ;   f_sp[p]=maxwv
        ;   f_err[p]=eve_flr_prec[p,st_ind+wmax_wv]

        ; Interpolate GOES GP data onto FISM time scale
        goes_fismtimes_int=interpol(goes_flr_flx, goes_flr_utc, eve_flr_sod)>0.0
        goes_fismtimes_int_short=interpol(goes_flr_flx_short, goes_flr_utc, eve_flr_sod)>0.0
        goes_sat_int=intarr(n_elements(goes_fismtimes_int))+median(goes_flr_sat)

        ; Use function to fit IP+GP GOES data to flare
        ;   Includes GP time shift for Temp
        goes_mx_gp=max(goes_fismtimes_int, wmax_goes_gp)
        goes_deriv=deriv(eve_flr_sod, goes_fismtimes_int)>0.0
        goes_mx_ip=max(goes_deriv, wmax_goes_ip)
        nwvs=n_elements(eve_flr_data[*,0])
        ans=''
        p_ip[j]=goes_mx_ip
        p_gp[j]=goes_mx_gp
        f_sp=fltarr(nwvs)
        for p=0,nwvs-1 do begin
          
              eve_wv_ts=smooth(eve_flr_data[p,*]-d_av[p],3)
              ;help, eve_wv_ts
              ;help, eve_wv_ts
                                ; Find GP time/thermal shift for GOES
              end_of_flr=(goes_utc_end[j]-goes_utc_start[j])/10                              ; eliminate bad data that is well after flare
              ;print, end_of_flr
              if end_of_flr lt 0.0 then end_of_flr=(goes_utc_end[j]+86400-goes_utc_start[j])/10 ; Cross day 
              if wmax_goes_gp+end_of_flr gt n_elements(eve_wv_ts)-1 then end_of_flr=n_elements(eve_wv_ts)-wmax_goes_gp-1
              ;print, wmax_goes_gp
              ;print, wmax_goes_gp+end_of_flr
              max_eve=max(eve_wv_ts[wmax_goes_gp:wmax_goes_gp+end_of_flr],wmax_eve) ; make sure after GOES GP Peak
              ;print, wmax_eve
              wmax_eve=wmax_eve>0                             ; make sure only positive shifts are allowed
                                ; Scale GOES to match EVE at peak of GP and IP as first guess
              goes_ts_gp_st=shift(goes_fismtimes_int*eve_wv_ts[wmax_goes_gp+wmax_eve]/goes_mx_gp,wmax_eve)
              ; Subtract off EVE-scaled GOES time series to eliminate GP
              ip_eve_wv_ts=(eve_wv_ts-goes_ts_gp_st)>0.0
              goes_ts_ip_st=goes_deriv*ip_eve_wv_ts[wmax_goes_ip]/goes_mx_ip
              goes_tot=goes_ts_gp_st+goes_ts_ip_st
              if keyword_set(debug) then begin
                 temp_g=fltarr(n_elements(goes_fismtimes_int))
                 for m=0,n_elements(goes_fismtimes_int)-1 do begin     
                      goes_get_chianti_temp, goes_fismtimes_int_short[m]/goes_fismtimes_int[m]>0.0, $
                                        temp_gt, sat=goes_sat_int[m]
                      temp_g[m]=temp_gt
                 endfor              
                 cc=independent_color()
                 plot, eve_flr_sod, eve_wv_ts, title='Wavelength: '+strtrim(wv[p])+'nm; Temp: '+strtrim(temp_g[wmax_goes_gp+wmax_eve])                  
                 oplot, eve_flr_sod, goes_tot, color=cc.red
                 oplot, eve_flr_sod, goes_ts_gp_st, color=cc.green
                 oplot, eve_flr_sod, goes_ts_ip_st, color=cc.blue
                 plot, eve_flr_sod, temp_g, color=cc.orange, /noerase
                 read, ans, prompt='Next wv?'
              endif
           
           ; Save the shift the GOES data based on the GP shift found above
           flr_peak_delay[j,p]=(wmax_eve*10.)>0.0 ; save the peak dealy for each wv from GOES peak
           
           eve_data_ip[j,p]=eve_wv_ts[wmax_goes_ip]
           eve_err_ip[j,p]=eve_flr_prec[p,wmax_goes_ip]
           eve_data[j,p]=max_eve
           eve_err[j,p]=eve_flr_prec[p,wmax_goes_gp+wmax_eve]

           ; Find the GOES Temperature at the EVE peak for each EVE wv
           goes_get_chianti_temp, goes_fismtimes_int_short[wmax_goes_gp+wmax_eve]/goes_fismtimes_int[wmax_goes_gp+wmax_eve], $
                 temp_tmp, sat=median(goes_flr_sat)
           if eve_data[j,p] gt 0.0 then goes_temp[j,p]=temp_tmp ; Only save if data is valid

           ; Stop to debug if /debug is set to make sure the actual
           ; Peak values are begin found
          ;    print, yd[j]
          ; if yd[j] eq 2011068 and goes_utc_start[j] gt 82000 then begin
          ;    cc=independent_color()
          ;    plot, eve_flr_sod, eve_flr_data[p,*], title=strtrim(wv[p])+' nm'
          ;    print, 'Max Value: ', maxwv, ' at Time: ', eve_flr_sod[st_ind+wmax_wv] +' sec'
          ;    oplot, [eve_flr_sod[st_ind+wmax_wv],eve_flr_sod[st_ind+wmax_wv]], [1e-10,1e1]
          ;    oplot, [eve_flr_sod[st_ind],eve_flr_sod[st_ind]], [1e-10,1e1], linestyle=1
          ;    oplot, [eve_flr_sod[end_ind],eve_flr_sod[end_ind]], [1e-10,1e1], linestyle=1
          ;    oplot, eve_flr_sod, goes_eve_match, color=cc.blue
          ;    oplot, eve_flr_sod, eve_ip_data, color=cc.green
          ;    plot,  eve_flr_sod, eve_flr_data[wv304,*],color=cc.red,/noerase; plot 304
          ;    ;stop
          ;    read, ans, prompt='Next? '
          ;  endif
        endfor
	f_rat=eve_data[j,*]/d_av
	rat_ar[j,*]=f_rat

;	if goes_post_ind[0] eq -1 then begin
;           goes_bt=goes_flr_utc[n_elements(goes_flr_utc)-1]
;           goes_bf=goes_flr_flx[n_elements(goes_flr_utc)-1]
;           goes_at=goes_flr_utc[n_elements(goes_flr_utc)-1]
;           goes_af=goes_flr_flx[n_elements(goes_flr_utc)-1]
;        endif else if goes_post_ind[0] eq 0 then begin
;           goes_bt=goes_flr_utc[goes_post_ind[0]]
;           goes_bf=goes_flr_flx[goes_post_ind[0]]
;           goes_at=goes_flr_utc[goes_post_ind[0]]
;           goes_af=goes_flr_flx[goes_post_ind[0]]
;        endif else begin
;           goes_bt=goes_flr_utc[goes_post_ind[0]-1]
;           goes_bf=goes_flr_flx[goes_post_ind[0]-1]
;           goes_at=goes_flr_utc[goes_post_ind[0]]
;           goes_af=goes_flr_flx[goes_post_ind[0]]
;        endelse;
;	tdiff=goes_at-goes_bt;
;	fdiff=goes_af-goes_bf
;	wght=(goes_utc_peak[j]-goes_bt)/tdiff  ; weighting no longer applicable with EVE's ~100% duty cycle
;	wflx=wght*fdiff
;	goes_flux_evetime=goes_bf+wflx
;	goes_data[j]=goes_flux_evetime
;	g_rat=peak_goes/g_dy_min
;	gs_rat=goes_flux_evetime/g_dy_min
;	s_rat=g_rat/gs_rat
;	p_f_rat=((f_rat-1.)*s_rat[0])+1.
;	p_f_sp=d_av*p_f_rat

	
        ; Find GOES derivative
;        goes_deriv=deriv(goes_flr_utc,goes[goes_ind].long) 
;        goes_data_ip[j]=max(goes_deriv)
        
	if plot_it ne 0 then begin
		;if ps_out ne 0 and j eq 0 then open_ps, '$fism_plots/see_flr_data_clv.ps'
		cc=independent_color()
		!p.multi=[0,1,3]
		tlt=yd[j]
		plot_io, wv, f_sp, yr=[1e-6,1e-2], title=tlt, charsize=2.4, $
			xtitle='Red: Daily Average, Black: Flare, Blue: Peak EVE', $
			psym=10, ytitle='Flux (W/m^2/nm)'
		oplot, wv, d_av, color=cc.red, psym=10
		oplot, wv, p_f_sp, color=cc.blue, psym=10
		oplot, wv, f_sp_ip, color=cc.green, psym=10
		plot_io, wv, f_rat, yr=[1.0,10.0], psym=10, ytitle='flare/av', $
			xtitle='Wavelength (nm)', charsize=2.4
		oplot, wv, fltarr(195)+1., linestyle=2
		oplot, wv, p_f_rat, color=cc.blue, psym=10
		plot_io, goes_flr_utc, goes_flr_flx, charsize=2.4, xs=1, $
			xtitle='Flux Scaling Factor: '+strtrim(gs_rat,2)
		oplot, fltarr(10000)+goes_utc_peak[j]+60,findgen(10000)*1e-6, linestyle=3
		
		;print, j
		if ps_out eq 0 then read, ans, prompt='Next Flare?'
	endif

	ans=''
	miss_eve_data:
        nogoes:
        ;stop
endfor

;if ps_out ne 0 then close_ps

; Subtract of daily data to get flare-only contributions 
;   NOTE: Not needed for GOES IP as it is a derivative
;p_gp=fltarr(n_flrs)
;e_gp=fltarr(n_flrs,nwvs)
;e_ip=fltarr(n_flrs,nwvs)
;for x=0,n_flrs-1 do begin
;	;e_gp[x,*]=reform(see_data[x,*])/reform(see_day_data[x,*])-1.
;	e_gp[x,*]=reform(eve_data[x,*])-reform(eve_day_data[x,*])
;	e_ip[x,*]=reform(eve_data_ip[x,*])-reform(eve_day_data[x,*])
;	;p_gp[x,*]=goes_data[x]/goes_day_data[x]-1.;
;	;p_gp[x,*]=(alog10(goes_data[x])+9)>0.;
;	p_gp[x,*]=(goes_data[x]-goes_day_data[x])>0.0
;endfor
;p_ip=goes_data_ip

; Get the median delay time of the GP to use
;   This needs to be more accurately quantified (based on GOES Temp?)
med_gp_delay_time=fltarr(nwvs)
av_gp_delay_time=fltarr(nwvs)
print, nwvs
for i=0,nwvs-1 do begin
   gd_flr_del=where(flr_peak_delay[*,i] gt 0.0)
   ;print, flr_peak_delay
   med_gp_delay_time[i]=median(flr_peak_delay[gd_flr_del,i])
   av_gp_delay_time[i]=mean(flr_peak_delay[gd_flr_del,i])
endfor

; Find the median and average GOES temperature for each EVE wv
med_goes_temp=fltarr(nwvs)
av_goes_temp=fltarr(nwvs)
for n=0,nwvs-1 do begin
   gdwv_t=where(goes_temp[*,n] gt 0.0)
   med_goes_temp[n]=median(goes_temp[gdwv_t,n])
   av_goes_temp[n]=mean(goes_temp[gdwv_t,n])
endfor

anwv_chk=''

e_gp=eve_data
e_ip=eve_data_ip

print, 'Saving mod_grad_phase_flrs.sav'
save, rat_ar, yd, goes_utc_peak, eve_data, eve_data_ip, wv, goes_data, eve_day_data, goes_day_data,$
	clv, e_gp, p_gp, e_ip, p_ip, flr_peak_delay, goes_data_ip, med_gp_delay_time, av_gp_delay_time, $
        goes_temp, av_goes_temp, med_goes_temp, file=expand_path('$fism_save')+'/mod_grad_phase_flrs.sav'

; Start here if no new flare data to read in above
no_new_flrs:
if keyword_set(no_new_flr_data) then begin
   restore, expand_path('$fism_save')+'/mod_grad_phase_flrs.sav'
   nwvs=n_elements(eve_data[0,*])
endif

;
;
;  Gradual Phase Fitting
;
;


c_gp=fltarr(3,nwvs)
c_gp[0,*]=wv
c_gp_m=fltarr(3,nwvs)
c_gp_m[0,*]=wv
c_gp_l=fltarr(3,nwvs)
c_gp_l[0,*]=wv
c_gp_c=fltarr(3,nwvs)
c_gp_c[0,*]=wv
abs_dif_gp=fltarr(nwvs)
; Also save the 1-sigma coefficients - NOTE: PCC, 4/13/2020,
;                                      sigma doesn't seem to work for Curvefit
sigma_c_gp=fltarr(3,nwvs)
sigma_c_gp[0,*]=wv
sigma_c_gp_m=fltarr(3,nwvs)
sigma_c_gp_m[0,*]=wv
sigma_c_gp_l=fltarr(3,nwvs)
sigma_c_gp_l[0,*]=wv
sigma_c_gp_c=fltarr(3,nwvs)
sigma_c_gp_c[0,*]=wv
; Also save the yerror, which is the standard percent error of the fit
yer_c_gp=fltarr(nwvs)
yer_c_gp_m=fltarr(nwvs)
yer_c_gp_l=fltarr(nwvs)
yer_c_gp_c=fltarr(nwvs)

; Fit power function to all MEGS wvs (>5 nm), linear function to XPS
; wvs (<5nm)
st_pow=where(wv ge 5.0)	
;print, 'Fitting Power Function to Gradual Phase...'
for k=st_pow[0],nwvs-1 do begin
	;print, k
        gd=where(p_gp gt 0.0 and p_gp le 7.e-4 and e_gp[*,k] gt 0.0)
        ; Now doing a linear fit of the ln of x and y, e.g.:
        ; y=a*x^b (original) is now y'=a'+b*x' where y'=ln(y),x'=ln(x),and a'=ln(a)
        ln_p_gp=alog(p_gp)
        ln_e_gp=alog(e_gp)
        wght_pois=sqrt(abs(ln_e_gp)) ;alog((e_gp)*0.0+0.2);0.1;*(abs(ln_e_gp)); sqrt(abs(ln_e_gp)) ;1./e_gp 
	if gd[0] eq -1 or n_elements(gd) lt 4 then goto, nogd
	limb_ind=where(clv[gd] eq 3)
	cent_ind=where(clv[gd] eq 1); or clv[gd] eq 2)
	mid_ind=where(clv[gd] eq 2)
	all_ind=where(clv[gd] eq 0 or clv[gd] eq 1 or clv[gd] eq 2 or clv[gd] eq 3)
	; Limb fit
        if n_elements(limb_ind) lt 3 then goto, bdlf
        limb_fit2=poly_fit(ln_p_gp[gd[limb_ind]], ln_e_gp[gd[limb_ind],k], 1, $
              sigma=sigma_l_2, measure_errors=wght_pois[gd[limb_ind],k], $
              yerror=yer_l, status=stat, yband=yband_limbfit2, yfit=yf_l)
        ;limb_fit1=poly_fit(ln_p_gp[gd[limb_ind]], ln_e_gp[gd[limb_ind],k], 1, $
        ;      sigma=sigma_l, measure_errors=yband_limbfit2, $
        ;      yerror=yer_l, status=stat, yband=yband_limbfit1, yfit=yf_l)
        ;c_gp_l[1:2,k]=[exp(limb_fit1[0]),limb_fit1[1]]
        ;sigma_c_gp_l[1:2,k]=[exp(sigma_l[0]+limb_fit1[0]),limb_fit1[1]-sigma_l[1]]
        c_gp_l[1:2,k]=[exp(limb_fit2[0]),limb_fit2[1]]
        sigma_c_gp_l[1:2,k]=[exp(sigma_l_2[0]+limb_fit2[0]),limb_fit2[1]-sigma_l_2[1]]
        ; Calculate the percent error
        mody=exp(yf_l)
        measy=exp(ln_e_gp[gd[limb_ind],k])
        gder=where((mody-measy)/measy lt 10.)
        perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
        yer_c_gp_l[k]=perirerr
        bdlf:
        
	; Central Fit
        if n_elements(cent_ind) lt 3 then goto, bdcf
        cent_fit2=poly_fit(ln_p_gp[gd[cent_ind]], ln_e_gp[gd[cent_ind],k], 1, $
               sigma=sigma_c2, measure_errors=wght_pois[gd[cent_ind],k], $
               yerror=yer_c, status=stat, yband=yband_cent_fit2, yfit=yf_c)
        ;cent_fit1=poly_fit(ln_p_gp[gd[cent_ind]], ln_e_gp[gd[cent_ind],k], 1, $
        ;       sigma=sigma_c, measure_errors=yband_cent_fit2, $
        ;       yerror=yer_c, status=stat, yband=yband_cent_fit1, yfit=yf_c)
        ;c_gp_c[1:2,k]=[exp(cent_fit1[0]),cent_fit1[1]]
        ;sigma_c_gp_c[1:2,k]=[exp(sigma_c[0]+cent_fit1[0]),cent_fit1[1]-sigma_c[1]]
        c_gp_c[1:2,k]=[exp(cent_fit2[0]),cent_fit2[1]]
        sigma_c_gp_c[1:2,k]=[exp(sigma_c2[0]+cent_fit2[0]),cent_fit2[1]-sigma_c2[1]]
        ; Calculate the percent error
        mody=exp(yf_c)
        measy=exp(ln_e_gp[gd[cent_ind],k])
        gder=where((mody-measy)/measy lt 10.)
        perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
        yer_c_gp_c[k]=perirerr
        bdcf:
	
	; Mid Fit
        if n_elements(mid_ind) lt 3 then goto, bdmf
        mid_fit2=poly_fit(ln_p_gp[gd[mid_ind]], ln_e_gp[gd[mid_ind],k], 1, $
		sigma=sigma_m2, measure_errors=wght_pois[gd[mid_ind],k], $
		yerror=yer_m, status=stat, yband=yband_mid_fit2, yfit=yf_m)
        ;mid_fit1=poly_fit(ln_p_gp[gd[mid_ind]], ln_e_gp[gd[mid_ind],k], 1, $
        ;       sigma=sigma_m, measure_errors=yband_mid_fit2, $
	;	yerror=yer_m, status=stat,yfit=yf_m)
        ;c_gp_m[1:2,k]=[exp(mid_fit1[0]),mid_fit1[1]]
        ;sigma_c_gp_m[1:2,k]=[exp(sigma_m[0]+mid_fit1[0]),mid_fit1[1]-sigma_m[1]]
        c_gp_m[1:2,k]=[exp(mid_fit2[0]),mid_fit2[1]]
        sigma_c_gp_m[1:2,k]=[exp(sigma_m2[0]+mid_fit2[0]),mid_fit2[1]-sigma_m2[1]]
        ; Calculate the percent error
        mody=exp(yf_m)
        measy=exp(ln_e_gp[gd[mid_ind],k])
        gder=where((mody-measy)/measy lt 10.)
        perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
        yer_c_gp_m[k]=perirerr
        bdmf:

	; All Fit
        all_fit2=poly_fit(ln_p_gp[gd[all_ind]], ln_e_gp[gd[all_ind],k], 1, $
		sigma=sigma_a2, measure_errors=wght_pois[gd[all_ind],k], $
		yerror=yer_a, status=stat, yband=yb_a, yfit=yf_a, chisq=cs_a)
        ;all_fit1=poly_fit(ln_p_gp[gd[all_ind]], ln_e_gp[gd[all_ind],k], 1, $
	;	sigma=sigma_a, measure_errors=yb_a, $
	;	yerror=yer_a, status=stat, yband=yb_a2, yfit=yf_a, chisq=cs_a)
        ;c_gp[1:2,k]=[exp(all_fit1[0]),all_fit1[1]]
        ;sigma_c_gp[1:2,k]=[exp(sigma_a[0]+all_fit1[0]),all_fit1[1]-sigma_a[1]]
        c_gp[1:2,k]=[exp(all_fit2[0]),all_fit2[1]]
        sigma_c_gp[1:2,k]=[exp(sigma_a2[0]+all_fit2[0]),all_fit2[1]-sigma_a2[1]]
        ; Calculate the percent error
        mody=exp(yf_a)
        measy=exp(ln_e_gp[gd[all_ind],k])
        gder=where((mody-measy)/measy lt 10.)
        perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
        yer_c_gp[k]=perirerr

        ; Replace bad central fits with 'alldata' fits if it is good
        if c_gp_c[1,k] lt 0 or c_gp_c[2,k] gt 1000 then begin
           if c_gp[1,k] gt 0 or c_gp[2,k] lt 1000 then begin
              c_gp_c[1,k]=c_gp[1,k]
              c_gp_c[2,k]=c_gp[2,k]
              sigma_c_gp_c[*,k]=sigma_c_gp[*,k]
              yer_c_gp_c[k]=yer_c_gp[k]
           endif else begin ; bad all fit, set to zero
              c_gp_c[1,k]=0.0
              c_gp_c[2,k]=0.0
              c_gp[1,k]=0.0
              c_gp[2,k]=0.0
           endelse              
        endif
        ; Replace bad limb fits with 'alldata' fits if it is good
        if c_gp_l[1,k] lt 0 or c_gp_l[2,k] gt 1000 then begin
           if c_gp[1,k] gt 0 or c_gp[2,k] lt 1000 then begin
              c_gp_l[1,k]=c_gp[1,k]
              c_gp_l[2,k]=c_gp[2,k]
              sigma_c_gp_l[*,k]=sigma_c_gp[*,k]
              yer_c_gp_l[k]=yer_c_gp[k]
           endif else begin ; bad all fit, set to zero
              c_gp_l[1,k]=0.0
              c_gp_l[2,k]=0.0
           endelse              
        endif
        ; Replace bad mid fits with 'alldata' fits if it is good
        if c_gp_m[1,k] lt 0 or c_gp_m[2,k] gt 1000 then begin
           if c_gp[1,k] gt 0 or c_gp[2,k] lt 1000 then begin
              c_gp_m[1,k]=c_gp[1,k]
              c_gp_m[2,k]=c_gp[2,k]
              sigma_c_gp_m[*,k]=sigma_c_gp[*,k]
              yer_c_gp_m[k]=yer_c_gp[k]
           endif else begin ; bad all fit, set to zero
              c_gp_m[1,k]=0.0
              c_gp_m[2,k]=0.0
           endelse              
        endif

        ; If limb fit power is greater the central fit,
        ;   just use the all flare fit as there should never be
        ;   limb brightening and will give better fit statistics
        if c_gp_l[2,k] gt c_gp_c[2,k] or c_gp_l[1,k] gt c_gp_c[1,k] then begin
           c_gp_l[1:2,k]=c_gp[1:2,k]
           c_gp_c[1:2,k]=c_gp[1:2,k]
           sigma_c_gp_l[*,k]=sigma_c_gp[*,k]
           sigma_c_gp_c[*,k]=sigma_c_gp[*,k]
           yer_c_gp_c[k]=yer_c_gp[k]
           yer_c_gp_l[k]=yer_c_gp[k]
        endif

        ; If predicted 1sig value at X1 level is >200% then there is no
        ; true increase or fit to the data, so zero out contributions
        ; from flares - mostly happens in MEGS-B where there is 
        ; insufficent data at flare peaks (gp) or prior to peak (ip)
        ;x1f=c_gp[1,k]*(1.e-4)^c_gp[2,k]
        ;x1f_sig=(sigma_c_gp[1,k])*(1.e-4)^sigma_c_gp[2,k]
        ;x1f_sig_percent=(x1f_sig-x1f)/x1f*100.
        ;if x1f_sig_percent gt 200 then begin
        if yer_c_gp[k] gt 2 or c_gp_c[2,k] lt 0.03 then begin
           c_gp_l[1,k]=0.0      ; just set coefficeint to 0.0
           c_gp_m[1,k]=0.0
           c_gp_c[1,k]=0.0
           c_gp[1,k]=0.0
           sigma_c_gp_l[1,k]=0.0
           sigma_c_gp_m[1,k]=0.0
           sigma_c_gp_c[1,k]=0.0
           sigma_c_gp[1,k]=0.0
           yer_c_gp[k]=0.0
           yer_c_gp_c[k]=0.0
           yer_c_gp_l[k]=0.0
           yer_c_gp_m[k]=0.0
        endif
        
        if keyword_set(debug) then begin
           if keyword_set(ps_out) then open_ps, '$fism_analysis/plots/gp_fit/gp_fit_wv'+strtrim(wv[k],2)+'.ps', /landscape, /color
           !p.multi=0
           cc=independent_color()
           xlf=findgen(10000)*.0000001
           if not keyword_set(ylog) then begin
              plot, p_gp[gd], e_gp[gd,k], psym=4, charsize=1.9, $
		xtitle='E!DGP,P!N', ytitle='E!DGP,Meas!N', title='Wavelength: '+$
                    strmid(strtrim(wv[k],2),0,5)+' nm', /xlog
           endif else begin
              plot, p_gp[gd], e_gp[gd,k], psym=4, charsize=1.9, $
		xtitle='E!DGP,P!N', ytitle='E!DGP,Meas!N', title='Wavelength: '+$
		strmid(strtrim(wv[k],2),0,5)+' nm', /xlog, /ylog
           endelse
           limb_ind=where(clv[gd] eq 3)
           cnt_ind=where(clv[gd] eq 1)
           mid_ind=where(clv[gd] eq 2)
                                ; Overplot the color-cordinated symbols
           if n_elements(limb_ind) lt 3 or n_elements(cnt_ind) lt 3 or n_elements(mid_ind) lt 3 then goto, bdplts
           oplot, p_gp[gd[limb_ind]], e_gp[gd[limb_ind],k], psym=4, color=cc.green
           oplot, p_gp[gd[cnt_ind]], e_gp[gd[cnt_ind],k], psym=4, color=cc.red
           oplot, p_gp[gd[mid_ind]], e_gp[gd[mid_ind],k], psym=4, color=cc.blue
           oplot, xlf, c_gp_c[1,k]*(xlf^c_gp_c[2,k]), color=cc.red
           oplot, xlf, (c_gp_c[1,k]*(xlf^c_gp_c[2,k]))*(1+yer_c_gp_c[k]), color=cc.red, linestyle=1
           ;oplot, xlf, sigma_c_gp_c[1,k]*(xlf^sigma_c_gp_c[2,k]), color=cc.red, linestyle=1
           oplot, xlf, c_gp_l[1,k]*(xlf^c_gp_l[2,k]), color=cc.green
           oplot, xlf, c_gp_m[1,k]*(xlf^c_gp_m[2,k]), color=cc.blue
           oplot, xlf, c_gp[1,k]*(xlf^c_gp[2,k])
           oplot, xlf, c_gp[1,k]*(xlf^c_gp[2,k])*(1+yer_c_gp[k]), linestyle=1
           ;oplot, xlf, (sigma_c_gp[1,k])*(xlf^(sigma_c_gp[2,k])), linestyle=1 ; +1 sigma uncertainty
           ;oplot, xlf, (sigma_c_gp[1,k])*(xlf^(sigma_c_gp[2,k])), linestyle=1 ; -1 sigma uncertainty
           ;oplot, xlf, (c_gp[1,k]+sigma_c_gp[1,k])*(xlf^(c_gp[2,k]-sigma_c_gp[2,k])), linestyle=1 ; +1 sigma uncertainty
           ;oplot, xlf, (c_gp[1,k]-sigma_c_gp[1,k])*(xlf^(c_gp[2,k]+sigma_c_gp[2,k])), linestyle=1 ; -1 sigma uncertainty
           ;oplot, xlf, c_gp[1,k]*(xlf^c_gp[2,k])+yer_c_gp[k], linestyle=1 ; +1 sigma uncertainty
           ;oplot, xlf, c_gp[1,k]*(xlf^c_gp[2,k])-yer_c_gp[k], linestyle=1 ; -1 sigma uncertainty
           
           maxx=max(p_gp[gd], min=minx)
           maxy=max(e_gp[gd,k], min=miny)
           xout=0.2; ((maxx-minx)*.5)+minx
           xyouts, xout, 0.85, 'Red: Central Flare Fit', charsize=1.7, color=cc.red, /normal
           xyouts, xout, 0.8, 'Green: Limb Flare Fit', charsize=1.7, color=cc.green, /normal
           xyouts, xout, 0.75, 'Blue: Mid Flare Fit', charsize=1.7, color=cc.blue, /normal
           xyouts, xout, 0.7, 'White: All Flare Fit', charsize=1.7, /normal
           print, c_gp_c[*,k]
           print, sigma_c_gp_c[*,k]
           x1f=c_gp[1,k]*(1.e-4)^c_gp[2,k]
           x1f_sig=(sigma_c_gp[1,k])*(1.e-4)^sigma_c_gp[2,k]
           print, yer_c_gp[k]*100.
           ;print, 'X1 1sig: ', (x1f_sig-x1f)/x1f*100., '%'
                                ;stop
           bdplts:
           ans=''
           if keyword_set(ps_out) then close_ps else read, ans, prompt='Next (Return, or 2 to stop)? '
           if ans eq 2 then stop
        endif

     nogd:
endfor

	

;
;
; Impulsive Phase Fitting
;
;

c_ip=fltarr(3,nwvs)
c_ip[0,*]=wv
c_ip_m=fltarr(3,nwvs)
c_ip_m[0,*]=wv
c_ip_l=fltarr(3,nwvs)
c_ip_l[0,*]=wv
c_ip_c=fltarr(3,nwvs)
c_ip_c[0,*]=wv
sigma_c_ip=fltarr(3,nwvs)
sigma_c_ip[0,*]=wv
sigma_c_ip_m=fltarr(3,nwvs)
sigma_c_ip_m[0,*]=wv
sigma_c_ip_l=fltarr(3,nwvs)
sigma_c_ip_l[0,*]=wv
sigma_c_ip_c=fltarr(3,nwvs)
sigma_c_ip_c[0,*]=wv
abs_dif_ip=fltarr(nwvs)
; Also save the yerror, which is the standard percent error of the fit
yer_c_ip=fltarr(nwvs)
yer_c_ip_m=fltarr(nwvs)
yer_c_ip_l=fltarr(nwvs)
yer_c_ip_c=fltarr(nwvs)

; Fit power function to all wvs for Impulsive Phase
;print, 'Fitting Power Function to Impulsive Phase...'
for k=0,nwvs-1 do begin
	;print, k
	gd=where(p_ip gt 1.e-9 and e_ip[*,k] gt 0.0)
        ; Now doing a linear fit of the ln of x and y, e.g.:
        ; y=a*x^b (original) is now y'=a'+b*x' where y'=ln(y),x'=ln(x),and a'=ln(a)
        ln_p_ip=alog(p_ip)
        ln_e_ip=alog(e_ip)
        wght_pois_ip=sqrt(abs(ln_e_ip)) ;1./e_gp ; set curvefit weight to statistical (poission) weighting, or 1/Y 
	if gd[0] eq -1 or n_elements(gd) lt 4 then goto, nogd_ip
	limb_ind=where(clv[gd] eq 3)
	cent_ind=where(clv[gd] eq 1); or clv[gd] eq 2)
	mid_ind=where(clv[gd] eq 2)
	all_ind=where(clv[gd] eq 0 or clv[gd] eq 1 or clv[gd] eq 2 or clv[gd] eq 3)
	; Limb fit
        if n_elements(limb_ind) lt 3 then goto, bdl_ip
        ;limb_fit1=poly_fit(ln_p_ip[gd[limb_ind]], ln_e_ip[gd[limb_ind],k], 1, $
	;		sigma=sigma_l, $ ;measure_errors=wght_pois_ip[gd[limb_ind],k], $
	;		status=stat)
        limb_fit2=poly_fit(ln_p_ip[gd[limb_ind]], ln_e_ip[gd[limb_ind],k], 1, $
			sigma=sigma_l2, measure_errors=wght_pois_ip[gd[limb_ind],k], $
			status=stat, yband=yband_limb_fit2, yfit=yf_l)
        ;limb_fit1=poly_fit(ln_p_ip[gd[limb_ind]], ln_e_ip[gd[limb_ind],k], 1, $
	;		sigma=sigma_l, measure_errors=yband_limb_fit2, $
	;		status=stat, yband=yband_limb_fit1)
        ;c_ip_l[1:2,k]=[exp(limb_fit1[0]),limb_fit1[1]]
        ;sigma_c_ip_l[1:2,k]=[exp(limb_fit1[0]+sigma_l[0]),limb_fit1[1]-sigma_l[1]]
        c_ip_l[1:2,k]=[exp(limb_fit2[0]),limb_fit2[1]]
        sigma_c_ip_l[1:2,k]=[exp(limb_fit2[0]+sigma_l2[0]),limb_fit2[1]-sigma_l2[1]]
        ; Calculate the percent error
        mody=exp(yf_l)
        measy=exp(ln_e_ip[gd[limb_ind],k])
        gder=where((mody-measy)/measy lt 10.)
        perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
        yer_c_ip_l[k]=perirerr
        bdl_ip:
 	
	; Central Fit
        if n_elements(cent_ind) lt 3 then goto, bdc_ip
        cent_fit2=poly_fit(ln_p_ip[gd[cent_ind]], ln_e_ip[gd[cent_ind],k], 1, $
			sigma=sigma_c2, measure_errors=wght_pois_ip[gd[cent_ind],k], $
			status=stat, yband=yband_cent_fit2,yfit=yf_c)
        ;cent_fit1=poly_fit(ln_p_ip[gd[cent_ind]], ln_e_ip[gd[cent_ind],k], 1, $
	;		sigma=sigma_c, measure_errors=yband_cent_fit2, $
	;		status=stat, yband=yband_cent_fit1)
        ;c_ip_c[1:2,k]=[exp(cent_fit1[0]),cent_fit1[1]]
        ;sigma_c_ip_c[1:2,k]=[exp(cent_fit1[0]+sigma_c[0]),cent_fit1[1]-sigma_c[1]]                
        c_ip_c[1:2,k]=[exp(cent_fit2[0]),cent_fit2[1]]
        sigma_c_ip_c[1:2,k]=[exp(cent_fit2[0]+sigma_c2[0]),cent_fit2[1]-sigma_c2[1]]
        ; Calculate the percent error
        mody=exp(yf_c)
        measy=exp(ln_e_ip[gd[cent_ind],k])
        gder=where((mody-measy)/measy lt 10.)
        perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
        yer_c_ip_c[k]=perirerr
        bdc_ip:
        
	; Mid Fit
        if n_elements(mid_ind) lt 3 then goto, bdm_ip
        mid_fit2=poly_fit(ln_p_ip[gd[mid_ind]], ln_e_ip[gd[mid_ind],k], 1, $
			sigma=sigma_m2, measure_errors=wght_pois_ip[gd[mid_ind],k], $
			status=stat, yband=yband_mid_fit2, yfit=yf_m)
        ;mid_fit1=poly_fit(ln_p_ip[gd[mid_ind]], ln_e_ip[gd[mid_ind],k], 1, $
	;		sigma=sigma_m, measure_errors=yband_mid_fit2, $
	;		status=stat, yband=yband_mid_fit1)
        ;c_ip_m[1:2,k]=[exp(mid_fit1[0]),mid_fit1[1]]
        ;sigma_c_ip_m[1:2,k]=[exp(mid_fit1[0]+sigma_m[0]),mid_fit1[1]-sigma_m[1]]
        c_ip_m[1:2,k]=[exp(mid_fit2[0]),mid_fit2[1]]
        sigma_c_ip_m[1:2,k]=[exp(mid_fit2[0]+sigma_m2[0]),mid_fit2[1]-sigma_m2[1]]
        ; Calculate the percent error
        mody=exp(yf_m)
        measy=exp(ln_e_ip[gd[mid_ind],k])
        gder=where((mody-measy)/measy lt 10.)
        perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
        yer_c_ip_m[k]=perirerr
         bdm_ip:
        
	; All Fit
        all_fit2=poly_fit(ln_p_ip[gd[all_ind]], ln_e_ip[gd[all_ind],k], 1, $
			sigma=sigma_a2, measure_errors=wght_pois_ip[gd[all_ind],k], $
			status=stat, yband=yband_all_fit2, yfit=yf_a)
        ;all_fit1=poly_fit(ln_p_ip[gd[all_ind]], ln_e_ip[gd[all_ind],k], 1, $
	;		sigma=sigma_a, measure_errors=yband_all_fit2, $
	;		status=stat, yband=yband_all_fit1)
        ;c_ip[1:2,k]=[exp(all_fit1[0]),all_fit1[1]]
        ;sigma_c_ip[1:2,k]=[exp(all_fit1[0]+sigma_a[0]),all_fit1[1]-sigma_a[1]]
        c_ip[1:2,k]=[exp(all_fit2[0]),all_fit2[1]]
        sigma_c_ip[1:2,k]=[exp(all_fit2[0]+sigma_a2[0]),all_fit2[1]-sigma_a2[1]]
        ; Calculate the percent error
        mody=exp(yf_a)
        measy=exp(ln_e_ip[gd[all_ind],k])
        gder=where((mody-measy)/measy lt 10.)
        perirerr=sqrt(total(((mody[gder]-measy[gder])/measy[gder])^2.)/n_elements(mody[gder]))
        yer_c_ip[k]=perirerr
 
        ; Replace bad central fits with 'alldata' fits if it is good
        if c_ip_c[1,k] lt 0 or c_ip_c[2,k] gt 1000 or c_ip_c[1,k] lt c_ip[1,k] then begin
           if c_ip[1,k] gt 0 or c_ip[2,k] lt 1000 then begin
              c_ip_c[1,k]=c_ip[1,k]
              c_ip_c[2,k]=c_ip[2,k]
              sigma_c_ip_c[*,k]=sigma_c_ip[*,k]
              yer_c_ip_c[k]=yer_c_ip[k]
           endif else begin ; bad all fit, set to zero
              c_ip_c[1,k]=0.0
              c_ip_c[2,k]=0.0
              c_ip[1,k]=0.0
              c_ip[2,k]=0.0
           endelse              
        endif
        ; Replace bad limb fits with 'alldata' fits if it is good
        if c_ip_l[1,k] lt 0 or c_ip_l[2,k] gt 1000 or c_ip_l[1,k] gt c_ip[1,k] then begin
           if c_ip[1,k] gt 0 or c_ip[2,k] lt 1000 then begin
              c_ip_l[1,k]=c_ip[1,k]
              c_ip_l[2,k]=c_ip[2,k]
              sigma_c_ip_l[*,k]=sigma_c_ip[*,k]
              yer_c_ip_l[k]=yer_c_ip[k]
           endif else begin ; bad all fit, set to zero
              c_ip_l[1,k]=0.0
              c_ip_l[2,k]=0.0
           endelse              
        endif
        ; Replace bad mid fits with 'alldata' fits if it is good
        if c_ip_m[1,k] lt 0 or c_ip_m[2,k] gt 1000 or c_ip_m[1,k] gt c_ip_c[1,k] then begin
           if c_ip[1,k] gt 0 or c_ip[2,k] lt 1000 then begin
              c_ip_m[1,k]=c_ip[1,k]
              c_ip_m[2,k]=c_ip[2,k]
              sigma_c_ip_m[*,k]=sigma_c_ip[*,k]
              yer_c_ip_m[k]=yer_c_ip[k]
           endif else begin ; bad all fit, set to zero
              c_ip_m[1,k]=0.0
              c_ip_m[2,k]=0.0
           endelse              
        endif

        ; If limb fit power is greater the central fit,
        ;   just use the all flare fit as there should never be
        ;   limb brightening and will give better fit statistics
        if c_ip_l[2,k] gt c_ip_c[2,k] or c_ip_l[2,k] lt 0.0 then begin
           c_ip_l[1:2,k]=c_ip[1:2,k]
           c_ip_c[1:2,k]=c_ip[1:2,k]
           sigma_c_ip_c[*,k]=sigma_c_ip[*,k]
           sigma_c_ip_l[*,k]=sigma_c_ip[*,k]
           yer_c_ip_c[k]=yer_c_ip[k]
           yer_c_ip_l[k]=yer_c_ip[k]
        endif

        ; If predicted 1sig value at ~X1 level is >250% then there is no
        ; true increase or fit to the data, so zero out contributions
        ; from flares - mostly happens in MEGS-B where there is 
        ; insufficent data at flare peaks (gp) or prior to peak (ip)
        ;x1f=c_ip[1,k]*(1.e-7)^c_ip[2,k]
        ;x1f_sig=(sigma_c_ip[1,k])*(1.e-7)^sigma_c_ip[2,k]
        ;x1f_sig_percent=(x1f_sig-x1f)/x1f*100.
        ;if x1f_sig_percent gt 250 or c_ip[2,k] lt 0.025 or c_ip[1,k] lt 1.0e-6 then begin
        if yer_c_ip[k] gt 2.0 or c_ip[2,k] lt 0.045 or c_ip[1,k] lt 1.0e-6 then begin
           c_ip_l[1,k]=0.0      ; just set coefficeint to 0.0
           c_ip_m[1,k]=0.0
           c_ip_c[1,k]=0.0
           c_ip[1,k]=0.0
           sigma_c_ip_l[1,k]=0.0
           sigma_c_ip_m[1,k]=0.0
           sigma_c_ip_c[1,k]=0.0
           sigma_c_ip[1,k]=0.0
           yer_c_ip_l[k]=0.0
           yer_c_ip_m[k]=0.0
           yer_c_ip_c[k]=0.0
           yer_c_ip[k]=0.0
        endif

        if keyword_set(debug) or keyword_set(ip_debug) then begin
           if keyword_set(ps_out) then open_ps, '$fism_analysis/plots/ip_fit/ip_fit_wv'+strtrim(wv[k],2)+'.ps', /landscape, /color
           !p.multi=0
           cc=independent_color()
           xlf=findgen(1000000)*.0000000001
           if keyword_set(ylog) then begin
              plot, p_ip[gd], e_ip[gd,k], psym=4, charsize=1.9, $
		xtitle='E!DIP,P!N', ytitle='E!DIP,Meas!N', title='Wavelength: '+$
		strmid(strtrim(wv[k],2),0,5)+' nm', /xlog, /ylog
           endif else begin
              plot, p_ip[gd], e_ip[gd,k], psym=4, charsize=1.9, $
		xtitle='E!DIP,P!N', ytitle='E!DIP,Meas!N', title='Wavelength: '+$
		strmid(strtrim(wv[k],2),0,5)+' nm', /xlog
           endelse 
              
           limb_ind=where(clv[gd] eq 3)
           cnt_ind=where(clv[gd] eq 1)
           mid_ind=where(clv[gd] eq 2)
           ; Overplot the color-cordinated symbols 
           if n_elements(limb_ind) gt 2 then oplot, p_ip[gd[limb_ind]], e_ip[gd[limb_ind],k], psym=4, color=cc.green
           if n_elements(cnt_ind) gt 2 then oplot, p_ip[gd[cnt_ind]], e_ip[gd[cnt_ind],k], psym=4, color=cc.red
           if n_elements(mid_ind) gt 2 then oplot, p_ip[gd[mid_ind]], e_ip[gd[mid_ind],k], psym=4, color=cc.blue
           oplot, xlf, c_ip_c[1,k]*(xlf^c_ip_c[2,k]), color=cc.red, thick=2
           oplot, xlf, c_ip_c[1,k]*(xlf^c_ip_c[2,k])*(1.+yer_c_ip_c[k]), color=cc.red, thick=2, linestyle=1
           oplot, xlf, c_ip_l[1,k]*(xlf^c_ip_l[2,k]), color=cc.green
           oplot, xlf, c_ip_m[1,k]*(xlf^c_ip_m[2,k]), color=cc.blue
           oplot, xlf, c_ip[1,k]*(xlf^c_ip[2,k])
           oplot, xlf, c_ip[1,k]*(xlf^c_ip[2,k])*(1.+yer_c_ip[k]), linestyle=1
           ;oplot, xlf, sigma_c_ip[1,k]*(xlf^sigma_c_ip[2,k]), linestyle=1
           ;oplot, xlf, sigma_c_ip_c[1,k]*(xlf^sigma_c_ip_C[2,k]), linestyle=1, color=cc.red
           ;oplot, xlf, sigma_c_ip[1,k]*(xlf^c_ip[2,k]), linestyle=1
           maxx=max(p_ip[gd], min=minx)
           maxy=max(e_ip[gd,k], min=miny)
           xout=0.2; ((maxx-minx)*.5)+minx
           xyouts, xout, 0.85, 'Red: Central Flare Fit', charsize=1.7, color=cc.red, /normal
           xyouts, xout, 0.8, 'Green: Limb Flare Fit', charsize=1.7, color=cc.green, /normal
           xyouts, xout, 0.75, 'Blue: Mid Flare Fit', charsize=1.7, color=cc.blue, /normal
           xyouts, xout, 0.7, 'Black: All Flare Fit', charsize=1.7, /normal
           print, c_ip[*,k]
           print, sigma_c_ip[*,k]
           print, yer_c_ip[k]*100
           ;print, 'X1ish 1 sig percent: ', x1f_sig_percent, '%'
	;stop
           ans=''
           if keyword_set(ps_out) then close_ps else read, ans, prompt='Next (Return, or 2 to stop)? '
           if ans eq 2 then stop

        endif

     nogd_ip:
endfor

; Eliminate bad fits by replacing power coef with median value
;min_gd_val=1e-4
;max_gd_val=10.
;bd_gp=where(c_gp[2,*] gt max_gd_val or c_gp[2,*] lt min_gd_val)
;c_gp[2,bd_gp]=median(c_gp[2,*])
;bd_gp_l=where(c_gp_l[2,*] gt max_gd_val or c_gp_l[2,*] lt min_gd_val)
;c_gp_l[2,bd_gp_l]=median(c_gp_l[2,*])
;bd_gp_c=where(c_gp_c[2,*] gt max_gd_val or c_gp_c[2,*] lt min_gd_val)
;c_gp_c[2,bd_gp_c]=median(c_gp_c[2,*])
;bd_gp_m=where(c_gp_m[2,*] gt max_gd_val or c_gp_m[2,*] lt min_gd_val)
;c_gp_m[2,bd_gp_m]=median(c_gp_m[2,*])
;bd_ip=where(c_ip[2,*] gt max_gd_val or c_ip[2,*] lt min_gd_val)
;c_ip[2,bd_ip]=median(c_ip[2,*])
;bd_ip_l=where(c_ip_l[2,*] gt max_gd_val or c_ip_l[2,*] lt min_gd_val)
;c_ip_l[2,bd_ip_l]=median(c_ip_l[2,*])
;bd_ip_c=where(c_ip_c[2,*] gt max_gd_val or c_ip_c[2,*] lt min_gd_val)
;c_ip_c[2,bd_ip_c]=median(c_ip_c[2,*])
;bd_ip_m=where(c_ip_m[2,*] gt max_gd_val or c_ip_m[2,*] lt min_gd_val)
;c_ip_m[2,bd_ip_m]=median(c_ip_m[2,*])
;min_gd_val=1e-9
;max_gd_val=10.
;bd_gp=where(c_gp[1,*] gt max_gd_val or c_gp[1,*] lt min_gd_val)
;c_gp[1,bd_gp]=median(c_gp[1,*])
;bd_gp_l=where(c_gp_l[1,*] gt max_gd_val or c_gp_l[1,*] lt min_gd_val)
;c_gp_l[1,bd_gp_l]=median(c_gp_l[1,*])
;bd_gp_c=where(c_gp_c[1,*] gt max_gd_val or c_gp_c[1,*] lt min_gd_val)
;c_gp_c[1,bd_gp_c]=median(c_gp_c[1,*])
;bd_gp_m=where(c_gp_m[1,*] gt max_gd_val or c_gp_m[1,*] lt min_gd_val)
;c_gp_m[1,bd_gp_m]=median(c_gp_m[1,*])
;bd_ip=where(c_ip[1,*] gt max_gd_val or c_ip[1,*] lt min_gd_val)
;c_ip[1,bd_ip]=median(c_ip[1,*])
;bd_ip_l=where(c_ip_l[1,*] gt max_gd_val or c_ip_l[1,*] lt min_gd_val)
;c_ip_l[1,bd_ip_l]=median(c_ip_l[1,*])
;bd_ip_c=where(c_ip_c[1,*] gt max_gd_val or c_ip_c[1,*] lt min_gd_val)
;c_ip_c[1,bd_ip_c]=median(c_ip_c[1,*])
;bd_ip_m=where(c_ip_m[1,*] gt max_gd_val or c_ip_m[1,*] lt min_gd_val)
;c_ip_m[1,bd_ip_m]=median(c_ip_m[1,*])

;if not keyword_set(find_cpow) then begin  ;NOTE: No longer averaging
;GP power coefficient!!!
     if not keyword_set(debug) then begin 
	print, 'Saving c_gp.sav and c_ip.sav'
        save, e_gp, p_gp, c_gp_l, c_gp_m, c_gp_c, c_gp, abs_dif_gp, $
              sigma_c_gp_l, sigma_c_gp_m, sigma_c_gp_c, sigma_c_gp, $
              yer_c_gp, yer_c_gp_m, yer_c_gp_l, yer_c_gp_c, $
              clv, wv, med_gp_delay_time, file=expand_path('$fism_save')+'/c_gp.sav'
        save, e_ip, p_ip, c_ip_l, c_ip_m, c_ip_c, c_ip, abs_dif_ip, $
              sigma_c_ip_l, sigma_c_ip_m, sigma_c_ip_c, sigma_c_ip, $
              yer_c_ip, yer_c_ip_m, yer_c_ip_l, yer_c_ip_c, $
              clv, wv, file=expand_path('$fism_save')+'/c_ip.sav'
     endif else begin
	print, 'Debug Keyword Set, NOT saving c_gp.sav or c_ip.sav coefs...'
     endelse
;endif else begin
     ; Find the avearge power from central fit (more flares) c_gp_c[2,30:110]
;     gd_c_pow=where(wv gt 14.0) ; only use EUV as XUV should be 1
;     c_power=mean(c_gp_c[2,gd_c_pow])
;     print, 'GP Power Coef: ', c_power
;     ; Save this power to be used in the model (with later run without /find_cpow
;     print, 'Saving gp_power_coef.sav'
;     save, c_power, c_gp_c, file=expand_path('$fism_save')+'/gp_power_coef.sav'
;     ; Save other arrays for debuggin in later section without having to
;     ;reprocess
;     save, p_gp, e_gp, wv, clv, c_gp_c, c_gp_l, c_gp_m, c_gp, $ 
;           file=expand_path('$fism_save')+'/gp_power_coef_debug.sav'
;endelse    

;stop

ep_only:
if keyword_set(end_plts_only) then begin
   debug=1
   if keyword_set(find_cpow) then begin
      restore, expand_path('$fism_save')+'/gp_power_coef_debug.sav'
   endif else begin
      restore, expand_path('$fism_save')+'/c_gp.sav'
      restore, expand_path('$fism_save')+'/c_ip.sav'
   endelse
endif

if keyword_set(debug) then begin
	!p.multi=0
	cc=independent_color()
        anwv:
	read, wv_plt, prompt='Enter Wavelength : '
        window, 0
        wwv_tmp=where(wv ge wv_plt)
        wwv=wwv_tmp[0]
	gd=where(p_gp gt 0.0 and e_gp[*,wwv] gt -0.01)
	xlf=findgen(10000)*.0000001
	;if ps_out ne 0 then open_ps, '$fism_plots/goes_p_gp_e_gp_'+strtrim(wv,2)+'.ps'
        if keyword_set(ylog) then begin 
           plot, p_gp[gd], e_gp[gd,wwv], psym=4, charsize=1.7, $
		xtitle='GOES P_GP', ytitle='EVE E_GP', title='Wavelength: '+$
		strtrim(wv[wwv],2), /xlog, /ylog
        endif else begin
           plot, p_gp[gd], e_gp[gd,wwv], psym=4, charsize=1.7, $
		xtitle='GOES P_GP', ytitle='EVE E_GP', title='Wavelength: '+$
		strtrim(wv[wwv],2), /xlog
        endelse
        limb_ind=where(clv[gd] eq 3)
	cnt_ind=where(clv[gd] eq 1)
	mid_ind=where(clv[gd] eq 2)
	; Overplot the color-cordinated symbols 
	oplot, p_gp[gd[limb_ind]], e_gp[gd[limb_ind],wwv], psym=4, color=cc.green
	oplot, p_gp[gd[cnt_ind]], e_gp[gd[cnt_ind],wwv], psym=4, color=cc.red
	oplot, p_gp[gd[mid_ind]], e_gp[gd[mid_ind],wwv], psym=4, color=cc.blue
	if keyword_set(lnfunct) then begin
		oplot, xlf, c_gp_c[1,wwv]*(xlf), color=cc.red
		oplot, xlf, c_gp_l[1,wwv]*(xlf), color=cc.green
		oplot, xlf, c_gp_m[1,wwv]*(xlf), color=cc.blue
		oplot, xlf, c_gp[1,wwv]*(xlf)
	endif else begin
		oplot, xlf, c_gp_c[1,wwv]*(xlf^c_gp_c[2,wwv]), color=cc.red
		oplot, xlf, c_gp_l[1,wwv]*(xlf^c_gp_l[2,wwv]), color=cc.green
		oplot, xlf, c_gp_m[1,wwv]*(xlf^c_gp_m[2,wwv]), color=cc.blue
		oplot, xlf, c_gp[1,wwv]*(xlf^c_gp[2,wwv])
	endelse
	maxx=max(p_gp[gd], min=minx)
	maxy=max(e_gp[gd,wwv], min=miny)
	xout=((maxx-minx)*.5)+minx
	xyouts, xout, ((maxy-miny)*.9)+miny, 'Red: Central Flare Fit', charsize=1.7, color=cc.red
	xyouts, xout, ((maxy-miny)*.8)+miny, 'Green: Limb Flare Fit', charsize=1.7, color=cc.green
	xyouts, xout, ((maxy-miny)*.7)+miny, 'Blue: Mid Flare Fit', charsize=1.7, color=cc.blue
	xyouts, xout, ((maxy-miny)*.6)+miny, 'White: All Flare Fit', charsize=1.7

        window, 1
                   !p.multi=0
           cc=independent_color()
           xlf=findgen(1000000)*.0000000001
           gd=where(p_ip gt 0.0 and e_ip[*,wwv] gt -0.01)
           if keyword_set(ylog) then begin
              plot, p_ip[gd], e_ip[gd,wwv], psym=4, charsize=1.7, $
		xtitle='GOES P_IP', ytitle='EVE E_IP', title='Wavelength: '+$
		strtrim(wv[wwv],2), /xlog, /ylog
           endif else begin
              plot, p_ip[gd], e_ip[gd,wwv], psym=4, charsize=1.7, $
		xtitle='GOES P_IP', ytitle='EVE E_IP', title='Wavelength: '+$
		strtrim(wv[wwv],2), /xlog
           endelse
           
           limb_ind=where(clv[gd] eq 3)
           cnt_ind=where(clv[gd] eq 1)
           mid_ind=where(clv[gd] eq 2)
           ; Overplot the color-cordinated symbols 
           oplot, p_ip[gd[limb_ind]], e_ip[gd[limb_ind],wwv], psym=4, color=cc.green
           oplot, p_ip[gd[cnt_ind]], e_ip[gd[cnt_ind],wwv], psym=4, color=cc.red
           oplot, p_ip[gd[mid_ind]], e_ip[gd[mid_ind],wwv], psym=4, color=cc.blue
           oplot, xlf, c_ip_c[1,wwv]*(xlf^c_ip_c[2,wwv]), color=cc.red
           oplot, xlf, c_ip_l[1,wwv]*(xlf^c_ip_l[2,wwv]), color=cc.green
           oplot, xlf, c_ip_m[1,wwv]*(xlf^c_ip_m[2,wwv]), color=cc.blue
           oplot, xlf, c_ip[1,wwv]*(xlf^c_ip[2,wwv])
           maxx=max(p_ip[gd], min=minx)
           maxy=max(e_ip[gd,wwv], min=miny)
           xout=((maxx-minx)*.5)+minx
           xyouts, xout, ((maxy-miny)*.9)+miny, 'Red: Central Flare Fit', charsize=1.7, color=cc.red
           xyouts, xout, ((maxy-miny)*.8)+miny, 'Green: Limb Flare Fit', charsize=1.7, color=cc.green
           xyouts, xout, ((maxy-miny)*.7)+miny, 'Blue: Mid Flare Fit', charsize=1.7, color=cc.blue
           xyouts, xout, ((maxy-miny)*.6)+miny, 'White: All Flare Fit', charsize=1.7

        anwv_chk=''
	read, anwv_chk, prompt='Another Wavelength (y/n)? '
	if anwv_chk eq 'y' or anwv_chk eq 'Y' then goto, anwv
endif

;stop
print, 'End time find_ip_gp_powerfunct_eve: ', !stime

end


