;
; NAME: find daily_error.pro
;
; PURPOSE: to find the daily error for FISM
;

pro find_daily_error_xuv, plots=plots

print, 'Running find_daily_error.pro', !stime

n_proxies=12

; Restore SORCE XPS data
data_path=expand_path('$fism_data') 
read_netcdf, data_path+'/lasp/sorce/sorce_xps/sorce_xps_L4_c24h_r0.1nm_latest.ncdf', src_dy ; start with 2003

; Restore the SORCE XPS mean error for each wavelength
;	created by find_meas_errors.pro
save_path=expand_path('$fism_save') 
restore, save_path+'/sorce_xps_mean_err.sav'

; Find FISM errors for XUV
ndys=n_elements(src_dy.date)
nwvs=n_elements(src_dy[0].modelflux_median)
tot_diff_sq=dblarr(n_proxies,nwvs)
fism_sig=dblarr(n_proxies,nwvs)
tot_fism=fltarr(ndys,nwvs,n_proxies)
tot_eve=fltarr(ndys,nwvs)
for i=1,n_proxies-1 do begin 
	ndys_cnt=fltarr(nwvs) ; count the bad data to subtract for each wavelength 
	for j=1,ndys-1 do begin ; Start with 2010121, end five years later to only use best eve data
           	; Separate the year.
                yr_st = strtrim(string(src_dy[j].date/1000), 2)
                res_pth=expand_path('$tmp_dir')+'/'+yr_st+'/'

		res_fl=res_pth+'FISM_tmp_daily_'+strtrim(src_dy[j].date,2)+$
			'_tag'+strtrim(i+1,2)+'_xuv.sav'
		restore, res_fl
                gd=where(src_dy[j].modelflux_median gt 0.0 and fism_pred gt 0.0 and abs(src_dy[j].modelflux_median[20]-fism_pred[20]) lt 1.e-4 $
                        and src_dy[j].modelflux_median[20] gt 1.e-5)
                if gd[0] eq -1 then goto, skp_xps
		tot_diff_sq[i,gd]=tot_diff_sq[i,gd]+((src_dy[j].modelflux_median[gd]-$
			fism_pred[gd])/src_dy[j].modelflux_median[gd])^2.
		tot_fism[j,gd,i]=fism_pred[gd]
		tot_eve[j,gd]=src_dy[j].modelflux_median[gd]
		ndys_cnt[gd]=ndys_cnt[gd]+1.
                skp_xps:
		;if j gt 40 and keyword_set(plots) then plot, sqrt(tot_diff_sq[i,*]/(ndys_cnt-2))
		;print, i, j, ' of ', ndys
                                ;wait, 0.02
                ;if gd[0] ne -1 then stop
	endfor
	fism_sig[i,*]=sqrt(tot_diff_sq[i,*]/(ndys_cnt))
	;print, i
	;if keywordstop
endfor

fism_sig_xuv=fism_sig
fism_arr=tot_fism
eve_arr=tot_eve

fism_sig_abs_temp=fltarr(n_proxies,nwvs)
for j=0,n_proxies-1 do fism_sig_abs_temp[j,*]=sqrt(reform(fism_sig[j,*])^2.+sorce_xps_err^2.)
fism_sig_abs_xuv=fism_sig_abs_temp

corr_ar=fltarr(n_proxies,nwvs)
for i=0,n_proxies-1 do begin
	for j=0,nwvs-1 do corr_ar[i,j]=correlate(eve_arr[*,j],fism_arr[*,j,i])
endfor


; Find what is the primary proxy for each wavelength based on the
; smallest 
best_primary_tag=intarr(nwvs)
for k=0,nwvs-1 do begin
   min_sig=min(fism_sig[*,k],wmin)
   best_primary_tag[k]=wmin+1 ; tags from 1-12
endfor
xuv_wv=findgen(400)/10.+0.5
print, 'Saving best_primary_proxy_xuv.sav'
save, best_primary_tag, xuv_wv, file=expand_path('$fism_save')+'/best_primary_proxy_xuv.sav'

print, 'Saving fism_daily_error_xuv.sav'
save, fism_sig_xuv, fism_sig_abs_xuv, file=save_path+'/fism_daily_error_xuv.sav'

if keyword_set(plots) then begin
	
	ans=''
	cc=independent_color()
	plot, xuv_wv, fism_sig[0,*]*100., yr=[0,100], psym=10, $
	xtitle='Wavelength (nm)', ytitle='Standard Deviation (%)',$
	charsize=2.0
	oplot, xuv_wv, fism_sig[1,*]*100., color=cc.red, psym=10
	oplot, xuv_wv, fism_sig[2,*]*100., color=cc.orange, psym=10
	oplot, xuv_wv, fism_sig[3,*]*100., color=cc.yellow, psym=10
	oplot, xuv_wv, fism_sig[4,*]*100., color=cc.green, psym=10
	oplot, xuv_wv, fism_sig[5,*]*100., color=cc.light_blue, psym=10
	oplot, xuv_wv, fism_sig[6,*]*100., color=cc.purple, psym=10
	oplot, xuv_wv, fism_sig[7,*]*100., color=cc.rust, psym=10
	oplot, xuv_wv, fism_sig[8,*]*100., color=cc.blue, psym=10
	oplot, xuv_wv, fism_sig[9,*]*100., color=cc.aqua, psym=10
	oplot, xuv_wv, fism_sig[10,*]*100.;, color=cc.black, psym=10
	oplot, xuv_wv, fism_sig[11,*]*100., color=cc.red, psym=10
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
	
	plot, xuv_wv, corr_ar[0,*], psym=10
	oplot, xuv_wv, corr_ar[1,*], psym=10,color=cc.red
	oplot, xuv_wv, corr_ar[2,*], psym=10,color=cc.orange
	oplot, xuv_wv, corr_ar[3,*], psym=10,color=cc.yellow
	oplot, xuv_wv, corr_ar[4,*], psym=10,color=cc.green
	oplot, xuv_wv, corr_ar[5,*], psym=10,color=cc.light_blue
	oplot, xuv_wv, corr_ar[6,*], psym=10,color=cc.purple
	oplot, xuv_wv, corr_ar[7,*], psym=10,color=cc.rust
	oplot, xuv_wv, corr_ar[8,*], psym=10,color=cc.blue
	oplot, xuv_wv, corr_ar[9,*], psym=10,color=cc.aqua
	oplot, xuv_wv, corr_ar[10,*], psym=10;,color=cc.black
	oplot, xuv_wv, corr_ar[11,*], psym=10,color=cc.red
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

print, 'End Time find_daily_error_xuv: ', !stime

end
