;
; NAME: find_p_sc_p_sr.pro
;
; PURPOSE: to find the p_sc and p_sr proxies for MgII, F10.7, LYA, and GOES
;
; MODIFICATION HISTORY:
;	PCC	11/15/04	Program Creation (separated from 
;				'create_mgft_sc_av_v2.pro)
;	PCC	3/28/05		Computes the proxy (P/Pmin-1) for all 
;				possible proxies (MgII, F107, log(GOES)d,
;				ly-alpha, 33.5nm, 36.5nm)
;	PCC	4/6/05		Added XPS #0 [0-7nm] as a proxy
;	PCC	6/13/05		Daily proxy is now divided by the SC day value
;	PCC	12/01/06	Updated for MacOSX
;       ***VERSION 02_01
;       PCC     5/23/12         Updated for SDO/EVE
;       PCC     3/7/14          Added in ESP diodes 171, 304, and MEGS-P 
;

pro find_3_prox_2

print, 'Running find_3_prox_2.pro', !stime

save_pth = expand_path('$fism_save') 
tmp_pth = expand_path('$tmp_dir')
restore, tmp_pth+'/eve_sc_av.sav'
restore, save_pth+'/eve_min_sp.sav'
restore, tmp_pth+'/prox_sc_sr_pred.sav'

ndys=n_elements(eve_day_ar)
; Find the proxies with no sc/sr decoupling
p_mgii=(mgii/min_mgii_abs)-1.
p_f107=(f107/min_f107_abs)-1.
p_goes=goes_daily_log ; Can't divide by min as min=0
p_lya=(lya/min_lya_abs)-1.
; Use the min reference spectrum 
;	for min 17.10, 30.38, 33.54 and 36.96 nm values
; 171
weve=where(eve_wv ge 17.10)
eve_171=total(eve_sc_av[weve[0]-2:weve[0]+2,*],1)/5.+total(eve_sr_res[weve[0]-2:weve[0]+2,*],1)/5.
min_171=total(fismref_sp[1,weve[0]-2:weve[0]+2],2)/5.
if min(eve_171) lt min_171 and min(eve_171) gt 0.0 then min_171=min(eve_171)
p_171=fltarr(ndys)
for m=0,ndys-1 do p_171[m]=(eve_171[m]/min_171)-1.				
; 304
weve=where(eve_wv ge 30.38)
eve_304=total(eve_sc_av[weve[0]-2:weve[0]+2,*],1)/5.+total(eve_sr_res[weve[0]-2:weve[0]+2,*],1)/5.
min_304=total(fismref_sp[1,weve[0]-2:weve[0]+2],2)/5.
if min(eve_304) lt min_304 and min(eve_304) gt 0.0 then min_304=min(eve_304)
p_304=fltarr(ndys)
for m=0,ndys-1 do p_304[m]=(eve_304[m]/min_304)-1.				
; 335
weve=where(eve_wv ge 33.54)
eve_335=total(eve_sc_av[weve[0]-2:weve[0]+2,*],1)/5.+total(eve_sr_res[weve[0]-2:weve[0]+2,*],1)/5.
min_335=total(fismref_sp[1,weve[0]-2:weve[0]+2],2)/5.
if min(eve_335) lt min_335 and min(eve_335) gt 0.0 then min_335=min(eve_335)
p_335=fltarr(ndys)
for m=0,ndys-1 do p_335[m]=(eve_335[m]/min_335)-1. 				
; 369
weve=where(eve_wv ge 36.96)
eve_369=total(eve_sc_av[weve[0]-2:weve[0]+2,*],1)/5.+total(eve_sr_res[weve[0]-2:weve[0]+2,*],1)/5.
min_369=total(fismref_sp[1,weve[0]-2:weve[0]+2],2)/5.
if min(eve_369) lt min_369 and min(eve_369) gt 0.0 then min_369=min(eve_369)
p_369=fltarr(ndys)
for m=0,ndys-1 do p_369[m]=(eve_369[m]/min_369)-1.				
; Use SDO/EVE/ESP Quad Diode as the soft X-ray proxy
ndys=n_elements(eve_sc_av[0,*])
gd_eveqd=where(eve_qd gt 0.0)
min_qd=min(eve_qd[gd_eveqd])			
p_qd=eve_qd/min_qd-1.	
; Use SDO/EVE/ESP 171 Diode as the MAVEN 171 proxy
ndys=n_elements(eve_sc_av[0,*])
gd_eve171d=where(eve_171d gt 0.0)
min_171d=min(eve_171d[gd_eve171d])			
p_171d=eve_171d/min_171d-1.	
; Use SDO/EVE/ESP lya Diode as the MAVEN LYA proxy
ndys=n_elements(eve_sc_av[0,*])
gd_evelyad=where(eve_lyad gt 0.0)
min_lyad=min(eve_lyad[gd_evelyad])			
p_lyad=eve_lyad/min_lyad-1.	
; Use SDO/EVE/ESP 304 Diode as a proxy
ndys=n_elements(eve_sc_av[0,*])
gd_eve304d=where(eve_304d gt 0.0)
min_304d=min(eve_304d[gd_eve304d])			
p_304d=eve_304d/min_304d-1.	

;
; Find the proxies with sc/sr decoupling using the 'sc_avg_dys'
;	specified from see_sc_av.sav
;

; Determine the corresponding days for each array (Good for all proxies)
fit_ind_prox_tmp=intarr(ndys)-1
fit_ind_eve_prox_tmp=intarr(ndys)-1
eve_day_ar_tmp=lonarr(ndys)-1
for d=0,1450 do begin;  ndys-1 do begin   , Currently limiting the fit to good EVE data
   if eve_304d[d] gt 0.0 and eve_304[d] gt 0.0 then begin
      a=where(day_ar_all eq eve_day_ar[d])
      if a[0] ne -1 then begin
         fit_ind_prox_tmp[d]=a
         fit_ind_eve_prox_tmp[d]=d
         eve_day_ar_tmp[d]=eve_day_ar[d]
      endif 
   endif
endfor
gd1=where(fit_ind_prox_tmp ge 0)
fit_ind_prox=fit_ind_prox_tmp[gd1]
gd2=where(fit_ind_eve_prox_tmp ge 0)
fit_ind_eve_prox=fit_ind_eve_prox_tmp[gd2]
gd3=where(eve_day_ar_tmp ge 0)
eve_day_ar=eve_day_ar_tmp[gd3]
 
ndys=n_elements(day_ar_all[fit_ind_prox])
sc_av=fltarr(ndys)
sr_av=fltarr(ndys)
prox_ar=[transpose(mgii[fit_ind_prox]),transpose(f107[fit_ind_prox]),transpose(goes_daily_log[fit_ind_prox]),transpose(lya[fit_ind_prox]), $
	transpose(eve_qd[fit_ind_eve_prox]),transpose(eve_171[fit_ind_eve_prox]),transpose(eve_304[fit_ind_eve_prox]),transpose(eve_335[fit_ind_eve_prox]), $
	transpose(eve_369[fit_ind_eve_prox]),transpose(eve_171d[fit_ind_eve_prox]), transpose(eve_304d[fit_ind_eve_prox]), transpose(eve_lyad[fit_ind_eve_prox])]
min_ar=[min_mgii,min_f107,1.,min_lya,$
        min_qd,min_171,min_304,min_335,$
	min_369,min_171d,min_304d,min_lyad]
sub_ar=[1.,1.,0.,1.,1.,1.,1.,1.,1.,1.,1.,1.]
prox_nm_ar=['mgii','f107','goes','lya','QD','171','304','335','369','171d','304d','lyad']
st_pls_scav=get_next_yyyydoy(day_ar_all[0],sc_avg_dys)
for h=0,n_elements(prox_nm_ar)-1 do begin	
	wst_av=where(day_ar_all le st_pls_scav and prox_ar[h,*] gt 0.0)
	if center_av eq 0 then begin
		strt_avg=avg(prox_ar[h,wst_av])
		sc_av[0:(sc_avg_dys-1)]=strt_avg
		for k=sc_avg_dys,ndys-1 do begin
			wstdy=get_prev_yyyydoy(day_ar_all[k],sc_avg_dys)
			wav=where(day_ar_all ge wstdy and day_ar_all le day_ar_all[k] and $ 
				prox_ar[h,*] gt 0.0)
			sc_av[k]=avg(prox_ar[h,wav])
		endfor
	endif else begin
		sc_av_tmp=fltarr(n_elements(prox_ar[h,*]))
		int_x=findgen(n_elements(prox_ar[h,*]))
		gd_prox=where(prox_ar[h,*] gt 0.0)	
		sc_av_tmp[gd_prox]=smooth(prox_ar[h,gd_prox],sc_avg_dys,/edge_truncate)
		; Interpolate over bad days
		gdsm=where(sc_av_tmp gt 0.0)
		sc_av=interpol(sc_av_tmp[gdsm],int_x[gdsm], int_x)
	endelse
	sr_ar=prox_ar[h,*]-sc_av
	sr_ar=reform(sr_ar)
	; cmd: p_mgii_sc=sc_av/p_min-1. & p_mgii_sr=sr_av/sc_av
	cmd='p_'+prox_nm_ar[h]+'_sc=(sc_av/min_ar[h])-sub_ar[h]'
	st=execute(cmd)
	cmd2='p_'+prox_nm_ar[h]+'_sr=reform((prox_ar[h,*]-sc_av)/min_ar[h])'
	st2=execute(cmd2)
	cmd3='p_'+prox_nm_ar[h]+'=reform(prox_ar[h,*])'
	st3=execute(cmd3)
        ;if h eq 4 then stop
        ;stop
endfor

proxy_day_ar=eve_day_ar ; avoid conflicting array names with find_e_sc_e_sr.pro

print, 'Saving proxies_2.sav'
save, proxy_day_ar, p_mgii, p_f107, p_goes, p_lya, p_335, p_369, p_304, $ 
	p_mgii_sc, p_f107_sc, p_goes_sc, p_lya_sc, p_335_sc, p_369_sc, $
	p_mgii_sr, p_f107_sr, p_goes_sr, p_lya_sr, p_335_sr, p_369_sr, $
	p_QD, p_QD_sc, p_QD_sr, p_304_sc, p_304_sr, prox_nm_ar, p_171, $
        p_171_sc, p_171_sr, p_171d, p_171d_sc, p_171d_sr, p_304d, p_304d_sc, $
        p_304d_sr, p_lyad, p_lyad_sc, p_lyad_sr, $
	file=save_pth+'/proxies_2.sav'

print, 'End Time find_3_prox_2: ', !stime

end
