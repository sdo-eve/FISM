;
;  NAME: create_sr_sc_av.pro
;
;  PURPOSE: to create the n-day trailing solar cycle average of the EVE data
;
;  MODIFICATION HISTORY:
;	PCC	7/20/04		Program Creation
;	PCC	7/22/04		Automatically picks l3 merged file
;  	****Version 2*****
;	PCC	8/24/04		Started v2, can now pick the # of prev days
;				to make the trailing average (default = 54 days)
;	****Version 3*****
;	PCC	11/2/04		Use a convolution (convol) instead of a boxcar
;				average
;	****Version 4*****
;	PCC	11/9/04		Use the opotimized convolution found from
;				'op_conv_kern.pro' and 'op_conv_kern_perwv.pro'
;	PCC	3/8/05		Added the keyword to set the number of sc av dys
;					default=54 days
;	PCC	3/28/05		Added the SEE measurement errors to the saveset
;	PCC	4/27/05		Added the keyword to perform a centered average
;	PCC	12/01/06	Updated for MacOSX
;	PCC	12/01/06	Changed defaults to the optimized and published defaults
;				scav_dys=108, /cent_av
;       ***** VERSION 2_1
;       PCC     5/21/12         Updated to use SDO/EVE data
;       PCC     3/6/14          Added EVE/ESP Diodes a proxies (for
;                               MAVEN prep)
;       PCC     11/7/16         Updated to use 1a EVE data

pro create_sc_sr_av, scav_dys=scav_dys, cent_av=cent_av

if keyword_set(cent_av) then center_av=1 else center_av=0 ; Save for other codes

print, 'Running create_sc_sr_av.pro; center_av=',center_av, !stime

;l3_ts=read_latest_merged('see','l3',status)
;restore, l3_mer_file

;l3mer_flnm=findfile(expand_path('$eve_proxy') + '/EVE_L3_*.sav')
l3mer_flnm=findfile(expand_path('$fism_data')+'/lasp/eve/latest_EVE_L3_merged_1a.ncdf')
read_netcdf, l3mer_flnm[0], eve, s, a

eve_wv=reform(eve.spectrummeta.wavelength)
eve_day_ar=reform(eve.mergeddata.yyyydoy)
; Remove the solar cycle n-day average to get solar rotation residual
ndys=n_elements(eve.mergeddata.yyyydoy)
nwvs=n_elements(eve_wv)
eve_sc_av=fltarr(nwvs,ndys)
eve_sr_res=fltarr(nwvs,ndys)
eve_daily_err=transpose(eve.mergeddata.sp_stdev)
; If keyword for the # of days to average is not set, the 
;	default is set to 108 days
if keyword_set(scav_dys) then sc_avg_dys=scav_dys else sc_avg_dys=108
if keyword_set(cent_av) then begin   ; Centered Average
   for h=0,nwvs-1 do begin
   	sc_av_tmp=fltarr(n_elements(reform(eve.mergeddata.sp_irradiance[h,*])))
   	intx=findgen(n_elements(sc_av_tmp)) ; assumes there is a data point for every day
   	gd_sm=where(eve.mergeddata.sp_irradiance[h,*] gt 0.0)
	if gd_sm[0] ne -1 then begin
           sc_av_tmp[gd_sm]=smooth(eve.mergeddata.sp_irradiance[h,gd_sm],sc_avg_dys,/edge_truncate)
           ; Interpolate over bad days
           gdsm=where(sc_av_tmp gt 0.0)
           eve_sc_av[h,*]=interpol(sc_av_tmp[gdsm], intx[gdsm], intx)
           eve_sr_res[h,gdsm]=eve.mergeddata.sp_irradiance[h,gd_sm]-eve_sc_av[h,gdsm]
        endif
   endfor
endif else begin		; Trailing average
   for h=0,nwvs-1 do begin
	strt_avg=avg(eve.mergeddata.sp_irradiance[h,0:(sc_avg_dys-1)])
	eve_sc_av[h,0:(sc_avg_dys-1)]=strt_avg
	for k=sc_avg_dys,ndys-1 do eve_sc_av[h,k]=avg(eve.mergeddata.sp_irradiance[h,(k-sc_avg_dys):k])
	eve_sr_res[h,*]=eve.mergeddata.sp_irradiance[h,*]-eve_sc_av[h,*]
   endfor
endelse

; Save ESP QD, 17.1 nm, 30.4nm and Lyman_alpha for later use as a soft X-ray proxy (starting in
; 'find_3_prox_2.pro')  NOTE: QD, 17 and Lyman-alpha are ~ MAVEN EUV diodes, and will
; be used for inital testing/coding of them

