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

pro create_fism_eve_merged_daily, strt_yr=strt_yr, end_yr=end_yr, update=update, $
  alltags=alltags

print, 'Running crate_fism_merged_daily', !stime

if keyword_set(strt_yr) then st_yd=strt_yr*1000l+1l else st_yd=1947045
cur_yd=get_current_yyyydoy()
;restore, expand_path('$fism_save')+'/end_yd_pred.sav'
if keyword_set(end_yr) then end_yd=end_yr*1000l+365l else end_yd=get_current_yyyydoy()-6;2

restore, expand_path('$fism_save')+'/fism_version_file.sav'
;version='02_01'
res_pth= expand_path('$fism_results')+'/daily_data/euv/'
res_pth_tags= expand_path('$tmp_dir')
sv_pth= expand_path('$fism_results')+'/merged'

FILE_MKDIR, sv_pth

if keyword_set(update) then begin
	tdy=get_current_yyyydoy()
	st_yd=get_prev_yyyydoy(tdy,90) ; update the past 60 days
	restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'.sav'
	keep_dys=where(day_ar lt st_yd)
	fism_pred_tmp=fism_pred[keep_dys,*]
	fism_err_tmp=fism_error[keep_dys,*]
        if keyword_set(alltags) then begin
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag1.sav'
           fism_pred_tmp_tag1=fism_pred_tag1[keep_dys,*]
           fism_err_tmp_tag1=fism_error_tag1[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag2.sav'
           fism_pred_tmp_tag2=fism_pred_tag2[keep_dys,*]
           fism_err_tmp_tag2=fism_error_tag2[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag3.sav'
           fism_pred_tmp_tag3=fism_pred_tag3[keep_dys,*]
           fism_err_tmp_tag3=fism_error_tag3[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag4.sav'
           fism_pred_tmp_tag4=fism_pred_tag4[keep_dys,*]
           fism_err_tmp_tag4=fism_error_tag4[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag5.sav'
           fism_pred_tmp_tag5=fism_pred_tag5[keep_dys,*]
           fism_err_tmp_tag5=fism_error_tag5[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag6.sav'
           fism_pred_tmp_tag6=fism_pred_tag6[keep_dys,*]
           fism_err_tmp_tag6=fism_error_tag6[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag7.sav'
           fism_pred_tmp_tag7=fism_pred_tag7[keep_dys,*]
           fism_err_tmp_tag7=fism_error_tag7[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag8.sav'
           fism_pred_tmp_tag8=fism_pred_tag8[keep_dys,*]
           fism_err_tmp_tag8=fism_error_tag8[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag9.sav'
           fism_pred_tmp_tag9=fism_pred_tag9[keep_dys,*]
           fism_err_tmp_tag9=fism_error_tag9[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag10.sav'
           fism_pred_tmp_tag10=fism_pred_tag10[keep_dys,*]
           fism_err_tmp_tag10=fism_error_tag10[keep_dys,*]
           restore,  expand_path('$fism_results')+'/merged/FISM_daily_eve_merged_'+version+'_tag11.sav'
           fism_pred_tmp_tag11=fism_pred_tag11[keep_dys,*]
           fism_err_tmp_tag11=fism_error_tag11[keep_dys,*]
        endif 
	day_ar_tmp=day_ar[keep_dys]
endif else begin
        restore, res_pth+'/2011/FISM_daily_2011010_'+version+'.sav' ; example to get wv
        nwvs=n_elements(fism_wv)
	fism_pred_tmp=fltarr(1,nwvs)
	fism_err_tmp=fltarr(1,nwvs)
        if keyword_set(alltags) then begin
           fism_pred_tmp_tag1=fltarr(1,nwvs)
           fism_err_tmp_tag1=fltarr(1,nwvs)
           fism_pred_tmp_tag2=fltarr(1,nwvs)
           fism_err_tmp_tag2=fltarr(1,nwvs)
           fism_pred_tmp_tag3=fltarr(1,nwvs)
           fism_err_tmp_tag3=fltarr(1,nwvs)
           fism_pred_tmp_tag4=fltarr(1,nwvs)
           fism_err_tmp_tag4=fltarr(1,nwvs)
           fism_pred_tmp_tag5=fltarr(1,nwvs)
           fism_err_tmp_tag5=fltarr(1,nwvs)
           fism_pred_tmp_tag6=fltarr(1,nwvs)
           fism_err_tmp_tag6=fltarr(1,nwvs)
           fism_pred_tmp_tag7=fltarr(1,nwvs)
           fism_err_tmp_tag7=fltarr(1,nwvs)
           fism_pred_tmp_tag8=fltarr(1,nwvs)
           fism_err_tmp_tag8=fltarr(1,nwvs)
           fism_pred_tmp_tag9=fltarr(1,nwvs)
           fism_err_tmp_tag9=fltarr(1,nwvs)
           fism_pred_tmp_tag10=fltarr(1,nwvs)
           fism_err_tmp_tag10=fltarr(1,nwvs)
           fism_pred_tmp_tag11=fltarr(1,nwvs)
           fism_err_tmp_tag11=fltarr(1,nwvs)
        endif 
	day_ar_tmp=lonarr(1)
endelse

tmp_yd=st_yd
while tmp_yd le end_yd-1 do begin
        yr = strmid(strtrim(tmp_yd,2), 0, 4)
	restore, expand_path('$fism_results')+'/daily_data/euv/'+yr+'/FISM_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_'+version+'.sav'
	fism_pred_tmp=[fism_pred_tmp,transpose(fism_pred)]
	fism_err_tmp=[fism_err_tmp,transpose(fism_error)]
        if keyword_set(alltags) then begin
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag1.sav'
           fism_pred_tmp_tag1=[fism_pred_tmp_tag1,transpose(fism_pred)]
           fism_err_tmp_tag1=[fism_err_tmp_tag1,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag2.sav'
           fism_pred_tmp_tag2=[fism_pred_tmp_tag2,transpose(fism_pred)]
           fism_err_tmp_tag2=[fism_err_tmp_tag2,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag3.sav'
           fism_pred_tmp_tag3=[fism_pred_tmp_tag3,transpose(fism_pred)]
           fism_err_tmp_tag3=[fism_err_tmp_tag3,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag4.sav'
           fism_pred_tmp_tag4=[fism_pred_tmp_tag4,transpose(fism_pred)]
           fism_err_tmp_tag4=[fism_err_tmp_tag4,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag5.sav'
           fism_pred_tmp_tag5=[fism_pred_tmp_tag5,transpose(fism_pred)]
           fism_err_tmp_tag5=[fism_err_tmp_tag5,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag6.sav'
           fism_pred_tmp_tag6=[fism_pred_tmp_tag6,transpose(fism_pred)]
           fism_err_tmp_tag6=[fism_err_tmp_tag6,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag7.sav'
           fism_pred_tmp_tag7=[fism_pred_tmp_tag7,transpose(fism_pred)]
           fism_err_tmp_tag7=[fism_err_tmp_tag7,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag8.sav'
           fism_pred_tmp_tag8=[fism_pred_tmp_tag8,transpose(fism_pred)]
           fism_err_tmp_tag8=[fism_err_tmp_tag8,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag9.sav'
           fism_pred_tmp_tag9=[fism_pred_tmp_tag9,transpose(fism_pred)]
           fism_err_tmp_tag9=[fism_err_tmp_tag9,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag10.sav'
           fism_pred_tmp_tag10=[fism_pred_tmp_tag10,transpose(fism_pred)]
           fism_err_tmp_tag10=[fism_err_tmp_tag10,transpose(fism_error)]
           restore, res_pth_tags+'/'+yr+'/FISM_tmp_daily_'+strmid(strtrim(tmp_yd,2), 0,7)+'_tag11.sav'
           fism_pred_tmp_tag11=[fism_pred_tmp_tag11,transpose(fism_pred)]
           fism_err_tmp_tag11=[fism_err_tmp_tag11,transpose(fism_error)]
        endif
	day_ar_tmp=[day_ar_tmp,tmp_yd]
	tmp_yd=get_next_yyyydoy(tmp_yd)
endwhile

ndys=n_elements(day_ar_tmp)
fism_pred=fism_pred_tmp[1:ndys-1,*]
fism_error=fism_err_tmp[1:ndys-1,*]
if keyword_set(alltags) then begin
   fism_pred_tag1=fism_pred_tmp_tag1[1:ndys-1,*]
   fism_error_tag1=fism_err_tmp_tag1[1:ndys-1,*]
   fism_pred_tag2=fism_pred_tmp_tag2[1:ndys-1,*]
   fism_error_tag2=fism_err_tmp_tag2[1:ndys-1,*]
   fism_pred_tag3=fism_pred_tmp_tag3[1:ndys-1,*]
   fism_error_tag3=fism_err_tmp_tag3[1:ndys-1,*]
   fism_pred_tag4=fism_pred_tmp_tag4[1:ndys-1,*]
   fism_error_tag4=fism_err_tmp_tag4[1:ndys-1,*]
   fism_pred_tag5=fism_pred_tmp_tag5[1:ndys-1,*]
   fism_error_tag5=fism_err_tmp_tag5[1:ndys-1,*]
   fism_pred_tag6=fism_pred_tmp_tag6[1:ndys-1,*]
   fism_error_tag6=fism_err_tmp_tag6[1:ndys-1,*]
   fism_pred_tag7=fism_pred_tmp_tag7[1:ndys-1,*]
   fism_error_tag7=fism_err_tmp_tag7[1:ndys-1,*]
   fism_pred_tag8=fism_pred_tmp_tag8[1:ndys-1,*]
   fism_error_tag8=fism_err_tmp_tag8[1:ndys-1,*]
   fism_pred_tag9=fism_pred_tmp_tag9[1:ndys-1,*]
   fism_error_tag9=fism_err_tmp_tag9[1:ndys-1,*]
   fism_pred_tag10=fism_pred_tmp_tag10[1:ndys-1,*]
   fism_error_tag10=fism_err_tmp_tag10[1:ndys-1,*]
   fism_pred_tag11=fism_pred_tmp_tag11[1:ndys-1,*]
   fism_error_tag11=fism_err_tmp_tag11[1:ndys-1,*]
endif
day_ar=day_ar_tmp[1:ndys-1]

;fism_wv=findgen(195)+0.5
if keyword_set(strt_yr) then begin
	if keyword_set(end_yr) then begin
		if strt_yr eq end_yr then begin
			flnm=sv_pth+'/FISM_daily_eve_merged_'+strtrim(strt_yr,2)+'_'+version
		endif else begin
			flnm=sv_pth+'/FISM_daily_eve_merged_'+strtrim(strt_yr,2)+'_'+$
				strtrim(end_yr,2)+'_'+version
		endelse
	endif else begin
		flnm=sv_pth+'/FISM_daily_eve_merged_'+strtrim(strt_yr,2)+'_'+$
			strmid(strtrim(cur_yd,2),0,4)+'_'+version
	endelse
endif else begin
	if keyword_set(end_yr) then begin
		flnm=sv_pth+'/FISM_daily_merged_1947_'+$
			strtrim(end_yr,2)+'_'+version
	endif else begin
		flnm=sv_pth+'/FISM_daily_eve_merged_'+version
	endelse
endelse

; Save data if /alltags is set
Print, 'Saving ',flnm	
if keyword_set(alltags) then begin
   flnm1=flnm+'_tag1.sav'
   save, fism_pred_tag1, fism_error_tag1, fism_wv, day_ar, file=flnm1
   flnm2=flnm+'_tag2.sav'
   save, fism_pred_tag2, fism_error_tag2, fism_wv, day_ar, file=flnm2
   flnm3=flnm+'_tag3.sav'
   save, fism_pred_tag3, fism_error_tag3, fism_wv, day_ar, file=flnm3
   flnm4=flnm+'_tag4.sav'
   save, fism_pred_tag4, fism_error_tag4, fism_wv, day_ar, file=flnm4
   flnm5=flnm+'_tag5.sav'
   save, fism_pred_tag5, fism_error_tag5, fism_wv, day_ar, file=flnm5
   flnm6=flnm+'_tag6.sav'
   save, fism_pred_tag6, fism_error_tag6, fism_wv, day_ar, file=flnm6
   flnm7=flnm+'_tag7.sav'
   save, fism_pred_tag7, fism_error_tag7, fism_wv, day_ar, file=flnm7
   flnm8=flnm+'_tag8.sav'
   save, fism_pred_tag8, fism_error_tag8, fism_wv, day_ar, file=flnm8
   flnm9=flnm+'_tag9.sav'
   save, fism_pred_tag9, fism_error_tag9, fism_wv, day_ar, file=flnm9
   flnm10=flnm+'_tag10.sav'
   save, fism_pred_tag10, fism_error_tag10, fism_wv, day_ar, file=flnm10
   flnm11=flnm+'_tag11.sav'
   save, fism_pred_tag11, fism_error_tag11, fism_wv, day_ar, file=flnm11
endif 

; Save FISM merged data regardless
flnm=flnm+'.sav'
save, fism_pred, fism_error, fism_wv, day_ar, file=flnm


print, 'End Time create_fism_merged_daily: ', !stime


end	
