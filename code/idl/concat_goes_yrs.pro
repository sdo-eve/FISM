;
;  NAME: concat_goes_yrs.pro
;
;  PURPOSE: to combine multiple years of the GOES 1m data into a single structure
;
;  CALL:
;	goes=concat_goes_years(yr_arr)
;  		yr_arr: an array of the years to combine, from 1999-current
;		goes: output structure containing all goes data
;
;  MODIFICATION HISTORY:
;	PCC   2/15/04   Creation
;	PCC   12/01/06	Updated for MaxOSX
;
;       VERSION 2_01
;       PCC   6/21/12   Updated for SDO/EVE
;+

function concat_goes_yrs, yr_arr

n_yr=n_elements(yr_arr)
tm=0ul
shrt=0.0d
lng=0.0d
st=0
flr_lng=0.0d
flr_shrt=0.0d
for i=0,n_yr-1 do begin
	restore, ('$fism_data') + '/lasp/goes_xrs/goes_1mdata_widx_' + $
		strtrim(yr_arr[i],2)+'.sav'
	tm=[tm,goes.time]
	shrt=[shrt,goes.short]
	lng=[lng,goes.long]
	st=[st,goes.sat]
	flr_lng=[flr_lng,goes.flare_idx_long]
	flr_shrt=[flr_shrt,goes.flare_idx_short]
endfor
nel=n_elements(tm)

goes_tmp={time:0ul,$
	short:0.0d,$
	long:0.0d,$
	sat:0,$
	flare_idx_long:0.0d,$
	flare_idx_short:0.0d}

goes=replicate(goes_tmp,nel-1)

goes.time=tm[1:nel-1]
goes.short=shrt[1:nel-1]
goes.long=lng[1:nel-1]
goes.sat=st[1:nel-1]
goes.flare_idx_long=flr_lng[1:nel-1]
goes.flare_idx_short=flr_shrt[1:nel-1]

return, goes
end
