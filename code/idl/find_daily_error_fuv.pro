;
; NAME: find daily_error.pro
;
; PURPOSE: to find the daily error for FISM FUV 
;

pro find_daily_error_fuv, plots=plots

print, 'Running find_daily_error_fuv.pro', !stime

n_proxies=3

; Restore SORCE data
; Get the Smoothed SORCE SOLSTICE data
src_pth=getenv('fism_data')
read_netcdf, src_pth+'/lasp/sorce/solstice_daily/SORCE_SOLSTICE_L3_HR_V15_2003.nc', src_l3 ; start with 2003
src_l3_nominal_date_jd=src_l3.nominal_date_jd
;src_l3_nominal_date_ymd=src_l3.nominal_date_yyyymmdd
src_l3_standard_wavelengths=src_l3.standard_wavelengths
src_l3_irradiance=transpose(src_l3.irradiance)
for k=2004,2017 do begin      ; Concat new years data
   read_netcdf, src_pth+'/lasp/sorce/solstice_daily/SORCE_SOLSTICE_L3_HR_V15_'+strtrim(k,2)+'.nc', src_l3 
   src_l3_nominal_date_jd=[src_l3_nominal_date_jd,src_l3.nominal_date_jd]
   ;src_l3_nominal_date_ymd=[src_l3_nominal_date_ymd,src_l3.nominal_date_yyyymmdd]
   ;src_l3_standard_wavelengths=[src_l3_standard_wavelengths,src_l3.standard_wavelengths]
   src_l3_irradiance=[src_l3_irradiance,transpose(src_l3.irradiance)]
endfor
src_l3_irradiance=transpose(src_l3_irradiance)
src_l3_ydoy=jd2yd(src_l3_nominal_date_jd)
src_l3_ydoy=fix(src_l3_ydoy,type=3) ; eliminate the .5
st_yd=src_l3_ydoy[0]
nsrc=n_elements(src_l3_ydoy)
end_yd=src_l3_ydoy[nsrc-1]

; Restore the SORCE SOLSTICE mean error for each wavelength
;	created by find_meas_errors.pro
save_path=expand_path('$fism_save') 
restore, save_path+'/sorce_sol_mean_err.sav'

; Find FISM errors for FUV
ndys=nsrc
nwvs=n_elements(src_l3_standard_wavelengths)
tot_diff_sq=dblarr(n_proxies,nwvs)
fism_sig_fuv=dblarr(n_proxies,nwvs)
tot_fism_fuv=fltarr(ndys,nwvs,n_proxies)
tot_sol=fltarr(ndys,nwvs)
;print, n_proxies
for i=0,n_proxies-1 do begin 
	ndys_cnt=fltarr(nwvs) ; count the bad data to subtract for each wavelength 
	for j=1,ndys-1 do begin 
           	; Separate the year.
                yr_st = strtrim(string(src_l3_ydoy[j]/1000), 2)
                res_pth=expand_path('$tmp_dir')+'/'+yr_st+'/'

		res_fl=res_pth+'FISM_tmp_daily_'+strtrim(src_l3_ydoy[j],2)+$
			'_tag'+strtrim(i,2)+'_fuv.sav'
		restore, res_fl
		gd=where(src_l3_irradiance[*,j] gt 0)
                if gd[0] eq -1 then goto, skp_sol
		tot_diff_sq[i,gd]=tot_diff_sq[i,gd]+((src_l3_irradiance[gd,j]-$
			fism_pred_fuv[gd])/src_l3_irradiance[gd,j])^2.
		tot_fism_fuv[j,gd,i]=fism_pred_fuv[gd]
		tot_sol[j,gd]=src_l3_irradiance[gd,j]
		ndys_cnt[gd]=ndys_cnt[gd]+1.
                skp_sol:
		;if j gt 40 and keyword_set(plots) then plot, sqrt(tot_diff_sq[i,*]/(ndys_cnt-2))
		;print, i, j, ' of ', ndys
		;wait, 0.02
	endfor
	fism_sig_fuv[i,*]=sqrt(tot_diff_sq[i,*]/(ndys_cnt))
	;print, i
	;if keywordstop
endfor

fism_arr=tot_fism_fuv
sol_arr=tot_sol

fism_sig_abs_temp=fltarr(n_proxies,nwvs)
for j=0,n_proxies-1 do fism_sig_abs_temp[j,*]=sqrt(reform(fism_sig_fuv[j,*])^2.+src_l3_uncertainty^2.)
fism_sig_abs_fuv=fism_sig_abs_temp

corr_ar_fuv=fltarr(n_proxies,nwvs)
for i=0,n_proxies-1 do begin
	for j=0,nwvs-1 do corr_ar_fuv[i,j]=correlate(sol_arr[*,j],fism_arr[*,j,i])
endfor


; Find what is the primary proxy for each wavelength based on the
; smallest 
best_primary_tag_fuv=intarr(nwvs)
for k=0,nwvs-1 do begin
   min_sig=min(fism_sig_fuv[*,k],wmin)
   best_primary_tag_fuv[k]=wmin+1 ; tags from 1-3
endfor
sol_wv=src_l3_standard_wavelengths
print, 'Saving best_primary_proxy_fuv.sav'
save, best_primary_tag_fuv, sol_wv, file=expand_path('$fism_save')+'/best_primary_proxy_fuv.sav'

print, 'Saving fism_daily_error_tmp_fuv.sav'
save, fism_sig_fuv, fism_sig_abs_fuv, file=save_path+'/fism_daily_error_fuv.sav'

if keyword_set(plots) then begin
	
	ans=''
	cc=independent_color()
	plot, sol_wv, fism_sig_fuv[0,*]*100., yr=[0,100], psym=10, $
	xtitle='Wavelength (nm)', ytitle='Standard Deviation (%)',$
	charsize=2.0
	oplot, sol_wv, fism_sig_fuv[1,*]*100., color=cc.red, psym=10
	oplot, sol_wv, fism_sig_fuv[2,*]*100., color=cc.orange, psym=10
	xyouts, 80, 75, 'Black: Lya', charsize=1.5
	xyouts, 80, 70, 'Red: MgII', charsize=1.5, color=cc.red
	xyouts, 80, 65, 'Orange: F10.7', charsize=1.5, color=cc.orange

	read, ans, prompt='Correlation Plot? '
	
	plot, sol_wv, corr_ar_fuv[0,*], psym=10
	oplot, sol_wv, corr_ar_fuv[1,*], psym=10,color=cc.red
	oplot, sol_wv, corr_ar_fuv[2,*], psym=10,color=cc.orange
	xyouts, 80, 0.65, 'Black: MgII', charsize=1.5
	xyouts, 80, 0.6, 'Red: F10.7', charsize=1.5, color=cc.red
	xyouts, 80, 0.55, 'Orange: GOES', charsize=1.5, color=cc.orange
	
	read, ans, prompt='End Program? '
endif	

print, 'End Time find_daily_error_fuv: ', !stime

end
