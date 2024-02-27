;
; NAME: conact_min_sp.pro
;
; PURPOSE: to use the f10.7 or MgII extrapolated minimum spectrum
;	where best in the FISMref minimum spectrum (use exp fit)
;
; MODIFICATION HISTORY:
;	PCC	6/21/05	Program Creation
;	PCC	12/01/06	Updated for MacOSX
;				Changed default to Exp
;       ***VERSION 02_01
;       PCC     5/23/12         Updated for SDO/EVE
;

pro concat_min_sp, plots=plots, ps_out=ps_out

print, 'Running concat_min_sp.pro', !stime

save_pth = expand_path('$fism_save') 
restore, save_pth+'/eve_min_sp_3.sav'

fismref_sp=min_max_sp_mgii_e	; Default Exp Mgii

nwvs=n_elements(min_max_sp_f107[0,*])
ref_ar=intarr(nwvs)
for i=0,nwvs-1 do begin
	stdev_ar=[reform(stdev_ar_m[0,1,i]),reform(stdev_ar_l[0,1,i]),$
		reform(stdev_ar_f[0,0,i])]
	min_ar=[reform(min_max_sp_mgii_e[1,i]),$
		reform(min_max_sp_lya_e[1,i]),$
		reform(min_max_sp_f107_e[1,i])]
	max_ar=[reform(min_max_sp_mgii_e[2,i]),$
		reform(min_max_sp_lya_e[2,i]),$
		reform(min_max_sp_f107_e[2,i])]
	; Get the min spectrum
	srt_ind=sort(stdev_ar)
	; Make sure min is not less than 0
	if min_ar[srt_ind[0]] le 0.0 then srt_ind[0]=srt_ind[1]
	fismref_sp[1,i]=min_ar[srt_ind[0]]
	ref_ar[i]=srt_ind[0]

        ;  TOOK OUT BELOW CHECKS DUE TO BAD DATA/LONG TERM CALIBRATION
        ; Check to make sure minimum eve measurement is not lower than
        ;  extrapolated minimum (e.g. negative slope fit)
        ;gd_eve=where(eve_data[i,*] gt 0.0)
        ;if gd_eve[0] ne -1 then begin
        ;   min_eve=min(eve_data[i,gd_eve])
        ;   if fismref_sp[1,i] gt min_eve then fismref_sp[1,i]=min_eve
        ;endif
	;fismref_sp[2,i]=max_ar[srt_ind[0]]
        ; Check to make sure maximum eve measurement is not greater than
        ;  extrapolated maximum (e.g. negative slope fit)
        ;if gd_eve[0] ne -1 then begin
        ;   max_eve=max(eve_data[i,gd_eve])
        ;   if fismref_sp[2,i] lt max_eve then fismref_sp[2,i]=max_eve
        ;endif
endfor

old_fismref=fismref_sp

; Replace the FUV extrapolations with the UARS minimum spectrum
;restore, '$fism_data/uars_sol/uars_sp_all.sav'
;us_sp=us_sp*1e-9
;nwv=n_elements(us_wv)
;for k=0,nwv-2 do begin
;	gd_us=where(us_sp[k,*] gt 0.0)
;	sm_us=smooth(reform(us_sp[k,gd_us]),107,/edge,/nan)
;	max_us=max(sm_us,min=min_us)
;	fismref_sp[1,us_wv[k]]=min_us
;	fismref_sp[2,us_wv[k]]=max_us
;endfor

if keyword_set(plots) then begin	
	cc=independent_color()
        restore, '~/Reference\ Spectrum/whi_sol_ref_sp_2008.sav'

	if keyword_set(ps_out) then open_ps, '$fism_plots/fismref_sp.ps', /landscape, /color
	plot_io, fismref_sp[0,*], fismref_sp[1,*], $
		psym=10, yr=[1e-7,1e-3], charsize=1.8,	ytitle='W/m^2/nm', $
		xtitle='Wavelength (nm)', xr=[0,195], xs=1, $
		title='Black: FISMref, Blue: WHI'
	oplot, sol_ref_sp[0,*], sol_ref_sp[1,*], color=cc.blue, psym=10
	if keyword_set(ps_out) then close_ps else stop
endif



print, 'Saving eve_min_sp.sav'
save, fismref_sp, min_f107, max_f107, min_mgii, max_mgii, $
	min_lya, max_lya, ref_ar, file=save_pth+'/eve_min_sp.sav'

print, 'End Time: ', !stime

end
