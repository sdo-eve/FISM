;
; NAME: find_fuv_c_sol.pro
;
; PURPOSE: to find the daily coefs for the FUV based on the UARS SOLSTICE
;	data from 1991-1996
;
; KEYWORDS:
;       res_e_p: set to restore files created in the first part of e
;       and p instead of recreating these
;
; MODIFICATION HISTORY
;	PCC	8/30/05	Program Creation
;	PCC	12/1/06	Updated for MacOSX
;       PCC     11/9/17 Updated for FISM_V2, 1A, SORCE
;

pro find_fuv_c_sol, tag=tag, debug=debug, res_e_p=res_e_p

if not keyword_set(tag) then tag=0 ; 0=lya, 1=mgii, 2=f107
fism_save_pth=expand_path('$fism_save')

if keyword_set(res_e_p) then goto, skp_e_p_create

print, 'Running find_fuv_c_sol, tag=',tag , ', ', !stime

cur_utc=bin_date(systime(/utc))
cur_dy = get_current_yyyydoy()
cur_yr=fix(cur_dy/1000)
;end_yd=cur_dy

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

sc_avg_dys=108
fism_data_pth=getenv('fism_data')

if tag eq 1 then begin
	; Get the MgII data
	restore, fism_data_pth+'/lasp/mgii/mgii_idx.sav'
	;mgii_yf=yd_to_yfrac(mgii_yd)
	n_mgii=n_elements(mgii_yd)

	; Find the 108-day sc smoothing
	sm_mgii=fltarr(n_mgii)
	mgii_res=fltarr(n_mgii)
	for j=0,n_mgii-1 do begin
		st_sm=get_prev_yyyydoy(mgii_yd[j],54)
		end_sm=get_next_yyyydoy(mgii_yd[j],54)
		wsmooth=where(mgii_yd ge st_sm and mgii_yd le end_sm and $
			mgii_ind gt 0.0)
		sm_mgii[j]=mean(mgii_ind[wsmooth])
		mgii_res[j]=mgii_ind[j]-sm_mgii[j]
             endfor
        min_mgii=min(sm_mgii)
endif

if tag eq 2 then begin

	;
	;       Get the F10.7 index
	;
	st_yd_f=get_prev_yyyydoy(st_yd, sc_avg_dys/2.)
	end_yd_f=get_next_yyyydoy(end_yd, sc_avg_dys/2.)
	restore, fism_data_pth+'/lasp/f10_7_merged/f107_data.sav'
	f107_yd=ft_time
	f107_data=ft
	;Find the previous n-day average - Using this so the predicted
	;  spectrum can be found for the current day (except for 1st n-days)	
	n_days_f=n_elements(f107_data)
	; create the sc n-day average
	sm_f107=fltarr(n_days_f)
	sm_f107=smooth(f107_data,sc_avg_dys)
        f107_res=f107_data-sm_f107
        min_f107=min(sm_f107)

endif


	
; Find the 108-day sc smoothing
nwv=n_elements(src_l3.standard_wavelengths)
ndy=n_elements(src_l3_ydoy)
sm_fuv=fltarr(nwv,ndy)
fuv_res=fltarr(nwv,ndy)
mgii_fuv_dy=fltarr(ndy)
mgii_fuv_dy_res=fltarr(ndy)
f107_fuv_dy=fltarr(ndy)
f107_fuv_dy_res=fltarr(ndy)
for k=0,ndy-1 do begin
	st_sm=get_prev_yyyydoy(src_l3_ydoy[k],54)
	end_sm=get_next_yyyydoy(src_l3_ydoy[k],54)
	for j=0,nwv-1 do begin	
		wsmooth=where(src_l3_ydoy ge st_sm and src_l3_ydoy le end_sm and $
			src_l3_irradiance[j,*] gt 0.0)
		sm_fuv[j,k]=mean(src_l3_irradiance[j,wsmooth])
		fuv_res[j,k]=src_l3_irradiance[j,k]-sm_fuv[j,k]
	endfor
	if tag eq 1 then begin	
		wmgii=where(mgii_yd eq src_l3_ydoy[k])
		if wmgii[0] ne -1 then begin
			mgii_fuv_dy[k]=sm_mgii[wmgii[0]] 
			mgii_fuv_dy_res[k]=mgii_res[wmgii[0]] 
		endif else begin
			mgii_fuv_dy[k]=-1
			mgii_fuv_dy_res[k]=-1
		endelse
	endif
	if tag eq 2 then begin
		wf107=where(fix(f107_yd,type=3) eq src_l3_ydoy[k])
		if wf107[0] ne -1 then begin
			f107_fuv_dy[k]=sm_f107[wf107] 
			f107_fuv_dy_res[k]=f107_res[wf107] 
		endif else begin
			f107_fuv_dy[k]=-1
			f107_fuv_dy_res[k]=-1
		endelse
	endif
