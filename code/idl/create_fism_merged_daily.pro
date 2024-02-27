;
; NAME: create_fism_merged_daily.pro
;
; PURPOSE: to merge the FISM daily data into one saveset
;
; MODIFICATION HISTORY:
;	PCC	7/18/05	program creation
;	PCC	12/01/06 Updated for MacOSX
;	PCC	12/04/06 Added Start and End years as keyword
;
;       VERSION 02_01
;       PCC    6/21/12   Updated for SDO/EVE
;       PCC    7/30/12   Added keyword 'alltags' to merge all proxy tags

pro create_fism_merged_daily, strt_yr=strt_yr, end_yr=end_yr, update=update

print, 'Running create_fism_merged_daily: ', !stime

if keyword_set(strt_yr) then st_yd=strt_yr*1000l+1l else st_yd=1947045
cur_yd=get_current_yyyydoy()
;restore, expand_path('$fism_save')+'/end_yd_pred.sav'
if keyword_set(end_yr) then end_yd=end_yr*1000l+365l else end_yd=get_current_yyyydoy()-6

restore, expand_path('$fism_save')+'/fism_version_file.sav'
;version='02_01'
res_pth= expand_path('$fism_results')+'/daily_hr_data'
res_pth_tags= expand_path('$tmp_dir')
sv_pth= expand_path('$fism_results')+'/merged'

FILE_MKDIR, sv_pth

if keyword_set(update) then begin
	tdy=get_current_yyyydoy()
	st_yd=get_prev_yyyydoy(tdy,60) ; update the past 60 days
	restore,  expand_path('$fism_results')+'/merged/FISM_daily_merged_'+version+'.sav'
	keep_dys=where(day_ar lt st_yd)
	fism_pred_tmp=fism_pred[keep_dys,*]
	fism_err_tmp = fism_err_all[keep_dys, *]
	;fism_err_tmp=fism_error[keep_dys,*]
        
	day_ar_tmp=day_ar[keep_dys]
endif else begin
        restore, res_pth+'/2011/FISM_daily_2011010_v'+version+'.sav' ; example to get wv
        nwvs=n_elements(wavelength)
	fism_pred_tmp=fltarr(1,nwvs)
	fism_err_tmp=fltarr(1,nwvs)
        
	day_ar_tmp=lonarr(1)
endelse

tmp_yd=st_yd
while tmp_yd le end_yd-1 do begin
        yr = strmid(strtrim(tmp_yd,2), 0, 4)
        yd = strtrim(tmp_yd,2)
	restore, res_pth+'/'+yr+'/FISM_daily_'+strmid(yd,0,7)+'_v'+version+'.sav'
	fism_pred_tmp=[fism_pred_tmp,transpose(irradiance)]
	fism_err_tmp=[fism_err_tmp,transpose(uncertainty)]
        
	day_ar_tmp=[day_ar_tmp,tmp_yd]
	tmp_yd=get_next_yyyydoy(tmp_yd)
endwhile

ndys=n_elements(day_ar_tmp)
fism_pred=fism_pred_tmp[1:ndys-1,*]
fism_err_all=fism_err_tmp[1:ndys-1,*]

day_ar=day_ar_tmp[1:ndys-1]

;fism_wv=findgen(195)+0.5
if keyword_set(strt_yr) then begin
	if keyword_set(end_yr) then begin
		if strt_yr eq end_yr then begin
			flnm=sv_pth+'/FISM_daily_merged_'+strtrim(strt_yr,2)+'_v'+version
		endif else begin
			flnm=sv_pth+'/FISM_daily_merged_'+strtrim(strt_yr,2)+'_v'+$
				strtrim(end_yr,2)+'_'+version
		endelse
	endif else begin
		flnm=sv_pth+'/FISM_daily_merged_'+strtrim(strt_yr,2)+'_v'+$
			strmid(strtrim(cur_yd,2),0,4)+'_v'+version
	endelse
endif else begin
	if keyword_set(end_yr) then begin
		flnm=sv_pth+'/FISM_daily_merged_1947_'+$
			strtrim(end_yr,2)+'_'+version
	endif else begin
		flnm=sv_pth+'/FISM_daily_merged_'+version
	endelse
endelse

; Save data if /alltags is set
;Print, 'Saving ',flnm	


; Save FISM merged data regardless
flnm=flnm+'.sav'
save, fism_pred, fism_err_all, wavelength, day_ar, file=flnm ; , fism_error


print, 'End Time create_fism_merged_daily: ', !stime


end	
