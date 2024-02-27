; 
; NAME: find_meas_errors.pro
;
; PURPOSE: to find the mean measurement errors to add in quadature to the
;	FISM errors to get an absolute FISM error
;
; HISTORY:
;       'find_see_sorce_mean_errors.pro'
;       VERSION 2_01
;       PCC     6/20/12   Updated for SDO EVE 'find_meas_errors.pro'
;       PCC     1/11/17   Updated for SORCE XPS and SOLSTICE
;      
;

pro find_meas_errors

print, 'Running find_meas_errors.pro', !stime

data_dir=expand_path('$fism_data') 
save_dir=expand_path('$fism_save') 

; Find the SEE L3 mean errors
;l3_ts=read_latest_merged('see','l3',status)
;;l3mer_flnm=findfile(data_dir+'/SEE/*_L3_*.ncdf')
;;read_netcdf, l3mer_flnm[0], l3_ts
;;nwv=n_elements(l3_ts.sp_err_tot[*,0])
;;see_l3_err=fltarr(nwv)	; Median SEE error for mission
;;for k=0,nwv-1 do see_l3_err[k]=mean(l3_ts.sp_err_tot[k,*])
;;save, see_l3_err, file='$fism_save/see_l3_mean_err.sav'

; Find the SEE L3A mean errors
;l3a_ts=read_latest_merged('see','l3a',status)
;;l3amer_flnm=findfile(data_dir+'/SEE/*_L3A_*.ncdf')
;;read_netcdf, l3amer_flnm[0], l3a_ts

;;nwv=n_elements(l3a_ts.sp_err_tot[*,0])
;;see_l3a_err=fltarr(nwv)	; Median SEE error for mission
;;for k=0,nwv-1 do see_l3a_err[k]=mean(l3a_ts.sp_err_tot[k,*])
;;save, see_l3a_err, file=save_dir+'/see_l3a_mean_err.sav'

; Find the EVE L3 1a mean errors
l3mer_flnm=findfile(data_dir+'/lasp/eve/latest_EVE_L3_merged_1a.ncdf')
read_netcdf, l3mer_flnm[0], eve, s, a
nwv=n_elements(eve.spectrummeta.wavelength)
eve_l3_stdev=fltarr(nwv)	; Median eve error for mission
for k=0,nwv-1 do begin
   gd=where(eve.mergeddata.sp_stdev[k,*] gt 0.0)
   eve_l3_stdev[k]=mean(eve.mergeddata.sp_stdev[k,gd])
endfor
; EVE error is in standard deviation, so need to divide by the mean
; spectrum
eve_l3_mean_sp=fltarr(nwv)	; Median eve spectrum for mission
for k=0,nwv-1 do eve_l3_mean_sp[k]=mean(eve.mergeddata.sp_irradiance[k,gd])
eve_l3_err=(eve_l3_stdev/eve_l3_mean_sp) ; (stdev/mean_sp)*100., in frac
save, eve_l3_err, file=save_dir+'/eve_l3_mean_err.sav'

; Get the SORCE XPS mean errors
read_netcdf, data_dir+'/lasp/sorce/sorce_xps/sorce_xps_L4_c24h_r0.1nm_latest.ncdf', xps
sorce_xps_err=fltarr(400)	; Median XPS error for mission
sorce_xps_err[0:399]=median(xps.err_abs) 
save, sorce_xps_err, file=save_dir+'/sorce_xps_mean_err.sav'

; Get the SORCE SOLSTICE mean errors
; Get the Smoothed SORCE SOLSTICE data
src_pth=getenv('fism_data')
read_netcdf, src_pth+'/lasp/sorce/solstice_daily/SORCE_SOLSTICE_L3_HR_V15_2003.nc', src_l3 ; start with 2003
src_l3_uncertainty_tmp=transpose(src_l3.irradiance_uncertainty/src_l3.irradiance) ; rel uncertainty
for k=2004,2017 do begin      ; Concat new years data
   read_netcdf, src_pth+'/lasp/sorce/solstice_daily/SORCE_SOLSTICE_L3_HR_V15_'+strtrim(k,2)+'.nc', src_l3 
   src_l3_uncertainty_tmp=[src_l3_uncertainty_tmp,transpose(src_l3.irradiance_uncertainty/src_l3.irradiance)]
   ;src_l3_irradiance=[src_l3_irradiance,transpose(src_l3.irradiance)]
endfor
nwv_ss=n_elements(src_l3_uncertainty_tmp[0,*])
src_l3_uncertainty=fltarr(nwv_ss)
for m=0,nwv_ss-1 do begin
   src_l3_uncertainty[m]=mean(src_l3_uncertainty_tmp[*,m])
endfor
save, src_l3_uncertainty, file=save_dir+'/sorce_sol_mean_err.sav'

print, 'End Time find_meas_errors: ', !stime

end
