;
; NAME: find_gp_flare_error
;
; PURPOSE: to findt the FISM gradual phase error
;
; MODIFICATION HISTORY
;	PCC	8/16/05	Program Creation
;	PCC	12/04/06 Updated for Max OSX
;
;       Version 2_01
;       PCC     6/24/12  Updated for SDO/EVE


pro find_gp_flare_error

print, 'Running find_gp_flare_error.pro', !stime

restore, expand_path('$fism_save')+'/fism_version_file.sav'

; Use to process All Flares Observed by EVE
restore, expand_path('$fism_save')+'/eve_flare_info.sav'
ndys=n_elements(yd)

; Restore an initial FISM saveset to get array dimensions
fism_pth=expand_path('$fism_results')+'/flare_data/'+strmid(strtrim(yd[i],2),0,4)+'/'
restore, fism_pth+'FISM_60sec_'+strtrim(yd[i],2)+'_'+version+'.sav'
nwvs=n_elements(fism_wv)

tot_diff_sq=fltarr(nwvs)

ans=''
for i=0,ndys-1 do begin


	; Restore the FISM saveset w/flares for the given day
        yr_string=strmid(strtrim(yd[i],2),0,4)
	restore, fism_pth+'/'+yr_string+'/'+'FISM_60sec_'+strtrim(dyar[i],2)+'_'+version+'.sav'

	; Restore the EVE data for that day/flare	
	; EVE daily (1A bins)
        tmp_pth=expand_path('$tmp_dir')
        restore, tmp_pth+'/eve_sc_av.sav'
	; EVE 10sec data - from 'find_ip_gp_powerfunct_eve.pro'
        restore, expand_path('tmp_dir')+'/'+yr_string+'/'+'eve_flr_data_'+strtrim(dyar[i],2)+'.sav'

	; Get the start and stop times from the stored EVE 10sec data above
	flr_start_time=egs_l2a_data.start_time
	egs_stop_time=egs_l2a_data.stop_time

	; Find the SEE spectrum that is closest to the UTC
	wgd_see_sp_gt=where(see_l3a_data.start_time ge utcar[i])
	if wgd_see_sp_gt[0] ne -1 then begin
		diff_gt=see_l3a_data[wgd_see_sp_gt[0]].start_time-utcar[i]
	endif else begin
		diff_gt=86400.
	endelse
	wgd_see_sp_lt=where(see_l3a_data.start_time lt utcar[i])
	n_lt=n_elements(wgd_see_sp_lt)
	if wgd_see_sp_lt[0] ne -1 then begin
		diff_lt=utcar[i]-see_l3a_data[wgd_see_sp_lt[n_lt-1]].start_time 
	endif else begin
		diff_lt=86400.
	endelse
	if diff_gt le diff_lt then begin	
		see_sp=see_l3a_data[wgd_see_sp_gt[0]].sp.flux 
		see_wv=see_l3a_data[wgd_see_sp_gt[0]].sp.wave
		wsee=wgd_see_sp_gt[0]
		diff_time_see=diff_gt
	endif else begin
		see_sp=see_l3a_data[wgd_see_sp_lt[n_lt-1]].sp.flux
		see_wv=see_l3a_data[wgd_see_sp_lt[n_lt-1]].sp.wave
		wsee=wgd_see_sp_lt[wgd_see_sp_lt[n_lt-1]]
		diff_time_see=diff_lt*(-1.)
	endelse
	
	; Find the XPS spectrum that is closest to the UTC
	wgd_xps_sp_gt=where(xps_l2a_data.start_time ge utcar[i])
	if wgd_xps_sp_gt[0] ne -1 then begin
		diff_gt=xps_l2a_data[wgd_xps_sp_gt[0]].start_time-utcar[i]
	endif else begin
		diff_gt=86400.
	endelse
	wgd_xps_sp_lt=where(xps_l2a_data.start_time lt utcar[i])
	n_lt=n_elements(wgd_xps_sp_lt)
	if wgd_xps_sp_lt[0] ne -1 then begin
		diff_lt=utcar[i]-xps_l2a_data[wgd_xps_sp_lt[n_lt-1]].start_time 
	endif else begin
		diff_lt=86400.
	endelse
	if diff_gt le diff_lt then begin
		xps_start_time=xps_l2a_data[wgd_xps_sp_gt[0]].start_time
		xps_stop_time=xps_l2a_data[wgd_xps_sp_gt[0]].stop_time
	endif else begin
		xps_start_time=xps_l2a_data[wgd_xps_sp_lt[n_lt-1]].start_time
		xps_stop_time=xps_l2a_data[wgd_xps_sp_lt[n_lt-1]].stop_time
	endelse
	
	; Find the median FISM spectrum that is within the EGS and XPS times
	wgd_egs_fism_sp=where(utc ge egs_start_time[wsee] and utc le egs_stop_time[wsee])
	if n_elements(wgd_egs_fism_sp) le 1 then begin
		wgd_egs_fism_sp_tmp=where(utc ge egs_start_time[wsee])
		wgd_egs_fism_sp=[wgd_egs_fism_sp_tmp[0]-1,wgd_egs_fism_sp_tmp[0]]
	endif
	nwv_fism=n_elements(fism_wv)
	fism_sp=fltarr(nwv_fism)
	for a=27,nwv_fism-1 do fism_sp[a]=median(fism_pred[wgd_egs_fism_sp,a])
	med_utc_egs=median(utc[wgd_egs_fism_sp])
	wgd_xps_fism_sp=where(utc ge xps_start_time and utc le xps_stop_time)
	for a=0,26 do fism_sp[a]=median(fism_pred[wgd_xps_fism_sp,a])
	diff_time_fism=med_utc_egs-utcar[i]
	check_pre=abs(utc[wgd_egs_fism_sp[0]-1]-utcar[i])
	if check_pre le diff_time_fism then begin
		wgd_egs_fism_sp[0]=wgd_egs_fism_sp[0]-1
		fism_sp=reform(fism_pred[wgd_egs_fism_sp[0],*])
		diff_time_fism=med_utc_egs-utcar[i]
	endif

	; Subtract off fism daily prediction, then add back SEE daily to
	;	get correct % gp error in FUV where SOLSTICE is used
	restore, '$fism_results/daily_data/FISM_daily_'+$
		strtrim(dyar[i],2)+'_'+version+'.sav'
	fism_sp=fism_sp-fism_pred+see_l3_data.sp.flux
	
	see_sp_tmp=see_sp
	gd=where(see_sp gt 0.0)
	see_sp=fism_sp*1.15	; Assume 30% error if no SEE data
	see_sp[gd]=see_sp_tmp[gd]	
	tot_diff_sq=tot_diff_sq+(((fism_sp-see_sp)/see_sp)^2.)
	;stop
endfor

fism_gp_flare_error=sqrt(tot_diff_sq/(ndys-1.))

; Find the absolute FISM error by adding the SEE L3a mean error in quadrature
restore, '$fism_save/see_l3a_mean_err.sav'
fism_gp_flare_error_abs=sqrt(fism_gp_flare_error^2.+see_l3a_err^2.)

;stop
print, 'Saving fism_gp_flare_error.sav'
save, fism_gp_flare_error, fism_gp_flare_error_abs, $
	file='$fism_save/fism_gp_flare_error.sav'


end
	
