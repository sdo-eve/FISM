;
; NAME: find_p_sc_p_sr.pro
;
; PURPOSE: to find the convolution of the proxies and then find the 
;	p_sc and p_sr proxies for MgII, F10.7, and GOES
;
; MODIFICATION HISTORY:
;	PCC	11/15/04	Program Creation (separated from 
;				'create_mgft_sc_av_v2.pro)
;	PCC	3/28/05		Computes the proxy (P/Pmin-1) for all 
;				possible proxies (MgII, F107, log(GOES)d,
;				ly-alpha, 33.5nm, 36.5nm)
;	PCC	4/6/05		Added XPS #0 [0-7nm] as a proxy
;	PCC	12/01/06	Updated for MacOSX
;       ***VERSION 02_01
;       PCC     5/23/12         Updated for SDO/EVE
;       PCC     3/7/14          Added ESP 171 and 304 diodes, and MEGS-P


pro find_3_prox_pred

print, 'Running find_3_prox_pred.pro', !stime

restore, expand_path('$tmp_dir') + '/eve_sc_av.sav'
restore, expand_path('$pre_gen_data_dir') + '/eve_min_sp.sav'
restore, expand_path('$tmp_dir') + '/prox_sc_sr_pred.sav'

; Create arrays for the EVE data that are similar size/days as other proxies
; Restore EVE merged data array 
l3mer_flnm=findfile(expand_path('$fism_data')+'/lasp/eve/latest_EVE_L3_merged.ncdf')
read_netcdf, l3mer_flnm[0], eve, s, a

ndys=n_elements(day_ar_all)
sqd=fltarr(ndys)
s171=fltarr(ndys)
s304=fltarr(ndys)
s335=fltarr(ndys)
s369=fltarr(ndys)
s171d=fltarr(ndys)
s304d=fltarr(ndys)
slyad=fltarr(ndys)
sqd_sc=fltarr(ndys)
s171_sc=fltarr(ndys)
s304_sc=fltarr(ndys)
s335_sc=fltarr(ndys)
s369_sc=fltarr(ndys)
s171d_sc=fltarr(ndys)
s304d_sc=fltarr(ndys)
slyad_sc=fltarr(ndys)
sqd_sr=fltarr(ndys)
s171_sr=fltarr(ndys)
s304_sr=fltarr(ndys)
s335_sr=fltarr(ndys)
s369_sr=fltarr(ndys)
s171d_sr=fltarr(ndys)
s304d_sr=fltarr(ndys)
slyad_sr=fltarr(ndys)
tm_ar=fltarr(1)
eve_ar=fltarr(1)
dy_ar_comp=lonarr(1)

weve_171=where(eve_wv ge 17.10)
weve_304=where(eve_wv ge 30.38)
weve_335=where(eve_wv ge 33.54)
weve_369=where(eve_wv ge 36.96)

for j=0,ndys-1 do begin
	weve=where(eve_day_ar eq day_ar_all[j])
	if weve[0] eq -1 then begin
		sqd[j]=-999.00
                s171[j]=-999.00
		s304[j]=-999.00
		s335[j]=-999.00
		s369[j]=-999.00
                s171d[j]=-999.00
                s304d[j]=-999.00
                slyad[j]=-999.00
		sqd_sc[j]=-999.00
                s171_sc[j]=-999.00
		s304_sc[j]=-999.00
		s335_sc[j]=-999.00
		s369_sc[j]=-999.00
                s171d_sc[j]=-999.00
                s304d_sc[j]=-999.00
                slyad_sc[j]=-999.00
		sqd_sr[j]=-999.00
                s171_sr[j]=-999.00
		s304_sr[j]=-999.00
		s335_sr[j]=-999.00
		s369_sr[j]=-999.00
                s171d_sr[j]=-999.00
                s304d_sr[j]=-999.00
                slyad_sr[j]=-999.00
	endif else begin
		sqd[j]=eve_qd[weve]
                s171[j]=total(eve_data[weve_171[0]-2:weve_171[0]+2,weve],1)/5.
		s304[j]=total(eve_data[weve_304[0]-2:weve_304[0]+2,weve],1)/5.
		s335[j]=total(eve_data[weve_335[0]-2:weve_335[0]+2,weve],1)/5.
		s369[j]=total(eve_data[weve_304[0]-2:weve_304[0]+2,weve],1)/5.
		s171d[j]=eve_171d[weve]
		s304d[j]=eve_304d[weve]
		slyad[j]=eve_lyad[weve]
		sqd_sc[j]=eve_qd_sc_av[weve]
                s171_sc[j]=total(eve_sc_av[weve_171[0]-2:weve_171[0]+2,weve],1)/5.
		s304_sc[j]=total(eve_sc_av[weve_304[0]-2:weve_304[0]+2,weve],1)/5.
		s335_sc[j]=total(eve_sc_av[weve_335[0]-2:weve_335[0]+2,weve],1)/5.
		s369_sc[j]=total(eve_sc_av[weve_369[0]-2:weve_369[0]+2,weve],1)/5.
		s171d_sc[j]=eve_171d_sc_av[weve]
		s304d_sc[j]=eve_304d_sc_av[weve]
		slyad_sc[j]=eve_lyad_sc_av[weve]
		sqd_sr[j]=eve_qd_sr_res[weve]
                s171_sr[j]=total(eve_sr_res[weve_171[0]-2:weve_171[0]+2,weve],1)/5.
		s304_sr[j]=total(eve_sr_res[weve_304[0]-2:weve_304[0]+2,weve],1)/5.
		s335_sr[j]=total(eve_sr_res[weve_335[0]-2:weve_335[0]+2,weve],1)/5.
		s369_sr[j]=total(eve_sr_res[weve_369[0]-2:weve_369[0]+2,weve],1)/5.
		s171d_sr[j]=eve_171d_sr_res[weve]
		s304d_sr[j]=eve_304d_sr_res[weve]
		slyad_sr[j]=eve_lyad_sr_res[weve]
	endelse
endfor

; Eliminate 33.5 and 36.9 proxies from MEGS-B after loss of MEGS-A as
; they run away and have incorret long-term calibration as of
; 1/10/2017
bd_eve_megsb=where(day_ar_all gt 2014145)
s335[bd_eve_megsb]=-999.0
s335_sc[bd_eve_megsb]=-999.0
s335_sr[bd_eve_megsb]=-999.0
s369[bd_eve_megsb]=-999.0
s369_sc[bd_eve_megsb]=-999.0
s369_sr[bd_eve_megsb]=-999.0


; Find the proxies with no sc/sr decoupling
p_mgii=(mgii/min_mgii_abs)-1.
p_f107=(f107/min_f107_abs)-1.
p_goes=goes_daily_log ; Can't divide by min as min=0
p_lya=(lya/min_lya_abs)-1.
; Use the MgII quatradic extrapolated min reference spectrum 
;	for min 33.5 and Ly-a values
min_171=total(fismref_sp[1,weve_171[0]-2:weve_171[0]+2],2)/5.
if min(s171) lt min_171 and min(s171) gt 0.0 then min_171=min(s171)
p_171=fltarr(ndys)
for m=0,ndys-1 do p_171[m]=(s171[m]/min_171)-1.				
min_304=total(fismref_sp[1,weve_304[0]-2:weve_304[0]+2],2)/5.
if min(s304) lt min_304 and min(s304) gt 0.0 then min_304=min(s304)
p_304=fltarr(ndys)
for m=0,ndys-1 do p_304[m]=(s304[m]/min_304)-1.				
min_335=total(fismref_sp[1,weve_335[0]-2:weve_335[0]+2],2)/5.
if min(s335) lt min_335 and min(s335) gt 0.0 then min_335=min(s335)
p_335=fltarr(ndys)
for m=0,ndys-1 do p_335[m]=(s335[m]/min_335)-1.				
min_369=total(fismref_sp[1,weve_369[0]-2:weve_369[0]+2],2)/5.
if min(s369) lt min_369 and min(s369) gt 0.0 then min_369=min(s369)
p_369=fltarr(ndys)
for m=0,ndys-1 do p_369[m]=(s369[m]/min_369)-1.										
gd_eveqd=where(sqd gt 0.0)
min_qd=min(sqd[gd_eveqd])			
p_qd=fltarr(ndys)
for m=0,ndys-1 do p_qd[m]=sqd[m]/min_qd-1.	
gd_eve171d=where(s171d gt 0.0)
min_171d=min(s171d[gd_eve171d])			
p_171d=fltarr(ndys)
for m=0,ndys-1 do p_171d[m]=s171d[m]/min_171d-1.	
gd_eve304d=where(s304d gt 0.0)
min_304d=min(s304d[gd_eve304d])			
p_304d=fltarr(ndys)
for m=0,ndys-1 do p_304d[m]=s304d[m]/min_304d-1.	
gd_evelyad=where(slyad gt 0.0)
min_lyad=min(slyad[gd_evelyad])			
p_lyad=fltarr(ndys)
for m=0,ndys-1 do p_lyad[m]=slyad[m]/min_lyad-1.	


; Find the proxies with sc/sr decoupling using the 'sc_avg_dys'
;	specified from see_sc_av.sav
p_mgii_sc=(mgii_sc_av/min_mgii)-1. 
p_mgii_sr=(mgii_sr_res/min_mgii)
p_f107_sc=((f107_sc_av/min_f107)-1.)>0.0002 
p_f107_sr=(f107_sr_res/min_f107)
p_goes_sc=goes_sc_av_log
p_goes_sr=(goes_sr_res_log)
p_lya_sc=(lya_sc_av/min_lya)-1.
p_lya_sr=(lya_sr_res/min_lya)
p_171_sc=fltarr(ndys)
p_304_sc=fltarr(ndys)
p_335_sc=fltarr(ndys)
p_369_sc=fltarr(ndys)
p_qd_sc=fltarr(ndys)
p_171d_sc=fltarr(ndys)
p_304d_sc=fltarr(ndys)
p_lyad_sc=fltarr(ndys)
p_171_sr=fltarr(ndys)
p_304_sr=fltarr(ndys)
p_335_sr=fltarr(ndys)
p_369_sr=fltarr(ndys)
p_qd_sr=fltarr(ndys)
p_171d_sr=fltarr(ndys)
p_304d_sr=fltarr(ndys)
p_lyad_sr=fltarr(ndys)
for m=0,ndys-1 do begin
   p_171_sc[m]=(s171_sc[m]/min_171)-1.
   p_171_sr[m]=(s171_sr[m]/min_171)
   p_304_sc[m]=(s304_sc[m]/min_304)-1.
   p_304_sr[m]=(s304_sr[m]/min_304)
   p_335_sc[m]=(s335_sc[m]/min_335)-1.
   p_335_sr[m]=(s335_sr[m]/min_335)
   p_369_sc[m]=(s369_sc[m]/min_369)-1.
   p_369_sr[m]=(s369_sr[m]/min_369)
   p_qd_sc[m]=(sqd_sc[m]/min_qd)-1.
   p_qd_sr[m]=(sqd_sr[m]/min_qd)
   p_171d_sc[m]=(s171d_sc[m]/min_171d)-1.
   p_171d_sr[m]=(s171d_sr[m]/min_171d)
   p_304d_sc[m]=(s304d_sc[m]/min_304d)-1.
   p_304d_sr[m]=(s304d_sr[m]/min_304d)
   p_lyad_sc[m]=(slyad_sc[m]/min_lyad)-1.
   p_lyad_sr[m]=(slyad_sr[m]/min_lyad)
endfor
ndys=n_elements(day_ar_all)
sc_av=fltarr(ndys)
sr_av=fltarr(ndys)

; Eliminate F10.7 sr spikes from particle hits in the F10.7 data
gd=where(p_f107_sr-smooth(p_f107_sr,5, /edge_truncate) lt 0.5)
gd_ft_yf=dblarr(n_elements(gd))
ngd_ft=n_elements(gd)
for m=0,ngd_ft-1 do begin
   gd_ft_yf[m]=yd_to_yfrac(day_ar_all[gd[m]])
endfor
all_ft_yf=dblarr(n_elements(day_ar_all))
ndys=n_elements(day_ar_all)
for n=0,ndys-1 do begin
   all_ft_yf[n]=yd_to_yfrac(day_ar_all[n])
endfor

nw_p_f107_sr=interpol(p_f107_sr[gd],gd_ft_yf,all_ft_yf)
p_f107_sr=nw_p_f107_sr

print, 'Saving proxies_pred.sav'
fname = expand_path('$tmp_dir') + '/proxies_pred.sav'
save, day_ar_all, p_mgii, p_f107, p_goes, p_lya, p_335, p_369, p_304, $ 
	p_mgii_sc, p_f107_sc, p_goes_sc, p_lya_sc, p_335_sc, p_369_sc, $
	p_mgii_sr, p_f107_sr, p_goes_sr, p_lya_sr, p_335_sr, p_369_sr, $
	p_qd, p_qd_sc, p_qd_sr, p_304_sc, p_304_sr, end_yd_pred, $
        p_171_sc, p_171_sr, p_171, eve_wv, p_171d, p_171d_sc, p_171d_sr, $
        p_304d, p_304d_sc, p_304d_sr, p_lyad, p_lyad_sc, p_lyad_sr, $
	file=fname

print, 'End Time find_3_prox_pred: ', !stime

end
