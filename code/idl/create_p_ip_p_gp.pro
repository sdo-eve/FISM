;
; NAME: create_p_ip_p_gp.pro
;
; PURPOSE: to find the p_ip and p_gp for the GOES data in yearly savesets
;
; MODIFICATION HISTORY:
;	PCC	6/6/05	Program Creation
;	PCC	6/13/05	Limited p_ip to be >1e-8 to eliminate noise (see p.148)
;	PCC	6/15/05 Added the most recent recorded flare location
;	PCC	12/04/06 Updated for Mac OSX
;

pro create_p_ip_p_gp, yr=yr, update=update

print, 'Processsing create_p_ip_p_gp.pro', !stime

cur_yd=get_current_yyyydoy()
cur_yr=fix(cur_yd/1000.)
num_ind=cur_yr-1982+1
if not keyword_set(yr) then yr=indgen(num_ind)+1982
if keyword_set(update) then yr=cur_yr

nyr=n_elements(yr)

; Restore the GOES daily min saveset
restore, expand_path('$pre_gen_data_dir') + '/goes_daily_pred.sav'
tmp_flr_loc=0.0 ; Use 0.0 as default (center of the Sun)
for i=0,nyr-1 do begin
	st_yd=yr[i]*1000l+1
	if (yr[i] ne 1996 and yr[i] ne 2000 and yr[i] ne 2004 and yr[i] ne 2008 and yr[i] ne 2012 and yr[i] ne 2016 $
            and yr[i] ne 2020 and yr[i] ne 2022 and yr[i] ne 2024) then end_yd=st_yd+365 else end_yd=st_yd+366
	tmp_yd=st_yd
	restore, expand_path('$goes_proxy') + '/goes_1mdata_widx_' + $
		strtrim(yr[i],2)+'.sav'
	; (-aw)
	; if tmp_yd ge 1996000 then restore, expand_path('$tmp_dir') + $
    ;    'noaa_flr_data_'+strtrim(yr[i],2)+'.sav'
	if tmp_yd ge 1996000 then restore, expand_path('$tmp_dir') + '/' + $
        'noaa_flr_data_'+strtrim(yr[i],2)+'.sav'
        while tmp_yd le end_yd do begin
		wgoes_min=where(dy_ar eq tmp_yd)
		if wgoes_min[0] eq -1 then goes_min=1.e-8 else $
			goes_min=goes_daily_l[wgoes_min[0]]
		utc_to_gps, tmp_yd, 0, gst_gps
		utc_to_gps, tmp_yd+1, 0, gend_gps
		wgs_dy=where(goes.time ge gst_gps and goes.time lt gend_gps)
		if wgs_dy[0] ne -1 and n_elements(wgs_dy) gt 3 then begin
			ngs=n_elements(wgs_dy)
			ptmp={time:1ul, ip:1d, gp:1d, fl_loc:0.0}
			p=replicate(ptmp,ngs)
                        p.time=goes[wgs_dy].time
                        p_time_prevday=p.time ; update to use for next day if GOES data is missing
			p.gp=(goes[wgs_dy].long-goes_min)>0.0d
			; Add the flare location for each element
			; Find the average of the flare locations >0 to use as the
                                ; flare location for all flares that day
			if tmp_yd ge 1996000 then begin
				wnoaa=where(noaa_flare_dat.yyyydoy eq tmp_yd and $
					strlen(noaa_flare_dat.locat) eq 6)
			endif else wnoaa=[-1,-1]
			if wnoaa[0] eq -1 and tmp_yd ge 1996000 then begin
				p.fl_loc=tmp_flr_loc 
				;stop
			endif else if wnoaa[0] eq -1 and tmp_yd lt 1996000 then begin
				p.fl_loc=0.0
			endif else begin
				nchange=n_elements(wnoaa)
				chng_loc_st=gst_gps
				for a=0,nchange-1 do begin
					utc_to_gps, tmp_yd, noaa_flare_dat[wnoaa[a]].strt_time, chng_loc_end
					fill_ind=where(goes.time ge chng_loc_st and goes.time lt chng_loc_end)
					if fill_ind[0] eq -1 then goto, nofill else p[fill_ind].fl_loc=tmp_flr_loc
					flr_long_loc=fix(strmid(noaa_flare_dat[wnoaa[a]].locat,1,2),type=4)
                                	flr_lat_loc=fix(strmid(noaa_flare_dat[wnoaa[a]].locat,4,2),type=4)
                                	tmp_flr_loc=sqrt((flr_long_loc*flr_long_loc)+(flr_lat_loc*flr_lat_loc))
					chng_loc_st=chng_loc_end
					;print, tmp_flr_loc, flr_long_loc, flr_lat_loc
					nofill:
				endfor
				; Fill in the rest of the day
				fill_ind=where(p.time ge chng_loc_st and p.time lt gend_gps)
				if fill_ind[0] ne -1 then p[fill_ind].fl_loc=tmp_flr_loc
                                ; Fill in where nonexistant (0.0) flare
                                ; location data with last value "tmep_flr_loc" for day 
                                bd2=where(p.fl_loc le 0.0)
                                if bd2[0] ne -1 then p[bd2].fl_loc=tmp_flr_loc
			endelse

			; Find the derivative manually
			n_p=n_elements(p.gp)
			p[1:n_p-1].ip=((p[1:n_p-1].gp-p[0:n_p-2].gp)/(p[1:n_p-1].time-p[0:n_p-2].time))>0.
			p[0].ip=0
			; 6/14/05 Eliminate p_ip < 5e-10 
			bd=where(p.ip lt 5.e-10)
			p[bd].ip=0.0
			
			;print, 'Saving '+strtrim(yr[i],2)+'...'
			
                        ; ensure path exists  (-aw)
                        subDir = expand_path('$goes_60sec_proxy')
                        FILE_MKDIR, subDir

			save, p, file=expand_path('$goes_60sec_proxy') + '/p_ip_p_gp_'+strtrim(tmp_yd,2)+'.sav'

                endif else begin ; No GOES data for the day, so fill
                        ptmp={time:1ul, ip:1d, gp:1d, fl_loc:0.0}
			p=replicate(ptmp,1440)
                        for k=0,1339 do begin
                           utc_to_gps, tmp_yd, k*60, gpstmp, gpsleap=13
                           p[k].time=gpstmp ;
                        endfor
                        p.gp=0.0d
                        p.ip=0.0d

                        save, p, file=expand_path('$goes_60sec_proxy') + '/p_ip_p_gp_'+strtrim(tmp_yd,2)+'.sav'
                endelse
                
		tmp_yd=get_next_yyyydoy(tmp_yd)
		print, tmp_yd
	endwhile
endfor


print, 'End Time create_p_ip_p_gp: ', !stime

end
