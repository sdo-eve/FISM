;
; NAME: process_fism_flare_Days
;
; PURPOSE: Process all the flare days of C5+ during the SDO mission
;
; HISTORY:
;       VERSION 2_01
;      
; 
;

pro process_fism_flare_days, new_start_yd=new_start_yd, debug=debug

print, 'Running process_fism_flare_days.pro', !stime

; Use to process All Flares Observed by EVE
restore, expand_path('$fism_save')+'/eve_flare_info.sav'
ndys=n_elements(yd)

if keyword_set(new_start_yd) then begin
   styd=where(yd ge new_start_yd)
endif else styd=0
for i=styd[0],ndys-1 do begin
        if keyword_set(debug) then print, yd[i]
	comp_fism_flare, start_yd=yd[i], end_yd=yd[i], /find_err
	;if i ne ndys-1 then begin
	if ndys-1 ne i then begin 
	 if isa( yd[i+1], /NUMBER) then while yd[i+1] eq yd[i] do i=i+1 ; skip for similar days with multiple flares
	endif
endfor

print, 'End Time process_fism_flare_days: ', !stime

end
	
