;
; NAME: concat_fism_daily.pro
;
; PURPOSE: to concat the optimal tag (determined by 'an_fit_coefs.pro' and 
;	calculated by 'comp_fism_1min_daily.pro') for each wavelength and each 
;	day to produce the best daily spectrum for each day
;
; HISTORY: 
;       VERSION 2_01
;       PCC    6/21    Updated for SDO/EVE

pro concat_fism_daily_xuv, start_yd=start_yd, end_yd=end_yd, update=update, ft_only=ft_only

    print, 'Running concat_fism_daily_xuv.pro', !stime

    if not keyword_set(start_yd) then start_yd=1947045

    if not keyword_set(end_yd) then begin
        restore, expand_path('$tmp_dir') + '/end_yd_pred.sav'
        end_yd=end_yd_pred-1
    endif

    if keyword_set(update) then begin
        ;tdy=get_current_yyyydoy()
        tdy=fix(get_current_yyyydoy(),type=3)
        end_yd=fix(get_prev_yyyydoy(tdy,1),type=3)
        start_yd=get_prev_yyyydoy(tdy,90) ; run for the past 60 days
    endif

     res_pth=expand_path('$daily_results') + '/xuv_daily/';(-aw)
    ;res_pth=expand_path('$fism_results') + '/'

    ; Restore the array of best tag for each wavelength
    ;restore, 'best_fit_coefs.sav'
    restore, '$fism_save/fism_version_file.sav'

    ; Get FISM version
    ;version = getenv('version')
    ;version='02_01' ; Can't get config to pars 'unable to allocate memory'
    restore, expand_path('$fism_save') + '/best_proxy_xuv.sav'
    nwv=n_elements(best_tag[0,*])
    tmp_yd=start_yd
    print, end_yd, 'concat xuv'
    while tmp_yd le end_yd do begin
      ;print, tmp_yd
        best_sp=fltarr(nwv)
        fism_error=fltarr(nwv)
        fism_abs_error=fltarr(nwv)
        tag=best_tag[0,0]
        brk=0
        wtag=where(best_tag[0,*] eq tag)
        remain_tag=best_tag[0,*]
        remain_tag[wtag]=-1

        ; Create a directory for the current year's results. 
        yd = strtrim(tmp_yd, 2)
        yd = strmid(yd, 0, 7)
        yr = strmid(yd, 0, 4)
        if not file_test(yr, /directory) then begin
            file_mkdir, res_pth + yr
        endif

        while brk ne 1 do begin
           if keyword_set(ft_only) then begin
              tag=2
              brk=1
           endif
            pred_fl='FISM_tmp_daily_'+yd+'_tag'+ $
                strtrim(tag,2)+'_xuv.sav'
                
            ; Seems to need yr sub dir as well (-aw)
            ; restore, expand_path('$tmp_dir')+'/'+pred_fl
            restore, expand_path('$tmp_dir') + '/' + yr + '/' + pred_fl
            predsp=reform(fism_pred)
            fism_error[wtag]=fism_err_daily[wtag]
            fism_abs_error[wtag]=fism_err_daily_abs[wtag]
            best_sp[wtag]=predsp[wtag]
            ; Find if there is another tag to be processed
            next_tag=where(remain_tag ne -1)
            if next_tag[0] ne -1 then begin
                tag=remain_tag[next_tag[0]] 
                wtag=where(remain_tag eq tag)
                remain_tag[wtag]=-1
            endif else brk=1
        endwhile
        svfl=res_pth+yr+'/FISM_daily_'+yd+'_xuv_'+version+'.sav'
        day_ar=tmp_yd
        utc=0
        fism_pred=best_sp
        save, fism_pred, fism_error, fism_abs_error, fism_wv, day_ar, utc, $
            file=svfl

		; TODO: I don't know of another way to get to the contents of
		; environment variables.
		if getenv('$gen_daily_ascii') eq 'true'  then begin
			; Generate ASCII output as well.
			out_file = res_pth + yr + '/FISM_daily_' + yd + '_xuv_' + version + $
				'.txt'
			create_ascii_output_daily, out_file, day_ar, fism_abs_error, $
				fism_error, fism_pred, fism_wv, utc
		endif

        tmp_yd=get_next_yyyydoy(tmp_yd)
                                ;print, tmp_yd, 'of', end_yd
    endwhile

print, 'End Time concat_fism_daily_xuv: ', !stime

end
