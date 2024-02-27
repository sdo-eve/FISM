;
; NAME: create_p_ip_p_gp.pro
;
; PURPOSE: to find the p_ip and p_gp for the GOES data in yearly savesets
;
; MODIFICATION HISTORY:
;	PCC	6/6/05	Program Creation
;	PCC	6/13/05	Limited p_ip to be >1e-8 to eliminate noise (see p.148)
;	PCC	6/15/05 Added the most recent recorded flare location
;	PCC	12/01/06	Updated for Mac OSX
;

pro create_p_ip_p_gp_3sec, yr=yr, update=update

print, 'Processsing create_p_ip_p_gp_3sec.pro', !stime

cur_yd=get_current_yyyydoy()
cur_yr=fix(cur_yd/1000.)
num_ind=cur_yr-1996+1
if not keyword_set(yr) then yr=indgen(num_ind)+1996
if keyword_set(update) then yr=cur_yr

nyr=n_elements(yr)

; Restore the GOES daily min saveset
restore, expand_path('$pre_gen_data_dir') + '/goes_daily_pred.sav'
tmp_flr_loc=0.0 ; Use 0 as default (center of Sun)
for i=0,nyr-1 do begin
	st_yd=yr[i]*1000l+1
	if (yr[i] ne 1996 and yr[i] ne 2000 and yr[i] ne 2004 and yr[i] ne 2008 and yr[i] ne 2012 and yr[i] ne 2016) $
            then end_yd=st_yd+365 else end_yd=st_yd+366
	tmp_yd=st_yd
	;restore, '$fism_data/goes/goes_1mdata_widx_'+$
	;	strtrim(yr[i],2)+'.sav'
	restore, expand_path('$tmp_dir') + '/noaa_flr_data_' + $
        strtrim(yr[i],2)+'.sav'
  
	while tmp_yd le end_yd do begin
	  ;print, string(tmp_yd) + '/' + string(end_yd)
		; Get the GOES 3sec daily file
		if tmp_yd eq 2003308 then goto, nofl ; 2003308 3sec file is corrupt
		g3sec_fl=expand_path('$goes_3sec_proxy') + '/goes_3sec_'+strtrim(tmp_yd,2)+'.sav'
		;print, g3sec_fl
		flinf=file_info(g3sec_fl)
		if flinf.exists eq 0 then goto, nofl
		restore, g3sec_fl
		ngs=n_elements(sod)
		ptmp={time:1ul, ip:1d, gp:1d, fl_loc:0.0}
		p=replicate(ptmp,ngs)
		yd_ar=replicate(yd,ngs)
		utc_to_gps, yd_ar, sod, goesgps
		p.time=goesgps
		wgoes_min=where(dy_ar eq tmp_yd)
		if wgoes_min[0] eq -1 then goes_min=5.e-10 else $
			goes_min=goes_daily_l[wgoes_min[0]]

		utc_to_gps, tmp_yd, 0, gst_gps
		utc_to_gps, tmp_yd+1, 0, gend_gps
		p.gp=goes_long-goes_min
		; Add the flare location for each element
		; Find the average of the flare locations >0 to use as the flare location 
		;	for all flares that day
		;stop
		wnoaa=where(noaa_flare_dat.yyyydoy eq tmp_yd and $
			strlen(noaa_flare_dat.locat) eq 6)
		;stop
		if wnoaa[0] eq -1 then begin
			p.fl_loc=tmp_flr_loc 
			;stop
		endif else begin
			nchange=n_elements(wnoaa)
			chng_loc_st=gst_gps
			for a=0,nchange-1 do begin
				utc_to_gps, tmp_yd, noaa_flare_dat[wnoaa[a]].strt_time, chng_loc_end
				fill_ind=where(p.time ge chng_loc_st and p.time lt chng_loc_end)
				if fill_ind[0] eq -1 then goto, nofill else p[fill_ind].fl_loc=tmp_flr_loc
				flr_long_loc=fix(strmid(noaa_flare_dat[wnoaa[a]].locat,1,2),type=4)
                                flr_lat_loc=fix(strmid(noaa_flare_dat[wnoaa[a]].locat,4,2),type=4)
                                tmp_flr_loc=sqrt((flr_long_loc*flr_long_loc)+(flr_lat_loc*flr_lat_loc))
				chng_loc_st=chng_loc_end
				nofill:
                        endfor
                        ;print, tmp_flr_loc, flr_long_loc, flr_lat_loc    
			; Fill in the rest of the day
			fill_ind=where(p.time ge chng_loc_st and p.time lt gend_gps)
			if fill_ind[0] ne -1 then p[fill_ind].fl_loc=tmp_flr_loc
			;stop
		endelse

		; Smooth the goes 3sec data by one on each side to eliminate noise
		;	This will only be used for the impulsive phase - still use
		;	orignial, non-smoothed data for GP
		p_gp_smth=smooth(p.gp,3,/edge, /nan)
		
		; Find the derivative manually
		n_p=n_elements(p.gp)
		p[1:n_p-1].ip=((p_gp_smth[1:n_p-1]-p_gp_smth[0:n_p-2])/(p[1:n_p-1].time-p[0:n_p-2].time))>0.
		p[0].ip=0
		; 6/14/05 Eliminate p_ip < 5e-10 
		bd=where(p.ip lt 5.e-10)
		p[bd].ip=0.0
		
		;print, 'Saving '+strtrim(yr[i],2)+'...'
			
        ; ensure path exists  (-aw)
        subDir = expand_path('$goes_3sec_proxy')
        ;print, subDir
        FILE_MKDIR, subDir

		save, p, file=expand_path('$goes_3sec_proxy') + '/p_ip_p_gp_'+$
			strtrim(tmp_yd,2)+'.sav'

		nofl:

		tmp_yd=get_next_yyyydoy(tmp_yd)
		;print, tmp_yd
	endwhile
endfor


end
