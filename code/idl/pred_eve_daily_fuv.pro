;
; NAME: pred_eve_daily.pro
;
; PURPOSE: to use the coefficiants produced by to predict the FISM
; Daily spectrum.
;
; USAGE:
;	pred_sp=pred_eve_daily(yyyydoy, utc, version=version, tag)
;
; OUTPUT:  
;	pred_sp: the predicted see spectrum for the given day and time
;	wv: variable for the wavelength scale
;
; MODIFICATION HISTORY:
;	PCC 2/24/04	Program Creation
;	PCC 3/2/04	Added version number keyword
;	PCC 5/6/04	Made more general
;	PCC 5/27/04	Version 7 update
;	PCC 6/9/04	Eliminated wavelength input
;	PCC 7/25/04	Updated for v9
;	PCC 4/7/05	Added keyword /scav to return the sc/sr modeled spectrum
;	PCC 12/01/06	Updated for MacOSX
;
;       VERSION 2_01
;       PCC    6/20/12  Updated for SDO/EVE
;+

function pred_eve_daily_fuv, yyyydoy, utc, no_scav=no_scav, sr_coef=sr_coef, $
	tag=tag, daily=daily, split_sr=split_sr, scsr_split=scsr_split

common goes_data_com, goes, goes_pri, ychk, day_ar_all, coefs, p_mgii, p_f107, p_goes, $
        p_171, p_171_sc, p_171_sr, p_171d, p_171d_sc, p_171d_sr, $
	p_335, p_369, p_lya, p_qd, fit_coefs, p_mgii_sc, p_mgii_sr, $
	p_f107_sc, p_f107_sr, p_qd_sc, p_qd_sr, p_369_sc, p_369_sr, $
	p_lya_sc, p_lya_sr, p_304, p_304_sc, p_304_sr, p_335_sc, $
	p_335_sr, p_goes_sc, p_goes_sr, fit_coefs_scsr, fit_coefs_sr, $
	fit_coefs_sc, def_tag, backup_ar, err_tag, nwv, $
        p_304d, p_304d_sc, p_304d_sr, p_lyad, p_lyad_sc, p_lyad_sr

yyyydoy=fix(yyyydoy,type=3)

;print, yyyydoy

dy_ind=where(day_ar_all eq yyyydoy)

;FISM fit ; 0=lya, 1=mgii, 2=f107
x_fit=dblarr(3)
x_fit[0]=p_lya[dy_ind]
x_fit[1]=p_mgii[dy_ind]
x_fit[2]=p_f107[dy_ind];>0.001
; FISM SC fit
x_fit_sc=dblarr(3)
x_fit_sc[0]=p_lya_sc[dy_ind]
x_fit_sc[1]=p_mgii_sc[dy_ind]
x_fit_sc[2]=p_f107_sc[dy_ind]
; FISM SR fit
x_fit_sr=dblarr(12)
x_fit_sr[0]=p_lya_sr[dy_ind]
x_fit_sr[1]=p_mgii_sr[dy_ind]
x_fit_sr[2]=p_f107_sr[dy_ind]

; Make sure proxy exist, if not, adjust tag
wbd_prox=-1
if x_fit_sc[tag] le 0.0 then begin 
	wbd_prox=1
	;print, tag
	while x_fit_sc[tag] lt 0.0 do begin
		tag=backup_ar[tag]
		;print, tag
	endwhile
	coef_fl=expand_path('$fism_save')+'/sc_sr_fit_coefs_fuv_tag'+strtrim(tag,2)+'.sav'
	restore, coef_fl
endif
err_tag=tag

x_fit=x_fit[tag]
x_fit_sc=x_fit_sc[tag]
x_fit_sr=x_fit_sr[tag]
x_fit_scsr=[x_fit_sc,x_fit_sr]
nx=n_elements(x_fit)
nx_scsr=n_elements(x_fit_scsr)


pred_fuv_dmin=fltarr(nwv)
pred_fuv_dmin_scsr=fltarr(nwv)
pred_fuv_dmin_sc=fltarr(nwv)
pred_fuv_dmin_sr=fltarr(nwv)
pred_fuv_dmin_srcoef=fltarr(nwv)
pred_fuv_dmin_srsplit=fltarr(nwv)

for j=0,nwv-1 do begin
	;FISM Pred
	pred_fuv_dmin_sc[j]=fit_coefs_sc[0,j]+1.; +1 takes care of the min sub in numerator before dividing
	pred_fuv_dmin_sr[j]=fit_coefs_sr[0,j] ; sr doesn't subtract off min before dividing
	;for k=0,nx-1 do begin
		;pred_see_dmin_scsr[j]=pred_see_dmin_scsr[j]+(fit_coefs_scsr[k+1,j]* $
		;	x_fit_scsr[k])+(fit_coefs_scsr[k+(nx_scsr/2)+1,j]*x_fit_scsr[k+(nx_scsr/2)])
		pred_fuv_dmin_sc[j]=pred_fuv_dmin_sc[j]+(fit_coefs_sc[1,j]*x_fit_sc)
		pred_fuv_dmin_sr[j]=pred_fuv_dmin_sr[j]+(fit_coefs_sr[1,j]*x_fit_sr)
        ;endfor
        ;if tag eq 7 then stop
endfor

; Multiply by the minimum reference spectrum
pred_sp_sc=mult_min_fuv(pred_fuv_dmin_sc, tag)
pred_sp_sr=mult_min_fuv(pred_fuv_dmin_sr, tag)

; Add solar cycle and solar rotation predictions into one spectrum
pred_sp_scsr=pred_sp_sc+pred_sp_sr

; Reset tag to default tag and get default fit coefs
if wbd_prox[0] ne -1 then begin
	tag=def_tag
	; Restore the fit coefs created by 'three_prox_sr_av.pro'
	coef_fl='$fism_save/sc_sr_fit_coefs_fuv_tag'+strtrim(tag,2)+'.sav'
	restore, coef_fl
endif

if keyword_set(scsr_split) then begin
	;print, 'Returning the SC/SR split fit FISM spectrum'
	;stop
	return, pred_sp_scsr
endif else if keyword_set(sr_coef) then begin
	;print, 'Returning the SR coef fit FISM spectrum'
	;stop
	return, pred_sp_srcoef
endif else if keyword_set(split_sr) then begin
	;print, 'Returning the SR split fit FISM spectrum'
	;stop
	return, pred_sp_srsplit
endif else begin
	;print, 'Returning the NON-SC/SR split fit FISM spectrum'
	;stop
	return, pred_sp
endelse

end

