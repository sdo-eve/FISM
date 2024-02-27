;
; NAME: three_prox_noscsr.pro
;
; PURPOSE: to compute a regression fit empirical model for the EVE data
;	based on all  daily proxies
;
; MODIFICATION HISTORY:
;	PCC	11/16/04	Program Creation
;	PCC	5/1/04		Updated to include all proxies and 2 proxy combinations
;	PCC	8/17/05		Now uses linfit_phil.pro (see p.13 of FISM v2 Notebook)
;	PCC	12/01/06	Updated for MacOSX
; 
;       VERSION 2_1
;       PCC     6/19/12         Updated to be based on SDO/EVE
;       PCC     7/30/12         Added debug keyword
;       PCC     3/7/14          Added ESP 171 and 304; MEGS-P as
;       proxies
;       PCC     1/11/17         Updated to 'find_xuv_c_xps.pro for XUV

pro find_xuv_c_xps, tag=tag, best_tag=best_tag, sc_best=sc_best, $
	eps_out=eps_out, debug=debug

print, 'Running find_xuv_c_xps, tag=', tag, '; ', !stime
set_plot, 'Z'
cc=independent_color()

save_pth = expand_path('$fism_save') 
fism_pth = expand_path('$fism') 
restore, fism_pth+'/tmp/proxies_pred.sav'; _2.sav'
restore, save_pth+'/xuv_e_sc_e_sr.sav'

; Make sure proxy data array is same size/days as good XPS data array
ndys_p=n_elements(day_ar_all)
ndys_xuv=n_elements(src_dy.date) ;n_elements(eve_data[0,*])
nwvs_xuv=n_elements(src_dy[0].modelflux_median)
p_days_xuv=intarr(ndys_xuv)
for k=0,ndys_xuv-1 do begin
	wprox=where(day_ar_all eq src_dy[k].date); and src_dy.modelflux[0] gt 0.0)
        if wprox[0] ne -1 then begin
           p_days_xuv[k]=wprox[0]
        endif
endfor

;e_tot=e_tot_xuv[p_days_xuv,*]
;e_sc=e_sc_xuv[p_days_xuv,*]
;e_sr=e_sr_xuv[p_days_xuv,*]
;xuv_daily_err=src_dy[p_days_xuv].err_abs

;FISM fit
x_fit=dblarr(12,ndys_xuv)
x_fit[0,*]=p_mgii[p_days_xuv]
x_fit[1,*]=p_f107[p_days_xuv]
x_fit[2,*]=p_goes[p_days_xuv]
x_fit[3,*]=p_lya[p_days_xuv]
x_fit[4,*]=p_qd[p_days_xuv]
x_fit[5,*]=p_171[p_days_xuv]
x_fit[6,*]=p_304[p_days_xuv]
x_fit[7,*]=p_335[p_days_xuv]
x_fit[8,*]=p_369[p_days_xuv]
x_fit[9,*]=p_171d[p_days_xuv]
x_fit[10,*]=p_304d[p_days_xuv]
x_fit[11,*]=p_lyad[p_days_xuv]
; FISM SC fit
x_fit_sc=dblarr(12,ndys_xuv)
x_fit_sc[0,*]=p_mgii_sc[p_days_xuv]
x_fit_sc[1,*]=p_f107_sc[p_days_xuv]
x_fit_sc[2,*]=p_goes_sc[p_days_xuv]
x_fit_sc[3,*]=p_lya_sc[p_days_xuv]
x_fit_sc[4,*]=p_qd_sc[p_days_xuv]
x_fit_sc[5,*]=p_171_sc[p_days_xuv]
x_fit_sc[6,*]=p_304_sc[p_days_xuv]
x_fit_sc[7,*]=p_335_sc[p_days_xuv]
x_fit_sc[8,*]=p_369_sc[p_days_xuv]
x_fit_sc[9,*]=p_171d_sc[p_days_xuv]
x_fit_sc[10,*]=p_304d_sc[p_days_xuv]
x_fit_sc[11,*]=p_lyad_sc[p_days_xuv]
; FISM SR fit
x_fit_sr=dblarr(12,ndys_xuv)
x_fit_sr[0,*]=p_mgii_sr[p_days_xuv]
x_fit_sr[1,*]=p_f107_sr[p_days_xuv]
x_fit_sr[2,*]=p_goes_sr[p_days_xuv]
x_fit_sr[3,*]=p_lya_sr[p_days_xuv]
x_fit_sr[4,*]=p_qd_sr[p_days_xuv]
x_fit_sr[5,*]=p_171_sr[p_days_xuv]
x_fit_sr[6,*]=p_304_sr[p_days_xuv]
x_fit_sr[7,*]=p_335_sr[p_days_xuv]
x_fit_sr[8,*]=p_369_sr[p_days_xuv]
x_fit_sr[9,*]=p_171d_sr[p_days_xuv]
x_fit_sr[10,*]=p_304d_sr[p_days_xuv]
x_fit_sr[11,*]=p_lyad_sr[p_days_xuv]

