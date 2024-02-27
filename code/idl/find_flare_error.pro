;
; NAME: find_flare_error
;
; PURPOSE: to find the FISM gradual phase error
;
; MODIFICATION HISTORY
;	PCC	8/16/05	Program Creation
;	PCC	12/04/06 Updated for Max OSX
;
;       Version 2_01
;       PCC     6/24/12  Updated for SDO/EVE


pro find_flare_error

print, 'Running find_flare_error.pro', !stime

restore, expand_path('$fism_save')+'/fism_version_file.sav'

; Use to process All Flares Observed by EVE
restore, expand_path('$fism_save')+'/eve_flare_info.sav'
ndys=n_elements(yd)

; Restore an initial FISM saveset to get array dimensions
fism_pth=expand_path('$fism_results')+'/flare_data/'
restore, fism_pth + '/euv/'+strmid(strtrim(yd[0],2),0,4)+'/'+'FISM_60sec_'+strtrim(yd[0],2)+'_'+version+'.sav'
nwvs=n_elements(fism_wv)

tot_diff_sq=fltarr(nwvs)
fism_flare_error=fltarr(nwvs)
fism_flare_error_abs=fltarr(nwvs)

; Restore the EVE daily data
a=file_search(expand_path('$fism_data')+'/lasp/eve/latest_EVE_L3_merged.ncdf')
read_netcdf, a[0], eve, s, a

ans=''
for j=0,nwvs-1 do begin ; process each wv separately    
    eve_data_fismtimes=fltarr(1)
    fism_data_fismtimes=fltarr(1)
    eve_prec_fismtimes=fltarr(1)

    for i=0,ndys-1 do begin
      ;check if he file exists 
      
       if yd[i] gt 2012076 then goto, bd_dys ; change date once full processing is re-run
	; Restore the FISM saveset w/flares for the given day
        ; fism_pred[sod,wv], utc[sod]
        yr_string=strmid(strtrim(yd[i],2),0,4)
        restore, fism_pth+'/euv/'+yr_string+'/'+'FISM_60sec_'+strtrim(yd[i],2)+'_'+version+'.sav'
        nutc=n_elements(utc)
        
        ; Get the EVE daily data for the day and the next day 
        gd_eve_daily_day=where(eve.mergeddata.yyyydoy eq yd[i])
        eve_daily_data=[[reform(eve.mergeddata[gd_eve_daily_day].sp_irradiance)],[reform(eve.mergeddata[gd_eve_daily_day+1].sp_irradiance)]]

	; Restore the EVE data for that day/flare	
	; EVE daily (1A bins)
        tmp_pth=expand_path('$tmp_dir')
        restore, tmp_pth+'/eve_sc_av.sav'
	; EVE 10sec data - from 'find_ip_gp_powerfunct_eve.pro'
	       fl_ex=file_test(expand_path('$tmp_dir')+'/'+yr_string+'/'+'eve_flr_data_'+strtrim(yd[i],2)+'.sav')

	       if fl_ex eq 0 then goto, miss_eve_data
         restore, expand_path('$tmp_dir')+'/'+yr_string+'/'+'eve_flr_data_'+strtrim(yd[i],2)+'.sav'
        
	; Get the start and stop times from the stored EVE 10sec data above
	flr_start_time=eve_flr_sod[0]
        nsp_eveflr=n_elements(eve_flr_sod)
	flr_stop_time=eve_flr_sod[nsp_eveflr-1]

        ; Find the EVE data 1-minute averages that aligns with FISM
        fism_st_time=where(utc ge flr_start_time)
        fism_end_time=where(utc ge flr_stop_time)
        if flr_stop_time lt flr_start_time then fism_end_time[0]=n_elements(utc)-1 ; don't cross day boundary
        for k=fism_st_time[0],fism_end_time[0]-1 do begin
           ;if utc[k] lt 86400 then begin
              gd_eve_min=where(eve_flr_sod gt utc[k]-30 and eve_flr_sod gt utc[k]+30 and eve_flr_data[j,*] gt 0.0)
              if gd_eve_min[0] ne -1 then begin
                 eve_av=mean(eve_flr_data[j,gd_eve_min])-eve_daily_data[j,0]; only flare component
                 eve_prec_av=mean(eve_flr_prec[j,gd_eve_min])*eve_av ; prec is in relative var (e.g. 0.04 for 4%)
                 eve_data_fismtimes=[eve_data_fismtimes,eve_av]
                 eve_prec_fismtimes=[eve_prec_fismtimes,eve_prec_av]
                 fism_data_fismtimes=[fism_data_fismtimes,imp_flare[k,j]+grad_flare[k,j]] ; only flare component
              endif
           ;endif else begin ; won't actaully enter this yet until find out how to deal with flares that cross day boundary
           ;   gd_eve_min=where(eve_flr_sod-86400 gt utc[k]-30 and eve_flr_sod gt utc[k]+30)
           ;   if gd_eve_min[0] ne -1 then begin
           ;      eve_av=mean(eve_flr_data[j,gd_eve_min])-eve_daily_data[j,0]
           ;      eve_data_fismtimes=[eve_data_fismtimes,eve_av]
           ;      fism_data_fismtimes=[fism_data_fismtimes,fism_pred[k,j]]
           ;   endif             
           ;endelse
         bd_dys:
        endfor
        miss_eve_data:
    endfor

;    tot_diff_sq[j]=((fism_data_fismtimes-eve_data_fismtimes)/eve_data_fismtimes)^2.
    npnts=n_elements(fism_data_fismtimes)
    tot_diff_sq[j]=total((fism_data_fismtimes[1:npnts-1]-eve_data_fismtimes[1:npnts-1])^2d) ; keep error absolute
    fism_flare_error[j]=sqrt(tot_diff_sq[j]/(npnts-2)) ; -1, but need -2 due to first element being a placeholder
    ; Find the absolute FISM error by adding the EVE median error in quadrature
    fism_flare_error_abs[j]=sqrt(fism_flare_error[j]^2.+median(eve_prec_fismtimes)^2.)

endfor

;stop
print, 'Saving fism_flare_error.sav'
save, fism_flare_error, fism_flare_error_abs, $
	file=expand_path('$fism_save')+'/fism_flare_error.sav'

print, 'End time find_flare_error: ', !stime
end
	
