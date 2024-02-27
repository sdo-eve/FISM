;
;  NAME: find_e_sc_e_sr.pro
;
;  PURPOSE: to create the ratio of the SEE data to the newly created minimum
;	spectrum for FISM version 10
;
;	E_sc=(EVE_sc_av/EVE_sc_av_min)-1.
;	E_sr=(EVE_l3_daily-EVE_sc_av)/EVE_sc_av_min
;
;  MODIFICATION HISTORY:
;	PCC	5/25/04		Program Creation
;	PCC	7/5/04		Modified for the SEE data l3 and l3a split
;	PCC	7/22/04		Changes for v9 to find E_sc and E_sr
;	PCC	8/3/04		Added the # of trailing days to average to
;				the saveset (from see_sc_av.sav)
;	PCC	3/28/05		v2. Adds a e_tot that does not split up the 
;				SC and SR components
;				NOTE: for lya, 33.5, and 36.5 proxies, just
;				use the mgii reference spectrum
;				use the exponential fit to avoid negative values
;	PCC	6/13/05		Now divide the SR by SC to get % change proxy
;	PCC	12/01/06	Updated for MacOSX
;       ***** VERSION 2_1
;       PCC     5/21/12         Updated to use SDO/EVE data
;
;+

pro find_e_sc_e_sr

print, 'Running find_e_sc_e_sr.pro', !stime

save_pth=expand_path('$fism_save') 
restore, save_pth+'/eve_min_sp.sav'
tmp_pth=expand_path('$tmp_dir')
restore, tmp_pth+'/eve_sc_av.sav'

nel_eve=n_elements(eve_day_ar)
nwvs_eve=n_elements(eve_wv)

;	Center
E_sr=fltarr(nel_eve,nwvs_eve)
E_sc=fltarr(nel_eve,nwvs_eve)
E_tot=fltarr(nel_eve,nwvs_eve)
for i=0,nwvs_eve-1 do E_sc[*,i]=(reform(eve_sc_av[i,*])/fismref_sp[1,i])-1.
; NOTE: see_sr res is already (E-Esc), so no need to subtract 1
for i=0,nwvs_eve-1 do E_sr[*,i]=reform(eve_sr_res[i,*])/fismref_sp[1,i]
for i=0,nwvs_eve-1 do E_tot[*,i]=(reform(eve_data[i,*])/fismref_sp[1,i])-1.

print, 'Saving eve_E_sc_E_sr.sav'
save, E_sr, E_sc, eve_day_ar, sc_avg_dys, $
	E_tot, eve_daily_err, eve_data, file=save_pth+'/eve_E_sc_E_sr.sav'

print, 'End Time find_e_sc_e_sr: ', !stime

end
