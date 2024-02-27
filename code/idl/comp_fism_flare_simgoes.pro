;
;  NAME: comp_fism_flare_simgoes.pro
;
;  PURPOSE: to compute the FISM Flare estimated spectra using a
;  simulated GOES profile
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
;	PCC 5/12/05	Added the /three_sec keyword to use the GOES 3-sec
;			data when available (WARNING: Only can be run for 1 day!)
;	PCC 9/20/05	Updated to use the GOES 3sec data for all days
;	PCC 12/01/06	Updated for MacOSX
;	PCC 05/01/07	Updated to version *00_01.sav - Now using TIMED SEE Version 9 data
;
;       VERSION 2_01  
;       PCC 7/17/2012   Updated for SDO/EVE
;       PCC 7/23/2012   Added 'find_err' keyword to process data to
;       find uncertainties

pro comp_fism_flare_simgoes, start_yd=start_yd, end_yd=end_yd, sec_step=sec_step, $
	three_sec=three_sec, update=update, today=today, find_err=find_err

print, 'Running comp_fism_flare.pro ... ', !stime

if not keyword_set(start_yd) then start_yd=1982002
if not keyword_set(end_yd) then begin
	restore, expand_path('$fism_save')+'/end_yd_pred.sav'
	end_yd=end_yd_pred-1
endif
if keyword_set(today) then start_yd=end_yd
if keyword_set(update) then begin
	tdy=get_current_yyyydoy()
	start_yd=get_prev_yyyydoy(tdy,60) ; run for the past 60 days
endif

res_pth=expand_path('$fism_results')+'/daily_data/'
sv_pth=expand_path('$fism_results')+'/flare_data/'

common goes_data_com, goes_day, ychk, dychk, c_ip_c, sec_step_sh, $
	c_gp_c, pred_sp, clv_rat, clv_rat_ip, def_fl_loc, cent_cor_fact, $
	limb_cor_fact, clv_rat_lin, c_gp_c_lin, nwvs, med_gp_delay_time

if not keyword_set(sec_step) then sec_step=60
sec_step=fix(sec_step)
sec_step_sh=sec_step ; for the common block
	
; Restore Common Block variables
; Restore the IP and GP coefs
;restore, '$fism_save/p_ip_e_ip_3sec.sav'
restore, expand_path('$fism_save')+'/c_ip.sav'
restore, expand_path('$fism_save')+'/c_gp.sav'
if not keyword_set(find_err) then begin
   restore, expand_path('$fism_save')+'/fism_ip_flare_error.sav'
   restore, expand_path('$fism_save')+'/fism_gp_flare_error.sav'
   if sec_step ge 60 then begin ; sec step must be 60 or 10 for correct errors
	if keyword_set(three_sec) then begin
		fism_ip_flare_error=reform(fism_flare_error_3sec[1,*])
	endif else begin
		fism_ip_flare_error=reform(fism_flare_error_3sec[0,*])
	endelse
    endif else fism_ip_flare_error=reform(fism_flare_error_3sec[2,*])
endif
restore, expand_path('$fism_save')+'/clv_rat.sav'
restore, expand_path('$fism_save')+'/fism_version_file.sav'

yrtmp=strmid(strtrim(start_yd,2),0,4)
dytmp=strmid(strtrim(start_yd,2),4,3)
dychk=dytmp
ychk=yrtmp
nwvs=n_elements(wv)


def_fl_loc=0.0 ;noaa_flare_dat[0].locat

if not keyword_set(three_sec) then begin
	; Restore the GOES 1min data in proxy form (p.ip and p.gp)
	restore, expand_path('$goes_60sec_proxy')+'/p_ip_p_gp_'+strtrim(start_yd,2)+'_sim.sav'
        goes_day=p
        next_day=get_next_yyyydoy(start_yd)
        ; Get and add on next day to account for flare GP shifts
        ;   that may cross the day boundary
	restore, expand_path('$goes_60sec_proxy')+'/p_ip_p_gp_'+strtrim(next_day,2)+'_sim.sav'
	goes_day=[goes_day,p]