endfor

; create and save the minimum spectrum by simply finding minimum valid smoothed
; measurement
fuv_min_sp=fltarr(nwv)
for m=0,nwv-1 do begin
   gd=where(sm_fuv[m,*] gt 0.0)
   fuv_min_sp[m]=min(sm_fuv[m,gd])
endfor
save, fuv_min_sp, src_l3_standard_wavelengths, file=fism_save_pth+'/fuv_min_sp_tag'+strtrim(tag,2)+'.sav'

if tag eq 1 then begin
	gd=where(src_l3_ydoy ge st_yd and src_l3_ydoy le end_yd and mgii_fuv_dy gt 0.0)
	p_mgii_sc=(mgii_fuv_dy[gd]/min_mgii)-1.
	p_mgii_sr=(mgii_fuv_dy_res[gd]/min_mgii)
endif else if tag eq 2 then begin
	gd=where(src_l3_ydoy ge st_yd and src_l3_ydoy le end_yd and f107_fuv_dy gt 0.0)
	p_f107_sc=(f107_fuv_dy[gd]/min_f107)-1.
	p_f107_sr=(f107_fuv_dy_res[gd]/min_f107)
endif else begin ; tag=0 lya
   wlya=where(src_l3_standard_wavelengths ge 121.56)
   gd=where(src_l3_ydoy ge st_yd and src_l3_ydoy le end_yd and $
                          sm_fuv[wlya[0],*] gt 0.0)
   p_lya=fltarr(ndy)
   for n=0,ndy-1 do begin
      p_lya[n]=mean(src_l3_irradiance[wlya[0]-2:wlya[0]+2,n])
   endfor
   sm_p_lya=smooth(p_lya,sc_avg_dys)
   min_lya=min(sm_p_lya)
   p_lya_sc=(sm_p_lya[gd]/min_lya)-1.
   p_lya_sr=(p_lya[gd]-sm_p_lya)/min_lya
endelse

ngd=n_elements(gd)
ndygd=n_elements(sm_fuv[*,0])
e_fuv_sc=fltarr(ndygd,ngd)
e_fuv_sr=fltarr(ndygd,ngd)
for m=0,nwv-1 do begin 
	e_fuv_sc[m,*]=(sm_fuv[m,gd]/fuv_min_sp[m])-1.
	e_fuv_sr[m,*]=(fuv_res[m,gd]/fuv_min_sp[m])
endfor

if tag eq 1 then begin
   save, p_mgii_sc, p_mgii_sr, min_mgii, e_fuv_sc, e_fuv_sr, nwv, src_l3_standard_wavelengths, $
         file=fism_save_pth+'/fuv_e_p_sc_sr_tag'+strtrim(tag,2)+'.sav'
endif else if tag eq 2 then begin
   save, p_f107_sc, p_f107_sr, min_f107, e_fuv_sc, e_fuv_sr, nwv, src_l3_standard_wavelengths, $
         file=fism_save_pth+'/fuv_e_p_sc_sr_tag'+strtrim(tag,2)+'.sav'