; QD
eve_qd=reform(eve.mergeddata.diode_irradiance[0,*])
sc_av_tmp=fltarr(n_elements(eve_qd))
eve_qd_sr_res=fltarr(n_elements(eve_qd))
intx=findgen(n_elements(sc_av_tmp)) ; assumes there is a data point for every day
gd_sm=where(eve_qd gt 0.0)
if gd_sm[0] ne -1 then begin
   sc_av_tmp[gd_sm]=smooth(eve_qd[gd_sm],sc_avg_dys,/edge_truncate)
   ; Interpolate over bad days
   gdsm=where(sc_av_tmp gt 0.0)
   eve_qd_sc_av=interpol(sc_av_tmp[gdsm], intx[gdsm], intx)
   eve_qd_sr_res[gdsm]=eve_qd[gdsm]-eve_qd_sc_av[gdsm]
endif

; 171
eve_171=reform(eve.mergeddata.diode_irradiance[1,*])
sc_av_tmp=fltarr(n_elements(eve_171))
eve_171_sr_res=fltarr(n_elements(eve_171))
intx=findgen(n_elements(sc_av_tmp)) ; assumes there is a data point for every day
gd_sm=where(eve_171 gt 0.0)
if gd_sm[0] ne -1 then begin
   sc_av_tmp[gd_sm]=smooth(eve_171[gd_sm],sc_avg_dys,/edge_truncate)
   ; Interpolate over bad days
   gdsm=where(sc_av_tmp gt 0.0)
   eve_171_sc_av=interpol(sc_av_tmp[gdsm], intx[gdsm], intx)
   eve_171_sr_res[gdsm]=eve_171[gdsm]-eve_171_sc_av[gdsm]
endif

; lya
eve_lya=reform(eve.mergeddata.diode_irradiance[5,*])
sc_av_tmp=fltarr(n_elements(eve_lya))
eve_lya_sr_res=fltarr(n_elements(eve_lya))
intx=findgen(n_elements(sc_av_tmp)) ; assumes there is a data point for every day
gd_sm=where(eve_lya gt 0.0)
if gd_sm[0] ne -1 then begin
   sc_av_tmp[gd_sm]=smooth(eve_lya[gd_sm],sc_avg_dys,/edge_truncate)
   ; Interpolate over bad days
   gdsm=where(sc_av_tmp gt 0.0)
   eve_lya_sc_av=interpol(sc_av_tmp[gdsm], intx[gdsm], intx)
   eve_lya_sr_res[gdsm]=eve_lya[gdsm]-eve_lya_sc_av[gdsm]
endif

; 30 nm
eve_304=reform(eve.mergeddata.diode_irradiance[5,*])
sc_av_tmp=fltarr(n_elements(eve_304))
eve_304_sr_res=fltarr(n_elements(eve_304))
intx=findgen(n_elements(sc_av_tmp)) ; assumes there is a data point for every day
gd_sm=where(eve_304 gt 0.0)
if gd_sm[0] ne -1 then begin
   sc_av_tmp[gd_sm]=smooth(eve_304[gd_sm],sc_avg_dys,/edge_truncate)
   ; Interpolate over bad days
   gdsm=where(sc_av_tmp gt 0.0)
   eve_304_sc_av=interpol(sc_av_tmp[gdsm], intx[gdsm], intx)
   eve_304_sr_res[gdsm]=eve_304[gdsm]-eve_304_sc_av[gdsm]
endif

eve_data=eve.mergeddata.sp_irradiance

; Add *d to the filename to signify which ones are diode (later will
; be similar names from MEGS that won't have the *d tag)
eve_171d=eve_171 
eve_171d_sc_av=eve_171_sc_av
eve_171d_sr_res=eve_171_sr_res
eve_304d=eve_304
eve_304d_sc_av=eve_304_sc_av
eve_304d_sr_res=eve_304_sr_res
eve_lyad=eve_lya
eve_lyad_sc_av=eve_lya_sc_av
eve_lyad_sr_res=eve_lya_sr_res

fle=expand_path('$tmp_dir') + '/eve_sc_av.sav'
print, 'Saving ', fle
save, eve_sc_av, eve_sr_res, eve_day_ar, eve_wv, sc_avg_dys, $
      eve_daily_err, center_av, eve_qd, eve_qd_sc_av, $
      eve_qd_sr_res, eve_data, eve_171d, eve_171d_sc_av, $
      eve_171d_sr_res,eve_304d, eve_304d_sc_av, $
      eve_304d_sr_res,eve_lyad, eve_lyad_sc_av, $
      eve_lyad_sr_res, file=fle
  
print, 'End Time create_sc_sr_av: ', !stime

end