endif else begin
	; Restore the GOES 3sec data in proxy form (p.ip and p.gp)
	resfl= expand_path('$fism_data')+'/p_ip_p_gp_'+$
		strtrim(start_yd,2)+'_sim.sav'
	flinf=file_info(resfl)
	if flinf.exists eq 0 then begin
		resfl= expand_path('$goes_60sec_proxy')+'/p_ip_p_gp_'+strtrim(start_yd,2)+$
			'_sim.sav'
		if keyword_set(find_err) then begin
                   fism_ip_flare_error=fltarr(nwvs)
                endif else begin
                   fism_ip_flare_error=reform(fism_flare_error_3sec[0,*])
                endelse
	endif
	restore, resfl
	goes_day=p
	; Restore the GOES 3sec data in proxy form (p.ip and p.gp) for
        ;  the next day for GP shifts that may cross day boundary
        next_day=get_next_yyyydoy(start_yd)
	resfl= expand_path('$fism_data')+'/p_ip_p_gp_'+$
		strtrim(next_day,2)+'_sim.sav'
	flinf=file_info(resfl)
	if flinf.exists eq 0 then begin
		resfl= expand_path('$goes_60sec_proxy')+'/p_ip_p_gp_'+strtrim(next_day,2)+$
			'_sim.sav'
		if keyword_set(find_err) then begin
                   fism_ip_flare_error=fltarr(nwvs)
                endif else begin
                   fism_ip_flare_error=reform(fism_flare_error_3sec[0,*])
                endelse
	endif
	restore, resfl
	goes_day=[goes_day,p]
endelse

st= !stime
;print, st