if keyword_set(tag) then begin
	case tag of
;		0: tag_ar=indgen(8)	; all 8 proxies, but if tag=0 won't enter this loop
		1: tag_ar=0 ; MgII
		2: tag_ar=1 ; F107
		3: tag_ar=2 ; goes
		4: tag_ar=3 ; lya composite
		5: tag_ar=4 ; ESP qd
		6: tag_ar=5 ; MEGS 171
		7: tag_ar=6 ; MEGS 304
		8: tag_ar=7 ; MEGS 335
                9: tag_ar=8 ; MEGS 369
		10: tag_ar=9 ; ESP 171
		11: tag_ar=10 ; ESP 304
                12: tag_ar=11 ; MEGS-P Lya
	endcase
endif else begin ; Sets default 
	tag=1 ; 0
	tag_ar=1 ; indgen(9)
endelse
x_fit=reform(x_fit[tag_ar,*])
x_fit_sc=reform(x_fit_sc[tag_ar,*])
x_fit_sr=reform(x_fit_sr[tag_ar,*])
x_fit_scsr=[x_fit_sc,x_fit_sr]
nx=n_elements(x_fit[*,0])
nx_scsr=n_elements(x_fit_scsr[*,0])

fit_coefs=fltarr(2,nwvs_xuv)
corr_ar=fltarr(nx,nwvs_xuv)
sigma_ar=fltarr(nx,nwvs_xuv)
mcorr_ar=fltarr(nwvs_xuv)
chisq_ar=fltarr(nwvs_xuv)
fit_coefs_sc=fltarr(2,nwvs_xuv)
corr_ar_sc=fltarr(nx,nwvs_xuv)
sigma_ar_sc=fltarr(nx,nwvs_xuv)
mcorr_ar_sc=fltarr(nwvs_xuv)
chisq_ar_sc=fltarr(nwvs_xuv)
fit_coefs_sc2=fltarr(3,nwvs_xuv)
corr_ar_sc2=fltarr(nx,nwvs_xuv)
sigma_ar_sc2=fltarr(nx,nwvs_xuv)
mcorr_ar_sc2=fltarr(nwvs_xuv)
chisq_ar_sc2=fltarr(nwvs_xuv)
fit_coefs_sr=fltarr(2,nwvs_xuv)
corr_ar_sr=fltarr(nx,nwvs_xuv)
sigma_ar_sr=fltarr(nx,nwvs_xuv)
mcorr_ar_sr=fltarr(nwvs_xuv)
chisq_ar_sr=fltarr(nwvs_xuv)
fit_coefs_scsr=fltarr(2,nwvs_xuv)
corr_ar_scsr=fltarr(nx_scsr,nwvs_xuv)
sigma_ar_scsr=fltarr(nx_scsr,nwvs_xuv)
mcorr_ar_scsr=fltarr(nwvs_xuv)
chisq_ar_scsr=fltarr(nwvs_xuv)
per_dif_sc=fltarr(nwvs_xuv)
per_dif_sc2=fltarr(nwvs_xuv)
per_dif_sr=fltarr(nwvs_xuv)
abs_dif_sc=fltarr(nwvs_xuv)
abs_dif_sc2=fltarr(nwvs_xuv)
abs_dif_sr=fltarr(nwvs_xuv)


