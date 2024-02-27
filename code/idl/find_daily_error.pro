;
; NAME: find daily_error.pro
;
; PURPOSE: to find the daily error for FISM
;

pro find_daily_error, plots=plots

print, 'Running find_daily_error.pro', !stime

n_proxies=12

; Restore EVE data
data_path=expand_path('$fism_data') 
l3mer_eve_flnm=findfile(data_path+'/lasp/eve/latest_EVE_L3_merged_1a.ncdf')
read_netcdf, l3mer_eve_flnm[0], eve, s, a

; Restore SEE L3 data
;;l3mer_flnm=findfile(data_path+'/SEE/*_L3_*.ncdf')
;;read_netcdf, l3mer_flnm[0], l3_ts

; Restore the SEE and EVE L3 mean error for each wavelength
;	created by find_meas_errors.pro
save_path=expand_path('$fism_save') 
;;restore, save_path+'/see_l3_mean_err.sav'
restore, save_path+'/eve_l3_mean_err.sav'



; Find EVE errors for EUV
ndys=1450; n_elements(eve.mergeddata.yyyydoy)  ; Currently only using first 5 years of good EVE data
nwvs=n_elements(eve.spectrummeta.wavelength)
tot_diff_sq=dblarr(n_proxies,nwvs)
fism_sig=dblarr(n_proxies,nwvs)
tot_fism=fltarr(ndys,nwvs,n_proxies)
tot_eve=fltarr(ndys,nwvs)
for i=0,n_proxies-1 do begin 
	ndys_cnt=fltarr(nwvs) ; count the bad data to subtract for each wavelength 
	for j=1,ndys-1 do begin ; Start with 2010121, end five years later to only use best eve data
           	; Separate the year.
                yr_st = strtrim(string(eve.mergeddata.yyyydoy[j]/1000), 2)
                res_pth=expand_path('$tmp_dir')+'/'+yr_st+'/'

		res_fl=res_pth+'FISM_tmp_daily_'+strtrim(eve.mergeddata.yyyydoy[j],2)+$
			'_tag'+strtrim(i+1,2)+'.sav'
		restore, res_fl
		gd=where(eve.mergeddata.sp_irradiance[*,j] gt 0)
                if gd[0] eq -1 then goto, skp_eve
		tot_diff_sq[i,gd]=tot_diff_sq[i,gd]+((eve.mergeddata.sp_irradiance[gd,j]-$
			fism_pred[gd])/eve.mergeddata.sp_irradiance[gd,j])^2.
		tot_fism[j,gd,i]=fism_pred[gd]
		tot_eve[j,gd]=eve.mergeddata.sp_irradiance[gd,j]
		ndys_cnt[gd]=ndys_cnt[gd]+1.
                skp_eve:
		;if j gt 40 and keyword_set(plots) then plot, sqrt(tot_diff_sq[i,*]/(ndys_cnt-2))
		;print, i, j, ' of ', ndys
		;wait, 0.02
	endfor
	fism_sig[i,*]=sqrt(tot_diff_sq[i,*]/(ndys_cnt))
	;print, i
	;if keywordstop
endfor

fism_arr=tot_fism
eve_arr=tot_eve

fism_sig_abs_temp=fltarr(n_proxies,nwvs)
for j=0,n_proxies-1 do fism_sig_abs_temp[j,*]=sqrt(reform(fism_sig[j,*])^2.+eve_l3_err^2.)
fism_sig_abs=fism_sig_abs_temp

corr_ar=fltarr(n_proxies,nwvs)
for i=0,n_proxies-1 do begin
	for j=0,nwvs-1 do corr_ar[i,j]=correlate(eve_arr[*,j],fism_arr[*,j,i])
endfor


; Find what is the primary proxy for each wavelength based on the
; smallest 
best_primary_tag=intarr(nwvs)
for k=0,nwvs-1 do begin
   min_sig=min(fism_sig[*,k],wmin)
   best_primary_tag[k]=wmin+1 ; tags from 1-9
endfor
eve_wv=eve.spectrummeta.wavelength
print, 'Saving best_primary_proxy.sav'
save, best_primary_tag, eve_wv, file=expand_path('$fism_save')+'/best_primary_proxy.sav'

print, 'Saving fism_daily_error_tmp.sav'
save, fism_sig, fism_sig_abs, file=save_path+'/fism_daily_error.sav'

