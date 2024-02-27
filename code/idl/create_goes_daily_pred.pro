;
;  NAME: create_goes_daily_pred.pro
;
;  PURPOSE:  to create a daily goes value as the 3rd lowest value for the day
;
;  MODIFICATION HISTORY:
;	PCC	7/25/04		Program Creation - 'create_goes_daily.pro'
;	PCC	11/8/04		Lowered the flare index threshold to eliminate
;				more flares as they were still contributing
;				significantly to the solar cycle
;	PCC	11/17/04	now uses only the 3rd lowest value for the day
;				as the daily value
;				new name: 'create_goes_daily_v2.pro'
;	PCC	12/01/06	Updated for MacOSX
;				new name: 'create_goes_daily_pred.pro'
;

pro create_goes_daily_pred, update=update

print, 'Running create_goes_daily_pred.pro', !stime

end_yyyydoy = get_current_yyyydoy()

; Is the 'trip' to indicate whether this is starting from scratch (0,
; initial run)?
if keyword_set(update) then begin
	restore, expand_path('$fism_save') + '/goes_daily_pred.sav'
	trip = 1
	ndys_old = n_elements(dy_ar)
	lst_dy = dy_ar[ndys_old - 1]
	start_yyyydoy = get_next_yyyydoy(lst_dy)
endif else begin
	trip = 0
	start_yyyydoy = 1982001
endelse

strtydoy = yd2ymd(start_yyyydoy)
styr = fix(strmid(strtrim(strtydoy[0],2), 0, 4), type=3)
endydoy = yd2ymd(end_yyyydoy)
endyr = fix(strmid(strtrim(endydoy[0],2), 0, 4), type=3)
nyrs = endyr - styr + 1
yr_arr = fix(findgen(nyrs) + styr)

; Restore the GOES data
goes = concat_goes_yrs(yr_arr)

gps_to_utc, goes.time, 13, goes_year, goes_doy, goes_utc, goes_month, $
    goes_day, hour, min, sec
goes_yd = goes_year * 1000 + goes_doy

tmp_yd = start_yyyydoy
; bd_cnt = bad count?
bd_cnt = 0
; Doesn't seem to be anything to jump to this label.
;gd_goes_dy:
while tmp_yd ne end_yyyydoy+1 do begin
	if trip eq 0 then begin
		dy_ind_l = where(goes_yd eq tmp_yd)
		if dy_ind_l[0] ne -1 then begin
			sort_ind = sort(goes[dy_ind_l].long)
			acend_goes_dy = goes[dy_ind_l[sort_ind]].long
			goes_daily_l = acend_goes_dy[3]
		endif else begin
			goes_daily_l = [1.0e-7]
			bd_cnt = bd_cnt + 1
		endelse
		dy_ar = tmp_yd
        ; First value has been calculated, so set 'trip'.
		trip = 1
	endif else begin
		dy_ind_l = where(goes_yd eq tmp_yd)
		;print, dy_ind_l
		if dy_ind_l[0] ne -1 and n_elements(dy_ind_l) gt 4 then begin
			sort_ind = sort(goes[dy_ind_l].long)
			acend_goes_dy = goes[dy_ind_l[sort_ind]].long
			goes_daily_l = [goes_daily_l, acend_goes_dy[3]]
		endif else begin
			goes_daily_l = [goes_daily_l, 1.0e-7]
			bd_cnt = bd_cnt + 1
		endelse
		dy_ar = [dy_ar, tmp_yd]
	endelse
	;print, tmp_yd
	tmp_yd = get_next_yyyydoy(tmp_yd)
endwhile

flnm = expand_path('$fism_save') + '/goes_daily_pred.sav'
print, 'Saving ', flnm
save, goes_daily_l, dy_ar, file=flnm

print, 'End Time create_goes_daily_pred: ', !stime

;stop

end		