for i=0,nwvs_xuv-1 do begin
	;
	;Total fit
	;
	
	;print, i
	fitrng=where(reform(src_dy.modelflux_median[i,*]) gt 0.0 and x_fit gt 0.0); and xuv_daily_err le 0.6)
        if fitrng[0] eq -1 then goto, no_eve_data
	res=poly_fit(x_fit[fitrng],reform(e_tot_xuv[fitrng,i]), 1,$
		chisq=chisq);, /stat_meas_errs)
	med=(median(e_tot_xuv[fitrng,i]))^2.
	chisq_ar[i]=chisq/med
	fit_coefs[*,i]=res
	;corr_ar[*,i]=corr
	;sigma_ar[*,i]=sigma
	;mcorr_ar[i]=mcorr
	
	;
	;SR fit - Don't do statistical weighting as there is so many 
	;	points near zero, but still to 2-sig elimination 
	;
	;if tag eq 5 then begin ; Eliminate extreme points in Lya data set
	;	res=linfit_phil(x_fit_sr[*,fitrng],reform(e_sr[fitrng,i]), $
	;		chisq=chisq, /two_sig, yfit=yfit, low_cut=95)
	;endif else begin
		res=linfit(x_fit_sr[fitrng],reform(e_sr_xuv[fitrng,i]), $
			chisq=chisq, yfit=yfit) ;,/two_sig
	;endelse
	nfit=n_elements(yfit)
	; Only find error above 0.25% of the median yfit value in order
	;	to emiminate dividing by zero or near zero
	cutoff=median(abs(yfit))
	err_fit_rng=where(abs(yfit) gt cutoff)
	new_nfit=n_elements(err_fit_rng)
	per_dif_sr[i]=(sqrt((total(((yfit[err_fit_rng]-reform(e_sr_xuv[fitrng[err_fit_rng],i]))/$
		reform(e_sr_xuv[fitrng[err_fit_rng],i]))^2))/(new_nfit-1)))
	abs_dif_sr[i]=sqrt((total((yfit-reform(e_sr_xuv[fitrng,i]))^2.))/(nfit-1))
	;if i eq 34 then stop
	med=(median(e_sr_xuv[fitrng,i]))^2.
	chisq_ar_sr[i]=chisq/med
	fit_coefs_sr[*,i]=res
	;corr_ar_sr[*,i]=corr
	;sigma_ar_sr[*,i]=sigma
	;mcorr_ar_sr[i]=mcorr
	
	;
	;SC fit
	;
        res_sc=poly_fit(x_fit_sc[fitrng],reform(e_sc_xuv[fitrng,i]), 1,$
		chisq=chisq, $;/stat_meas_errs, $
                        yfit=yfit)
        res_sc2=poly_fit(x_fit_sc[fitrng],reform(e_sc_xuv[fitrng,i]), 2,$
		chisq=chisq2, $;/stat_meas_errs, $
		yfit=yfit2)
        ;endif else begin
         ;  res_sc=linfit_phil(x_fit_sc[*,fitrng],reform(e_sc[fitrng,i]), $
	;	chisq=chisq, /stat_meas_errs, $
	;	yfit=yfit)
        ;endelse
	nfit=n_elements(yfit)
	per_dif_sc[i]=(sqrt((total(((yfit-reform(e_sc_xuv[fitrng,i]))/$
		reform(e_sc_xuv[fitrng,i]))^2))/(nfit-1)))
        per_dif_sc2[i]=(sqrt((total(((yfit2-reform(e_sc_xuv[fitrng,i]))/$
		reform(e_sc_xuv[fitrng,i]))^2))/(nfit-1)))
	abs_dif_sc[i]=sqrt((total((yfit-reform(e_sc_xuv[fitrng,i]))^2.))/(nfit-1))
	abs_dif_sc2[i]=sqrt((total((yfit2-reform(e_sc_xuv[fitrng,i]))^2.))/(nfit-1))
	;if i eq 30 then stop
	med=(median(e_sc_xuv[fitrng,i]))^2.
	chisq_ar_sc[i]=chisq/med
	chisq_ar_sc2[i]=chisq2/med
	fit_coefs_sc[*,i]=res_sc
	fit_coefs_sc2[*,i]=res_sc2
	;corr_ar_sc[*,i]=corr
	;sigma_ar_sc[*,i]=sigma
	;mcorr_ar_sc[i]=mcorr
	
	;
	;SR and SC regress fit
	;
	res=regress(x_fit_scsr[fitrng],reform(e_tot_xuv[fitrng,i]), $
		const=const, chisq=chisq, correlation=corr, $
		ftest=ftest, mcorrelation=mcorr, sigma=sigma, $
		measure_errors=reform(src_dy.err_abs[fitrng]))
	med=(median(e_sr_xuv[fitrng,i]))^2.
	chisq_ar_scsr[i]=chisq/med
	fit_coefs_scsr[1,i]=res
	fit_coefs_scsr[0,i]=const
	corr_ar_scsr[*,i]=corr
	sigma_ar_scsr[*,i]=sigma
	mcorr_ar_scsr[i]=mcorr

	if keyword_set(debug) then begin
           print, i
           cc=independent_color()
           xax=findgen(10000)/1000.
           ans=''
           plot, x_fit_sc[*,fitrng],reform(e_sc_xuv[fitrng,i]), psym=2, title='Solar Cycle'
           yfit_sc=fit_coefs_sc[0,i]+fit_coefs_sc[1,i]*xax
           yfit_sc2=fit_coefs_sc2[0,i]+fit_coefs_sc2[1,i]*xax+fit_coefs_sc2[2,i]*xax*xax
           oplot, xax, yfit_sc, thick=2
           oplot, xax, yfit_sc2, thick=2, color=cc.red
           read, ans, prompt='Solar Rotation Fit?'
           plot, x_fit_sr[*,fitrng],reform(e_sr_xuv[fitrng,i]), psym=2, title='Solar Rotation'
           xax_sr=(findgen(10000)-5000.)/1000.
           yfit_sr=fit_coefs_sr[0,i]+fit_coefs_sr[1,i]*xax_sr
           oplot, xax_sr, yfit_sr, thick=2
           read, ans, prompt='Next wv?'
	endif
	
        no_eve_data:
endfor


; Force sc fit slope coefficient to be + (there are no line/proxies that are anti-correlated with SC)
bd=where(fit_coefs_sc[1,*] lt 0.0)
if bd[0] ne -1 then fit_coefs_sc[1,bd]=0.0
; EVE 43.5 nm and 46.5 nm bins do not have accurate long-term trends, so zero the SC
;fit_coefs_sc[1,43]=0.0
;fit_coefs_sc[1,46]=0.0

; Save the fit coefs to predict the FISM spectra
if keyword_set(sc_best) then begin
	flnm=save_pth+'/three_prox_fitcoefs_tag'+strtrim(tag,2)+'_scav'+strtrim(sc_avg_dys,2)+'_xuv.sav'
endif else begin
	flnm=save_pth+'/sc_sr_fit_coefs_xuv_tag'+strtrim(tag,2)+'.sav'
endelse
print, 'Saving Fit Coefs (tag '+strtrim(tag,2)+') ...'
save, fit_coefs, fit_coefs_sc2, fit_coefs_scsr, fit_coefs_sc,fit_coefs_sr, abs_dif_sc, $
	abs_dif_sr, per_dif_sc, per_dif_sr, file=flnm

print, 'End Time find_xuv_c_xps: ', !stime

;stop

end
