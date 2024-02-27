pro prgev_to_sav

save_path=expand_path('$fism_save')

;month	day	year	st_hr	st_min	peak_hr	peak_min	end_hr	end_min	mag	n_s	lat	e_w	long	reg
flr_data=read_ascii(save_path+'/flares_SDO_C5plus.csv',delimiter=',', record_start=1)

; convert to yyyydoy
flr_yr=fix(reform(flr_data.field01[2,*]))
flr_mn=fix(reform(flr_data.field01[0,*]))
flr_dy=fix(reform(flr_data.field01[1,*]))
goes_hr_start=fix(reform(flr_data.field01[3,*]))
goes_min_start=fix(reform(flr_data.field01[4,*]))
goes_hr_peak=fix(reform(flr_data.field01[5,*]))
goes_min_peak=fix(reform(flr_data.field01[6,*]))
goes_hr_end=fix(reform(flr_data.field01[7,*]))
goes_min_end=fix(reform(flr_data.field01[8,*]))
ymd_to_yd, flr_yr, flr_mn, flr_dy, yd


; Determine the location
 ;1-center,2-mid,3-limb,0-NA
; 1:0-40 deg, 2:40-70 deg, 3:70-90 deg
cl_ang=reform(sqrt(flr_data.field01[12,*]*flr_data.field01[12,*]+flr_data.field01[14,*]*flr_data.field01[14,*]))
clv=intarr(n_elements(cl_ang))
for i=0,n_elements(cl_ang)-1 do begin
   if cl_ang[i] gt 0 and cl_ang[i] lt 40 then clv[i]=1 ; 'gt 0' to make sure to not use ones that aren't known
   if cl_ang[i] ge 40 and cl_ang[i] lt 70 then clv[i]=2
   if cl_ang[i] ge 70 then clv[i]=3
endfor

print, 'Saving eve_flare_info.sav'
save, goes_hr_start, goes_min_start, goes_hr_end, goes_min_end, yd, clv, cl_ang, $
      goes_min_peak, goes_hr_peak, file=save_path+'/eve_flare_info.sav'

end