if keyword_set(plots) then begin
	
	ans=''
	cc=independent_color()
	plot, eve.spectrummeta.wavelength, fism_sig[0,*]*100., yr=[0,100], psym=10, $
	xtitle='Wavelength (nm)', ytitle='Standard Deviation (%)',$
	charsize=2.0
	oplot, eve.spectrummeta.wavelength, fism_sig[1,*]*100., color=cc.red, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[2,*]*100., color=cc.orange, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[3,*]*100., color=cc.yellow, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[4,*]*100., color=cc.green, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[5,*]*100., color=cc.light_blue, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[6,*]*100., color=cc.purple, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[7,*]*100., color=cc.rust, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[8,*]*100., color=cc.blue, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[9,*]*100., color=cc.aqua, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[10,*]*100.;, color=cc.black, psym=10
	oplot, eve.spectrummeta.wavelength, fism_sig[11,*]*100., color=cc.red, psym=10
	xyouts, 80, 75, 'Black: MgII', charsize=1.5
	xyouts, 80, 70, 'Red: F10.7', charsize=1.5, color=cc.red
	xyouts, 80, 65, 'Orange: GOES', charsize=1.5, color=cc.orange
	xyouts, 80, 60, 'Yellow: L-ya', charsize=1.5, color=cc.yellow
	xyouts, 80, 55, 'Green: QD', charsize=1.5, color=cc.green
	xyouts, 80, 50, 'Light Blue: 171', charsize=1.5, color=cc.light_blue
	xyouts, 80, 45, 'Purple: 304', charsize=1.5, color=cc.purple
	xyouts, 80, 40, 'Rust: 335', charsize=1.5, color=cc.rust
	xyouts, 80, 35, 'Blue: 369', charsize=1.5, color=cc.blue
	xyouts, 80, 30, 'Aqua: ESP171', charsize=1.5, color=cc.aqua
	xyouts, 80, 25, 'Black: ESP304', charsize=1.5;, color=cc.black
	xyouts, 80, 20, 'Red: MEGS-P Lya', charsize=1.5, color=cc.red

	read, ans, prompt='Correlation Plot? '
	
	plot, eve.spectrummeta.wavelength, corr_ar[0,*], psym=10
	oplot, eve.spectrummeta.wavelength, corr_ar[1,*], psym=10,color=cc.red
	oplot, eve.spectrummeta.wavelength, corr_ar[2,*], psym=10,color=cc.orange
	oplot, eve.spectrummeta.wavelength, corr_ar[3,*], psym=10,color=cc.yellow
	oplot, eve.spectrummeta.wavelength, corr_ar[4,*], psym=10,color=cc.green
	oplot, eve.spectrummeta.wavelength, corr_ar[5,*], psym=10,color=cc.light_blue
	oplot, eve.spectrummeta.wavelength, corr_ar[6,*], psym=10,color=cc.purple
	oplot, eve.spectrummeta.wavelength, corr_ar[7,*], psym=10,color=cc.rust
	oplot, eve.spectrummeta.wavelength, corr_ar[8,*], psym=10,color=cc.blue
	oplot, eve.spectrummeta.wavelength, corr_ar[9,*], psym=10,color=cc.aqua
	oplot, eve.spectrummeta.wavelength, corr_ar[10,*], psym=10;,color=cc.black
	oplot, eve.spectrummeta.wavelength, corr_ar[11,*], psym=10,color=cc.red
	xyouts, 80, 0.65, 'Black: MgII', charsize=1.5
	xyouts, 80, 0.6, 'Red: F10.7', charsize=1.5, color=cc.red
	xyouts, 80, 0.55, 'Orange: GOES', charsize=1.5, color=cc.orange
	xyouts, 80, 0.5, 'Yellow: L-ya', charsize=1.5, color=cc.yellow
	xyouts, 80, 0.45, 'Green: QD', charsize=1.5, color=cc.green
	xyouts, 80, 0.4, 'Light Blue: 171', charsize=1.5, color=cc.light_blue
	xyouts, 80, 0.35, 'Purple: 304', charsize=1.5, color=cc.purple
	xyouts, 80, 0.3, 'Rust: 335', charsize=1.5, color=cc.rust
	xyouts, 80, 0.25, 'Blue: 369', charsize=1.5, color=cc.blue
	xyouts, 80, 0.2, 'Aqua: ESP171', charsize=1.5, color=cc.aqua
	xyouts, 80, 0.15, 'Black: ESP304', charsize=1.5;, color=cc.black
	xyouts, 80, 0.1, 'Red: MEGS-P Lya', charsize=1.5, color=cc.red
	
	read, ans, prompt='End Program? '
endif	

print, 'End Time find_daily_error: ', !stime

end