; FISM flare model
tmp_yd=start_yd
while tmp_yd le end_yd do begin
	; Restore the daily model computed by 'comp_fism_daily.pro' and then
	;	'concat_fism_daily.pro'
	restore, res_pth+'/'+strmid(strtrim(tmp_yd,2),0,4)+'/'+'FISM_daily_'+strtrim(tmp_yd,2)+'_'+version+'.sav'
	pred_sp=fism_pred	; Enter in common array variable
	fism_flr_pred1=fltarr(1,nwvs)
	fism_pred1=fltarr(1,nwvs)
	grad_flare=fltarr(1,nwvs)
	imp_flare=fltarr(1,nwvs)
	fism_error1=fltarr(1,nwvs)
	utc1=lonarr(1)
	day_ar1=lonarr(1)
	for j=0l,86400-sec_step,sec_step do begin
		grad_inc=fltarr(nwvs)
		imp_inc=fltarr(nwvs)
		fism_flr_pred_tmp=pred_eve_flares(tmp_yd,j,grad_inc,imp_inc)
		fism_flr_pred1=[fism_flr_pred1,transpose(fism_flr_pred_tmp)]
		; Add flare model to daily model
		fism_pred1=[fism_pred1,transpose(fism_pred+fism_flr_pred_tmp)]
		grad_flare=[grad_flare,transpose(grad_inc)]
		imp_flare=[imp_flare,transpose(imp_inc)]
		utc1=[utc1,j]
		day_ar1=[day_ar1,tmp_yd]
		; Use FISM flare error
		if keyword_set(find_err) then begin
                   fism_error_tmp=fltarr(nwvs)
                endif else begin
                   fism_error_tmp=sqrt(fism_ip_flare_error^2.+fism_gp_flare_error_abs^2.)
                endelse
                fism_error1=[fism_error1,transpose(fism_error_tmp)]
		;if n_elements(where(fism_flr_pred_tmp gt 0.0)) gt 100 then stop
                print, j
        endfor
        
	;print, tmp_yd, ' of', end_yd, ' ', !stime
	; Eliminate the first elements that are all zeros
	nel=n_elements(utc1)
	fism_flr_pred=fism_flr_pred1[1:nel-1,*]
	grad_flare=fix(grad_flare[1:nel-1,*],type=4)
	imp_flare=fix(imp_flare[1:nel-1,*],type=4)
	fism_pred=fix(fism_pred1[1:nel-1,*],type=4)
	utc=utc1[1:nel-1]
	day_ar=day_ar1[1:nel-1]
	fism_error=fix(fism_error1[1:nel-1,*],type=4)
	fism_wv=wv
        ;stop

        ; Make sure file path exists
        yr=strmid(strtrim(tmp_yd,2),0,4)
        subDir = sv_pth + '/' + yr
        FILE_MKDIR, subDir
        

	if keyword_set(three_sec) then begin
		  svfl=sv_pth+'/'+strmid(strtrim(tmp_yd,2),0,4)+'/'+'FISM_'+strtrim(sec_step,2)+'sec_'+$
		  	strtrim(tmp_yd,2)+'_'+version+'.sav'	
	endif else begin
		svfl=sv_pth+'/'+strmid(strtrim(tmp_yd,2),0,4)+'/'+'FISM_'+strtrim(sec_step,2)+'sec_'+strtrim(tmp_yd,2)+$
			'_'+version+'_1mgoes.sav'
	endelse
	date=day_ar[0]
	fism_error=reform(fism_error[0,*])
	if (end_yd-start_yd) gt 1 then begin
	    save, fism_pred, fism_error, fism_wv, date, utc, file=svfl, /compress
	    
	endif else begin
	    save, fism_pred, fism_error, grad_flare, imp_flare, date, utc, $
	    	fism_wv, file=svfl, /compress
            print, svfl
	endelse
	
	no_goes_data:
	tmp_yd=get_next_yyyydoy(tmp_yd)

	; Check and update yearly, daily savesets if needed
	yd=strtrim(tmp_yd,2)
	dy=strmid(yd,4,3)
	yyyy=strmid(yd,0,4)	
	if yyyy ne ychk then begin ; Update yearly savesets, NOAA
		;print, 'Updating Yearly savesets...'
		if yyyy ge 1996 then begin
			restore, expand_path('$tmp_dir')+'/noaa_flr_data_'+$
				strtrim(yyyy,2)+'.sav'
		endif 
		ychk=yyyy
		;print, ychk, tmp_yd		
	endif
	if dy ne dychk and not keyword_set(three_sec) then begin ; Update the daily GOES saveset
		new_fl=expand_path('$goes_60sec_proxy')+'/p_ip_p_gp_'+$
				strtrim(tmp_yd,2)+'.sav'
                restore, new_fl
		goes_day=p
                next_day=get_next_yyyydoy(tmp_yd)
		new_fl=expand_path('$goes_60sec_proxy')+'/p_ip_p_gp_'+$
				strtrim(next_day,2)+'.sav'
                restore, new_fl
		goes_day=[goes_day,p]
		dychk=dy
		;print, dychk, tmp_yd
	endif	
	if dy ne dychk and keyword_set(three_sec) then begin ; Update the daily 
							     ;GOES 3sec saveset
		;stop
		new_fl='$fism_data/goes_3sec/p_ip_p_gp_'+$
			strtrim(tmp_yd,2)+'.sav'
		flinf=file_info(new_fl)
		if flinf.exists eq 0 then begin
			new_fl=expand_path('$goes_60sec_proxy')+'/p_ip_p_gp_'+$
				strtrim(tmp_yd,2)+'.sav'
			flinf=file_info(new_fl)
			if flinf.exists eq 0 then goto, no_goes_data
			if keyword_set(find_err) then begin
                           fism_ip_flare_error=fltarr(nwvs)
                        endif else begin
                           fism_ip_flare_error=reform(fism_flare_error_3sec[0,*])
                        endelse
		endif else begin	; Make sure using correct IP error	
			if keyword_set(find_err) then begin
                           fism_ip_flare_error=fltarr(nwvs)
                        endif else begin
                           fism_ip_flare_error=reform(fism_flare_error_3sec[1,*])
                        endelse
		endelse			
		restore, new_fl
		;plot, p.gp
		goes_day=p
                ; Get the next day for GP shifts that cross day boundary
                next_day=get_next_yyyydoy(tmp_yd)
                new_fl='$fism_data/goes_3sec/p_ip_p_gp_'+$
			strtrim(next_day,2)+'.sav'
		flinf=file_info(new_fl)
		if flinf.exists eq 0 then begin
			new_fl=expand_path('$goes_60sec_proxy')+'/p_ip_p_gp_'+$
				strtrim(next_day,2)+'.sav'
			flinf=file_info(new_fl)
			if flinf.exists eq 0 then goto, no_goes_data
			if keyword_set(find_err) then begin
                           fism_ip_flare_error=fltarr(nwvs)
                        endif else begin
                           fism_ip_flare_error=reform(fism_flare_error_3sec[0,*])
                        endelse
		endif else begin	; Make sure using correct IP error	
			if keyword_set(find_err) then begin
                           fism_ip_flare_error=fltarr(nwvs)
                        endif else begin
                           fism_ip_flare_error=reform(fism_flare_error_3sec[1,*])
                        endelse
		endelse			
		restore, new_fl
		;plot, p.gp
		goes_day=[goes_day,p]
		dychk=dy
		;stop
		;print, dychk, tmp_yd
	endif	
endwhile

;print, 'Start Time: ', st
;print, 'End Time: ', !stime

;stop
end
