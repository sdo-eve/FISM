;
;  NAME: comp_fism_daily.pro
;
;  PURPOSE: to compile an array of the fism predicted spectra corresponding to
;	the SEE ODC times
;
;  MODIFICATION HISTORY:
;	PCC 6/8/04	'comp_fism_seetimes.pro'
;	PCC 7/15/04	Updated for daily model
;	PCC 8/23/04	Uses inputs for cron job
;	PCC 11/2/04	Changed to accept a day range to speed processing
;	PCC 3/23/04	Changed to process FISM for every minute of given days
;			'comp_fism_1min.pro
;	PCC 4/7/05	Added the keyword /scav to return the FISM sc/sr fit 
;			spectrum
;	PCC 4/11/05	Added the /daily keyword to just produce the daily model
;	PCC 12/01/06	Updated for MacOSX
;
;       VERSION 2_01    
;       PCC 6/20/12     Updated for SDO/EVE , changed name to '...evetimes..'
;       PCC 6/21/12     Updated to just have one proccesing code for
;                       pre-error analysis and post-error analysis processing
;                       keyword 'preerr' added to replace '... evetiems...' processing

pro comp_fism_daily, start_yd=start_yd, end_yd=end_yd, scsr_split=scsr_split, $
	no_scav=no_scav, tag_an=tag_an, sr_coef=sr_coef, sr_split=sr_split, preerr=preerr, update=update

if not keyword_set(scsr_split) then scsr_split=1 ; Make default 

print, 'Running comp_fism_daily, scsr_split=',strtrim(scsr_split,2), '  ', !stime

if not keyword_set(start_yd) and keyword_set(preerr) then start_yd=2010121 $ ; First day of normal SDO ops
   else if not keyword_set(start_yd) then start_yd=1947045
if keyword_set(update) then begin
   ;tdy=long(strmid(get_current_yyyydoy(), 7,8))
   tdy=fix(get_current_yyyydoy(),type=3)
   end_yd=fix(get_prev_yyyydoy(tdy,1),type=3)
   ;print, end_yd
   start_yd=get_prev_yyyydoy(tdy,90) ; run for the past 60 days

endif
save_pth = expand_path('$fism_results') 
sv_pth=save_pth+'/daily_data/'
common goes_data_com, goes, goes_pri, ychk, day_ar_all, coefs, p_mgii, p_f107, p_goes, $
        p_171, p_171_sc, p_171_sr, p_171d, p_171d_sc, p_171d_sr, $
	p_335, p_369, p_lya, p_qd, fit_coefs, p_mgii_sc, p_mgii_sr, $
	p_f107_sc, p_f107_sr, p_qd_sc, p_qd_sr, p_369_sc, p_369_sr, $
	p_lya_sc, p_lya_sr, p_304, p_304_sc, p_304_sr, p_335_sc, $
	p_335_sr, p_goes_sc, p_goes_sr, fit_coefs_scsr, fit_coefs_sr, $
	fit_coefs_sc, def_tag, backup_ar, err_tag, nwv, $
        p_304d, p_304d_sc, p_304d_sr, p_lyad, p_lyad_sc, p_lyad_sr
	
; Setup backup proxy array [primary]:secondary
;1'mgii' -> f107
;2'f107' -> Should alwasy be available (as I interpolate if not actually measured)
;3'goes' -> QD -> f107
;4'lya' -> mgii -> f107
;5'QD' -> f107
;6'171' -> 304 -> lya -> mgii -> f107
;7'304' -> lya -> mgii -> f107
;8'335' -> QD -> f107
;9'369' -> QD -> f107
;10'171d' -> '171' -> '304' -> 'lya' -> 'mgii' -> f107
;11'304d' -> '304' -> 'lya' -> 'mgii' -> f107
;12'lyad' -> 'lya' -> mgii -> f107
backup_ar=[2,1,5,1,2,7,4,5,5,6,7,4] ; note: from 1-9, not 0-8


;Restore the proxies
restore, expand_path('$tmp_dir') +'/proxies_pred.sav'
if not keyword_set(end_yd) and not keyword_set(update) then begin
	end_yd=end_yd_pred	; from 'proxies_pred.sav'
endif

nwv=n_elements(eve_wv)
fism_wv=eve_wv ; Set the FISM wavelength scale

; Run for each tag number stated in an_fit_coefs.pro
if keyword_set(tag_an) then begin
	best_tag=intarr(nwv)+tag_an-1
	tag=best_tag[0]