endif else begin
   save, p_lya_sc, p_lya_sr, min_lya, e_fuv_sc, e_fuv_sr, nwv, src_l3_standard_wavelengths, $
         file=fism_save_pth+'/fuv_e_p_sc_sr_tag'+strtrim(tag,2)+'.sav'
endelse

skp_e_p_create:
if keyword_set(res_e_p) then begin
   restore, file=fism_save_pth+'fuv_e_p_sc_sr_tag'+strtrim(tag,2)+'.sav'
endif

; Find the linear fit coefs c_sc and c_sr for the FUV
fit_coefs_sc=fltarr(2,nwv)
corr_ar_sc=fltarr(nwv)
sigma_ar_sc=fltarr(nwv)
mcorr_ar_sc=fltarr(nwv)
chisq_ar_sc=fltarr(nwv)
fit_coefs_sr=fltarr(2,nwv)
corr_ar_sr=fltarr(nwv)
sigma_ar_sr=fltarr(nwv)
mcorr_ar_sr=fltarr(nwv)
chisq_ar_sr=fltarr(nwv)
per_dif_sc=fltarr(nwv)
per_dif_sr=fltarr(nwv)
abs_dif_sc=fltarr(nwv)
abs_dif_sr=fltarr(nwv)
for p=0,nwv-1 do begin
	;
	;SR fit - Don't do statistical weighting as there are so many 
	;	points near zero, but still to 2-sig elimination 
	;
	if tag eq 0 then begin ; Eliminate extreme points in Lya data set
		fitrng=where(e_fuv_sc[p,*] gt 0.0 and p_lya_sc gt 0.0 and $
			p_lya_sr gt -1.0 and e_fuv_sr[p,*] gt -2.0)
		res=poly_fit(p_lya_sr[fitrng],e_fuv_sr[p,fitrng], 1, $
			chisq=chisq, yfit=yfit);, low_cut=95)
                xfit_sr=p_lya_sr[fitrng]
        endif else if tag eq 1 then begin
		fitrng=where(e_fuv_sc[p,*] gt 0.0 and p_mgii_sr gt -0.1 and $
			p_mgii_sr gt -1.0 and e_fuv_sr[p,*] gt -2.0)
		res=poly_fit(p_mgii_sr[fitrng],e_fuv_sr[p,fitrng], 1, $
			chisq=chisq, yfit=yfit)
                xfit_sr=p_mgii_sr[fitrng]
        endif else begin
		fitrng=where(e_fuv_sc[p,*] gt 0.0 and p_f107_sc gt 0.0 and $
			p_f107_sr gt -3.0 and e_fuv_sr[p,*] gt -2.0)
		res=poly_fit(p_f107_sr[fitrng],e_fuv_sr[p,fitrng], 1, $
			chisq=chisq, yfit=yfit)	
                xfit_sr=p_f107_sr[fitrng]
        endelse
	nfit=n_elements(yfit)
	; Only find error above 0.25% of the median yfit value in order
	;	to emiminate dividing by zero or near zero
	cutoff=median(abs(e_fuv_sr[p,fitrng]));*0.75
	err_fit_rng=where(abs(e_fuv_sr[p,fitrng]) gt cutoff); and rat lt 5 $
		;and rat gt -5)
	new_nfit=n_elements(err_fit_rng)
	per_dif_sr[p]=(sqrt((total(((yfit[err_fit_rng]-reform(e_fuv_sr[p,fitrng[err_fit_rng]]))/$
		reform(e_fuv_sr[p,fitrng[err_fit_rng]]))^2.))/(new_nfit-2)))
	abs_dif_sr[p]=sqrt((total((yfit-reform(e_fuv_sr[p,fitrng]))^2.))/(nfit-1))
	;if i eq 34 then stop
	med=(median(e_fuv_sr[p,fitrng]))^2.
	chisq_ar_sr[p]=chisq/med
        fit_coefs_sr[*,p]=res
        yfit_sr=yfit
	;corr_ar_sr[*,i]=corr
	;sigma_ar_sr[*,i]=sigma
	;mcorr_ar_sr[i]=mcorr
	
	;
	;SC fit
	;
	if tag eq 0 then begin
		res_sc=linfit_phil(p_lya_sc[fitrng],e_fuv_sc[p,fitrng], $
			chisq=chisq, /stat_meas_errs, $
			yfit=yfit)
                xfit_sc=p_lya_sc[fitrng]
        endif else if tag eq 1 then begin
		res_sc=linfit_phil(p_mgii_sc[fitrng],e_fuv_sc[p,fitrng], $
			chisq=chisq, /stat_meas_errs, $
                        yfit=yfit)
                xfit_sc=p_mgii_sc[fitrng]
	endif else begin
		res_sc=linfit_phil(p_f107_sc[fitrng],e_fuv_sc[p,fitrng], $
			chisq=chisq, /stat_meas_errs, $
                        yfit=yfit)
                xfit_sc=p_f107_sc[fitrng]
	endelse
	nfit=n_elements(yfit)
	per_dif_sc[p]=(sqrt((total(((yfit-reform(e_fuv_sc[p,fitrng]))/$
		reform(e_fuv_sc[p,fitrng]))^2))/(nfit-1)))
	abs_dif_sc[p]=sqrt((total((yfit-reform(e_fuv_sc[p,fitrng]))^2.))/(nfit-1))
	;if i eq 30 then stop
	med=(median(e_fuv_sc[p,fitrng]))^2.
	chisq_ar_sc[p]=chisq/med
	fit_coefs_sc[*,p]=res_sc
	;corr_ar_sc[*,i]=corr
	;sigma_ar_sc[*,i]=sigma
	;mcorr_ar_sc[i]=mcorr
	;if us_wv[p] eq 133 then stop

        if keyword_set(debug) then begin
           cc=independent_color()
           ans=''
           plot, xfit_sc, e_fuv_sc[p,fitrng], psym=3, title='SC, wv='+strtrim(src_l3_standard_wavelengths[p],2)+'nm'
           oplot, xfit_sc, yfit, color=cc.red, psym=3
           print, res_sc
           ;plot, p_lya_sc[fitrng], e_fuv_sc[p,fitrng], psym=3, title='SC, wv='+strtrim(src_l3_standard_wavelengths[p],2)+'nm'
           ;oplot, p_mgii_sc[fitrng], e_fuv_sc[p,fitrng], psym=3, color=cc.blue
           ;oplot,p_f107_sc[fitrng], e_fuv_sc[p,fitrng], psym=3, color=cc.red
           read, ans, prompt='SR Plot?'
           plot, xfit_sr,  e_fuv_sr[p,fitrng], psym=3, title='SC, wv='+strtrim(src_l3_standard_wavelengths[p],2)+'nm'
           oplot, xfit_sr, yfit_sr, color=cc.red, psym=3
           print, res
           ;plot, p_lya_sr[fitrng], e_fuv_sr[p,fitrng], psym=3, title='SC, wv='+strtrim(src_l3_standard_wavelengths[p],2)+'nm'
           ;oplot, p_mgii_sr[fitrng], e_fuv_sr[p,fitrng], psym=3, color=cc.blue
           ;oplot, p_f107_sr[fitrng], e_fuv_sr[p,fitrng], psym=3, color=cc.red
           read, ans, prompt='Next Wavelength?'
           
        endif
endfor

flnm=fism_save_pth+'/sc_sr_fit_coefs_fuv_tag'+strtrim(tag,2)+'.sav'
print, 'Saving ', flnm
save, fit_coefs_sc,fit_coefs_sr, abs_dif_sc, src_l3_standard_wavelengths, $
	abs_dif_sr, per_dif_sc, per_dif_sr, file=flnm

print, 'End Time find_fuv_c_sol: ', !stime

end
