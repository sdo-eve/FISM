;
; NAME: an_fit_coefs.pro
;
; PURPOSE: to analyze the fit coefs (sc, sr, and total) to find the best 
;	proxy based on fit_sc=fit_sr(=fit)
;

pro an_fit_coefs_xuv, debug=debug, manual_sel=manual_sel

print, 'Running an_fit_coefs_xuv ', !stime
 

tag_ar=[1,2,3,4,5,6,7,8,9,10,11,12]	; tag numbers - see 'three_prox_noscsr.pro'
ntags=n_elements(tag_ar)

; Declare array sizes
save_pth = expand_path('$fism_save') 
restore, save_pth+'/sc_sr_fit_coefs_xuv_tag'+strtrim(tag_ar[0],2)+'.sav'
nwv=n_elements(fit_coefs[0,*])
slope_co=fltarr(nwv,5,ntags)	; fit_tot, fit_sc, fit_sr
for i=0,ntags-1 do begin
	; Restore the file created by 'three_prox_noscsr.pro'
	flnm=save_pth+'/sc_sr_fit_coefs_xuv_tag'+strtrim(tag_ar[i],2)+'.sav'
	restore, flnm
	
	; Save the slope coefs in the array
	slope_co[*,0,i]=fit_coefs[1,*]
	slope_co[*,1,i]=fit_coefs_sc[1,*]
	slope_co[*,2,i]=fit_coefs_sr[1,*]
	slope_co[*,3,i]=fit_coefs_sc[1,*]/fit_coefs_sr[1,*]
	slope_co[*,4,i]=fit_coefs[1,*]/fit_coefs_sr[1,*]
endfor

best_tag=intarr(nwv)
if keyword_set(manual_sel) then begin
   ; Loop through and have user enter the best proxy for each wavelength
   best_tag_tmp=0
   for j=0,nwv-1 do begin
	;print, 'Wavelength: '+strtrim(j+0.5,2)+'nm'
	print, 'P#  Total    SC      SR	   SC/SR    tot/SR'
	print, '___________________________________________'
	for k=0,ntags-1 do print, strtrim(tag_ar[k],2), $
		strtrim(reform(slope_co[j,*,k]),2) 
	read, best_tag_tmp, prompt='Enter the best proxy number (SC/SR~1+/-0.1): '
	best_tag[j]=best_tag_tmp
     endfor
endif else begin ; Just use the best proxy where SC/SR is closest to 1
   for j=0,nwv-1 do begin
      best_tag_tmp=min(abs(slope_co[j,3,*]-1),wmin)
      best_tag[j]=wmin+1 ; tags are from 1-12, not 0-11
      if best_tag[j] eq 9 then best_tag[j] = 1 ; Bad proxy
      if best_tag[j] eq 8 then best_tag[j] = 1 ; Bad proxy
      ;if best_tag[j] eq 2 then best_tag[j] = 1 ; Don't use F10.7 as primary as it bottoms out at solar min
      best_tag[j]=2 ; force best tag to be F107 everywhere, other proxies have issues that I don't understand yet
   endfor
endelse

if not keyword_set(debug) then save, best_tag, nwv, file=save_pth+'/best_fit_coefs_xuv.sav' $
                                     else stop

print, 'End Time an_fit_coefs_xuv: ', !stime

end