endif else begin
	;restore, '$fism_save/best_fit_coefs.sav'
	best_tag=indgen(n_elements(backup_ar))+1	; Now just process the each individual proxy
	tag=1
endelse
brk=0

wtag=where(best_tag eq tag)
remain_tag=best_tag
if wtag[0] ne -1 then remain_tag[wtag]=-1

while brk ne 1 do begin
def_tag=tag

; Restore Common Block variables
; Restore the fit coefs created by 'three_prox_sr_av.pro'
coef_fl= expand_path('$fism_save') +'/three_prox_fitcoefs_tag'+strtrim(tag,2)+'_noscav.sav'
restore, coef_fl

; Restore the array of daily model errors from 'concat_daily_error.pro'
; Only do this if running after the uncertainties are calculated
if not keyword_set(preerr) then restore, expand_path('$fism_save') + '/fism_daily_error.sav'


yrtmp=strmid(strtrim(start_yd,2),0,4)
ychk=yrtmp

st= !stime

tmp_yd=start_yd
while tmp_yd le end_yd do begin
	; Separate the year.
	yr = strtrim(string(tmp_yd/1000), 2)

	fism_pred1=fltarr(1,nwv)
	fism_err_sc1=fltarr(1,nwv)
	fism_err_sr1=fltarr(1,nwv)
	utc1=lonarr(1)
	day_ar1=lonarr(1)
	end_sod=0 
	for j=0l,end_sod do begin
		; Use the daily model and the sr coef for the no_scav coef
		if keyword_set(sr_coef) then begin
			fism_pred_tmp=pred_eve_daily(tmp_yd,43200, $
				tag=tag, /daily, /sr_coef) ; 
		endif else if keyword_set(sr_split) then begin
			fism_pred_tmp=pred_eve_daily(tmp_yd,43200, $
				tag=tag, /daily, /split_sr) ; 		
		endif else if keyword_set(scsr_split) then begin
			fism_pred_tmp=pred_eve_daily(tmp_yd,43200, $
				tag=tag, /daily, /scsr_split) ; 		
		endif else begin
			fism_pred_tmp=pred_eve_daily(tmp_yd,43200, $
				tag=tag, /daily) ; 		
		endelse
		fism_pred1=[fism_pred1,fism_pred_tmp]
		utc1=[utc1,43200] ; UTC is set at Mid-day as it is the 'Daily'
		day_ar1=[day_ar1,tmp_yd]
		;print, j, ' of', 1439
		;stop
	endfor
	;print, tmp_yd, ' of', end_yd
        ; Eliminate the first elements that are all zeros and ensure all values are >2.e-7
	nel=n_elements(utc1)
	fism_pred=reform(fism_pred1[1:nel-1,*])>2.e-7
	utc=utc1[1:nel-1]
	if not keyword_set(preerr) then begin
           fism_err_daily = reform(fism_sig[err_tag-1, *])
           fism_err_daily_abs = reform(fism_sig_abs[err_tag-1 , *])
	endif
        day_ar=day_ar1[1:nel-1]
        ; Make sure file path exists
        subDir = expand_path('$tmp_dir') + '/' + yr
        FILE_MKDIR, subDir
        svfl=expand_path('$tmp_dir') + '/' + yr + '/FISM_tmp_daily_'+strtrim(tmp_yd,2)+'_tag'+ $
		strtrim(tag,2)+'.sav'

	if keyword_set (preerr) then begin
           save, fism_pred, fism_wv, day_ar, utc, tag, file=svfl
        endif else begin
          save, fism_pred, fism_wv, day_ar, utc, tag, fism_err_daily, $
               fism_err_daily_abs, file=svfl
        endelse
	tmp_yd=get_next_yyyydoy(tmp_yd)
	;print, tmp_yd, ' tag: ', tag
endwhile

; Find if there is another tag to be processed
next_tag=where(remain_tag ne -1)
if next_tag[0] ne -1 then begin
	tag=remain_tag[next_tag[0]] 
	wtag=where(remain_tag eq tag)
	remain_tag[wtag]=-1
	print, 'Tag number begin processed, EUV: '+strtrim(tag,2)+'  ', !stime
endif else brk=1

endwhile	; End while loop for each tag

print, 'Start Time: ', st
print, 'End Time comp_fism_daily: ', !stime

;stop
end
