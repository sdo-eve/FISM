;
;  NAME: create_min_sp.pro
;
;  PURPOSE: to create the minimum SEE spectrum based on the F10.7 or MgII 
;
;  MODIFICATION HISTORY:
;	PCC	5/25/04		Program Creation
;	PCC	5/25/04		Modified to create two arrays of SEE data for 
;				flare (xps_index > 1.5) and non-flare data
;	PCC	5/27/04		Change flare threshold to >1.3
;	**Version 2**
;	PCC	6/4/04		Modified to use the 54-day trailing average (SC)
;	PCC	6/11/04		Modified to also compute the max reference 
;					spectrum
;	PCC	6/29/04		Changed the daily min/max f107 to 54 day min/max
;	PCC	7/5/04		Removed creation of SEE data array to new program
;					called 'create_see_arr_l3a.pro'
;	**Version 3**
;	PCC	7/5/04		Now uses SEE level 3 data (daily), not level 3a
;	**Version 4**
;	PCC	7/22/04		Set up to restore SEE merged data set
;				Set up to run as a daily Kron job 
;	PCC	8/23/04		Option to plot or not to plot
;	PCC	11/2/04		Now accepts the avg days for sc avg and the 
;				convol kernal
;	**Version 5**
;	PCC	11/10/04	Now uses the best kernal found by 'op_conv_kern.pro'
;	PCC	11/19/04	Added the exponential fit of the data
;	PCC	11/28/04	Added the quadratic fit 
;	PCC	3/8/05		Eliminated a bunch of redundant code, v6
; 	PCC	3/29/05		Eliminated the use of the convolution kernal
;	PCC	4/3/05		Eliminated negative values for min sp and fits to 
;				zero or missing SEE data
;	PCC	6/24/05		Added the keyword sc_av to use the solar cycle averages
;				for the fit instead of the daily average data
; 	PCC	6/26/05		New f10.7 and Mgii min and max values (see p. 151)
;	PCC	8/17/05		Now use 'linfit_phil.pro' (see p.13 of FISM v2 notebook)
;	PCC	12/01/06	Updated for MacOSX	
;       
;       VERSION 02_01
;       PCC     5/23/12         Updated for SDO/EVE
;
;+

pro create_min_sp, plots=plots, comp_plots=comp_plots, sc_av=sc_av, eps_wv=eps_wv, debug=debug

print, 'Running create_min_sp.pro', !stime

psout=0

; Get the EVE and Proxy data
tmp_pth = expand_path('$tmp_dir') 
restore, tmp_pth+'/eve_sc_av.sav'
restore, tmp_pth+'/proxies_1.sav'	
restore, tmp_pth+'/prox_sc_sr_pred.sav'
nel=n_elements(day_ar_all)

; Get the SOHO SEM data
;restore, '/titus/timed/analysis/soho/all_sem_daily_v3.sav'
data_pth = expand_path('$fism_data') 
restore, data_pth+'/soho_sem/sem_data.sav'
bd_sem=where(sem_irr le 0.0)
; Guess at missing SEM values
nbad_sem=n_elements(bd_sem)
for i=0,nbad_sem-1 do begin
	sem_irr[bd_sem[i]]=sem_irr[bd_sem[i]-1]
endfor
sem_81=smooth(sem_irr,81,/edge_truncate)
sem_dy=fix(sem_yd, type=3)
nsem_dy=n_elements(sem_dy)
sem_wv=replicate(30.4,nsem_dy)
;sem_81=ph2watt(sem_wv,sem_81)

; Min/Max proxy values 
; PCC 3/7/2014 now from prox_sc_sr_pred.sav
;max_f107=456.1
;min_f107=62.60
;max_mgii=0.29095
;min_mgii=0.26261
;max_lya=9.8254e-3	
;min_lya=0.00563588
max_sem=1.633e-3 ;(estimate)
min_sem=7.245e-4 ;(actual)

if keyword_set(sc_av) then begin
        ; Use the min/max values 
	; Replace the EVE data with EVE_SC_AV
        eve_data=eve_sc_av
	; Replace the proxy data with p_sc_av
	p_f107=f107_sc_av/min_f107-1.
	p_mgii=mgii_sc_av/min_mgii-1.
	p_goes=goes_sc_av/1.e-8-1.
	p_lya=lya_sc_av/min_lya-1.
	p_sem=sem_81/min_sem-1.
endif

nwvs=n_elements(eve_wv)
ndays=n_elements(eve_day_ar)

; Find the max and min spectra using each proxy
min_max_sp_f107=fltarr(3,nwvs) ; wv, min, max
min_max_sp_mgii=fltarr(3,nwvs)
min_max_sp_goes=fltarr(3,nwvs)
min_max_sp_lya=fltarr(3,nwvs)
min_max_sp_sem=fltarr(3,nwvs)
min_max_sp_f107_e=fltarr(3,nwvs) ; wv, min, max
min_max_sp_mgii_e=fltarr(3,nwvs)
min_max_sp_goes_e=fltarr(3,nwvs)
min_max_sp_lya_e=fltarr(3,nwvs)
min_max_sp_sem_e=fltarr(3,nwvs)
min_max_sp_f107_q=fltarr(3,nwvs) ; wv, min, max
min_max_sp_mgii_q=fltarr(3,nwvs)
min_max_sp_goes_q=fltarr(3,nwvs)
min_max_sp_lya_q=fltarr(3,nwvs)
min_max_sp_sem_q=fltarr(3,nwvs)
chisq_ar_m=fltarr(3,nwvs)	; lin, exp, quad
chisq_ar_f=fltarr(3,nwvs)
chisq_ar_g=fltarr(3,nwvs)
chisq_ar_l=fltarr(3,nwvs)
chisq_ar_s=fltarr(3,nwvs)
stdev_ar_m=fltarr(2,3,nwvs)	; [0,*,*]:absolute stdev, [1,*,*]:percent stdev
stdev_ar_f=fltarr(2,3,nwvs)	
stdev_ar_g=fltarr(2,3,nwvs)
stdev_ar_l=fltarr(2,3,nwvs)
stdev_ar_s=fltarr(2,3,nwvs)
ans=''
for k=0,nwvs-1 do begin
	fit_ind=where(eve_data[k,0:1450] gt 0.0) ; Limit to first ~5 years of good EVE data
        ngd_dys=n_elements(fit_ind)
        if fit_ind[0] eq -1 then goto, bd_eve_data ; no EVE data for this wavelength
	; Find minimum of SEE data for that wavelength (k) to use if extrapolation
	;	goes negative (use .99 of min see value to avoid divide by zero errors)
	maxeve=max(eve_data[k,fit_ind],min=mineve)
	mineve=mineve*0.99
	
        ;
	;Find minimum for wv using f10.7
        ; 
        
        ; Determine the corresponding days for each array (Good for all proxies)
        fit_ind_prox_tmp=intarr(ngd_dys)
        for d=0,ngd_dys-1 do begin
           a=where(day_ar_all eq eve_day_ar[fit_ind[d]])
           if a[0] ne -1 then fit_ind_prox_tmp[d]=a
        endfor
        gd=where(fit_ind_prox_tmp gt 0)
        fit_ind_prox=fit_ind_prox_tmp[gd]
        fit_ind_eve=fit_ind[gd]
 	; Linear Fit - Changed to use linfit_phil.pro 8/17/05
	;linco=poly_fit(p_f107[fit_ind], see_data[k,fit_ind],1, chisq=chisq, yfit=yfit_l)
	linco=linfit_phil(p_f107[fit_ind_prox], eve_data[k,fit_ind_eve],chisq=chisq, yfit=yfit_l, $
		/stat_meas_errs)
	chisq_ar_f[0,k]=chisq
	stdv_f107_l=find_stdev(eve_data[k,fit_ind_eve], yfit_l)
	stdev_ar_f[*,0,k]=stdv_f107_l
	; Exp Fit - Fit as far as data will allow
	eve_exp_fit=reform(eve_data[k,fit_ind_eve])
	expco=expfit_phil(p_f107[fit_ind_prox],eve_exp_fit, chisqe)
	chisq_ar_f[1,k]=chisqe
	yfit_e=expco[0]*exp(expco[1]*p_f107[fit_ind_prox])+expco[2]
	stdv_f107_e=find_stdev(eve_exp_fit, yfit_e)
	stdev_ar_f[*,1,k]=stdv_f107_l
	; Quadratic Fit
	quadco=poly_fit(p_f107[fit_ind_prox], eve_data[k,fit_ind_eve],2, chisq=chisqq, yfit=yfit_q)
	chisq_ar_f[2,k]=chisqq
	stdv_f107_q=find_stdev(eve_data[k,fit_ind_eve], yfit_q)
	stdev_ar_f[*,2,k]=stdv_f107_l
	if keyword_set(plots) then begin
		!p.multi=[0,1,3]
		cc=independent_color()
		max_x=max(p_f107)
		titl_wv_tmp=strtrim(eve_wv[k],2)
		if eve_wv[k] lt 100 then titl_wv=strmid(titl_wv_tmp,0,4) else $
			titl_wv=strmid(titl_wv_tmp,0,5)
		plot, p_f107[fit_ind_prox], eve_data[k,fit_ind_eve]*1e5, psym=4, charsize=2.2, $;xr=[0,max_x], $
			title='WV= '+titl_wv+'nm', xtitle='F10.7'
		oplot, p_f107[fit_ind_prox], eve_data[k,fit_ind_eve]*1e5, psym=4, color=cc.green
		oplot, findgen(5), (linco[0]+linco[1]*findgen(5))*1e5, color=cc.red
		expx=findgen(500)*.01
		oplot, expx, (quadco[0]+quadco[1]*expx+$
			quadco[2]*(expx^2.))*1e5, color=cc.orange
		oplot, expx, (expco[0]*exp(expco[1]*expx)+expco[2])*1e5, color=cc.blue
		;if k eq 30 then stop
	endif
	min_max_sp_f107[1,k]=linco[0]  ; 62/62 - 1 = 0 -> y=b+a*0=b
	if min_max_sp_f107[1,k] le 0.0 then min_max_sp_f107[1,k]=mineve
	min_max_sp_f107[2,k]=linco[0]+linco[1]*((max_f107/min_f107)-1.)
	min_max_sp_f107_e[1,k]=expco[0]+expco[2]  ; 62/62 - 1 = 0 -> y=a+c
	if min_max_sp_f107_e[1,k] le 0.0 then min_max_sp_f107_e[1,k]=mineve
	min_max_sp_f107_e[2,k]=expco[0]*exp(expco[1]*((max_f107/min_f107)-1.))+$
		expco[2]
	min_max_sp_f107_q[1,k]=quadco[0]  ; 62/62 - 1 = 0 -> y=b+a*0+c*0^2=b
	if min_max_sp_f107_q[1,k] le 0.0 then min_max_sp_f107_q[1,k]=mineve
	min_max_sp_f107_q[2,k]=quadco[0]+quadco[1]*((max_f107/min_f107)-1.)$
		+quadco[2]*(((max_f107/min_f107)-1.)^2.)
	
	;
	;Find minimum for wv using mgii
	;
	; Lin fit
	;linco=poly_fit(p_mgii[fit_ind], see_data[k,fit_ind],1,chisq=chisq,yfit=yfit_l)
	fit2=where(p_mgii[fit_ind_prox] gt 0.0001 and p_mgii[fit_ind_prox] lt 1)
	linco=linfit_phil(p_mgii[fit_ind_prox[fit2]], eve_data[k,fit_ind_eve[fit2]],chisq=chisq,yfit=yfit_l, $
		/stat_meas_errs)
	chisq_ar_m[0,k]=chisq
	stdv_mgii_l=find_stdev(eve_data[k,fit_ind_prox[fit2]], yfit_l)
	stdev_ar_m[*,0,k]=stdv_mgii_l
	; Exp Fit - Fit as far as data will allow
	expco=expfit_phil(p_mgii[fit_ind_prox[fit2]],eve_exp_fit[fit2],chisqe)
	chisq_ar_m[1,k]=chisqe
	yfit_e=expco[0]*exp(expco[1]*p_mgii[fit_ind[fit2]])+expco[2]
	stdv_mgii_e=find_stdev(eve_exp_fit[fit2], yfit_e)
	stdev_ar_m[*,1,k]=stdv_mgii_e
	; Quadratic Fit
	quadco=poly_fit(p_mgii[fit_ind_prox[fit2]], eve_data[k,fit_ind_eve[fit2]],2,chisq=chisqq,yfit=yfit_q)
	chisq_ar_m[2,k]=chisqq
	stdv_mgii_q=find_stdev(eve_data[k,fit_ind_eve[fit2]], yfit_q)
	stdev_ar_m[*,2,k]=stdv_mgii_q
	if keyword_set(plots) then begin
		max_x=max(p_mgii)
		plot, p_mgii[fit_ind_prox[fit2]], eve_data[k,fit_ind_eve[fit2]]*1e5, psym=4, xs=1, charsize=2.2, $ ; xr=[0,max_x],
			ytitle='<E_d>108 (x 1e-5)', xtitle='MgII'
		oplot, mgii_sc_av[fit_ind_prox[fit2]], eve_sc_av[k,fit_ind_eve[fit2]]*1e5, psym=1, color=cc.light_blue
		oplot, p_mgii[fit_ind_prox[fit2]], eve_data[k,fit_ind_eve[fit2]]*1e5, psym=4, color=cc.green
		oplot, findgen(5), (linco[0]+linco[1]*findgen(5))*1e5, color=cc.red
		expx=findgen(500)*.001
		oplot, expx, (quadco[0]+quadco[1]*expx+$
			quadco[2]*(expx^2.))*1e5, color=cc.orange
		oplot, expx, (expco[0]*exp(expco[1]*expx)+expco[2])*1e5, color=cc.blue
		;if k eq 30 then stop
	endif
	min_max_sp_mgii[1,k]=linco[0]  ; min_mgii/min_mgii - 1 = 0 -> y=b+a*0=b
	if min_max_sp_mgii[1,k] le 0.0 then min_max_sp_mgii[1,k]=mineve
	min_max_sp_mgii[2,k]=linco[0]+linco[1]*((max_mgii/min_mgii)-1.)
	min_max_sp_mgii_e[1,k]=expco[0]+expco[2]  ; 62/62 - 1 = 0 -> y=a+c
	if min_max_sp_mgii_e[1,k] le 0.0 then min_max_sp_mgii_e[1,k]=mineve
	min_max_sp_mgii_e[2,k]=expco[0]*exp(expco[1]*((max_mgii/min_mgii)-1.))+$
		expco[2]
	min_max_sp_mgii_q[1,k]=quadco[0]  ; 62/62 - 1 = 0 -> y=b+a*0+c*0^2=b
	if min_max_sp_mgii_q[1,k] le 0.0 then min_max_sp_mgii_q[1,k]=mineve
	min_max_sp_mgii_q[2,k]=quadco[0]+quadco[1]*((max_mgii/min_mgii)-1.)$
		+quadco[2]*(((max_mgii/min_mgii)-1.)^2.)
	
	;
	;Find minimum for wv using lya 
	;
	; Lin Fit
	;linco=poly_fit(p_lya[fit_ind], see_data[k,fit_ind],1,chisq=chisq,yfit=yfit_l)
	linco=linfit_phil(p_lya[fit_ind_prox], eve_data[k,fit_ind_eve],chisq=chisq,yfit=yfit_l, $
		/stat_meas_errs)
	chisq_ar_l[0,k]=chisq
	stdv_lya_l=find_stdev(eve_data[k,fit_ind_eve], yfit_l)
	stdev_ar_l[*,0,k]=stdv_lya_l
	; Exp Fit - Fit as far as data will allow
	expco=expfit_phil(p_lya[fit_ind_prox],eve_exp_fit,chisqe)
	chisq_ar_l[1,k]=chisqe
	yfit_e=expco[0]*exp(expco[1]*p_lya[fit_ind])+expco[2]
	stdv_lya_e=find_stdev(eve_exp_fit, yfit_e)
	stdev_ar_l[*,1,k]=stdv_lya_e
	; Quadratic Fit
	quadco=poly_fit(p_lya[fit_ind_prox], eve_data[k,fit_ind_eve],2,chisq=chisqq,yfit=yfit_q)
	chisq_ar_l[2,k]=chisqq
	stdv_lya_q=find_stdev(eve_data[k,fit_ind], yfit_q)
	stdev_ar_l[*,2,k]=stdv_lya_q
	if keyword_set(plots) then begin
		max_x=max(p_lya[fit_ind])
		plot, p_lya[fit_ind_prox], eve_data[k,fit_ind_eve]*1e5, psym=4, xs=1,charsize=2.2,$ ; xr=[0,max_x], 
			xtitle='Lya'	
		oplot, p_lya[fit_ind_prox], eve_data[k,fit_ind_eve]*1e5, psym=4, color=cc.green
		oplot, findgen(100), (linco[0]+linco[1]*findgen(100))*1e5, color=cc.red
		expx=findgen(200)*.05
		oplot, expx, (quadco[0]+quadco[1]*expx+$
			quadco[2]*(expx^2.))*1e5, color=cc.orange
		oplot, expx, (expco[0]*exp(expco[1]*expx)+expco[2])*1e5, color=cc.blue
	endif
	min_max_sp_lya[1,k]=linco[0]  ; min_goes_log/min_goes_log - 1 = 0 -> y=b+a*0=b
	if min_max_sp_lya[1,k] le 0.0 then min_max_sp_lya[1,k]=mineve
	min_max_sp_lya[2,k]=linco[0]+linco[1]*((max_lya/min_lya)-1.)
	min_max_sp_lya_e[1,k]=expco[0]+expco[2]  ; min_lya/min_lya - 1 = 0 -> y=a+c
	if min_max_sp_lya_e[1,k] le 0.0 then min_max_sp_lya_e[1,k]=mineve
	min_max_sp_lya_e[2,k]=expco[0]*exp(expco[1]*((max_lya/min_lya)-1.))+$
		expco[2]
	min_max_sp_lya_q[1,k]=quadco[0]  ; min_lya/min_lya - 1 = 0 -> y=b+a*0+c*0^2=b
	if min_max_sp_lya_q[1,k] le 0.0 then min_max_sp_lya_q[1,k]=mineve
	min_max_sp_lya_q[2,k]=quadco[0]+quadco[1]*((max_lya/min_lya)-1.)$
		+quadco[2]*(((max_lya/min_lya)-1.)^2.)
	

	;	
	;	Fit using the SOHO SEM 26-34 nm proxy 
	;
	;fit_ind=where(eve_data[k,*] gt 0.0)
	;nfit_eve=n_elements(fit_ind)
	;fit_ind_sem=intarr(nfit_eve)
	;for i=0,nfit_eve-1 do begin
;		fit_ind_sem[i]=where(sem_dy eq eve_day_ar[fit_ind[i]])
;	endfor	
	
	; Define the Measurement Errors as a sqrt(abs(y)) for statistical weighting
	;meas_er=sqrt(abs(eve_data[k,fit_ind]))
	; Find minimum of SEE data for that wavelength (k) to use if extrapolation
	;	goes negative (use .99 of min see value to avoid divide by zero errors)
	;maxeve=max(eve_data[k,fit_ind],min=mineve)
	;mineve=mineve*0.99
	; Linear Fit
	;linco=poly_fit(p_sem[fit_ind_sem], see_data[k,fit_ind],1, chisq=chisq, yfit=yfit_l)
	;linco=linfit_phil(p_sem[fit_ind_sem], eve_data[k,fit_ind],chisq=chisq, yfit=yfit_l, $
	;	/stat_meas_errs)
	;chisq_ar_s[0,k]=chisq
	;stdv_sem_l=find_stdev(eve_data[k,fit_ind], yfit_l)
	;stdev_ar_s[*,0,k]=stdv_sem_l
	; Exp Fit - Fit as far as data will allow
	;eve_exp_fit=reform(eve_data[k,fit_ind])
	;expco=expfit_phil(p_sem[fit_ind_sem],eve_exp_fit, chisqe)
	;chisq_ar_s[1,k]=chisqe
	;yfit_e=expco[0]*exp(expco[1]*p_f107[fit_ind])+expco[2]
	;stdv_sem_e=find_stdev(eve_exp_fit, yfit_e)
	;stdev_ar_s[*,1,k]=stdv_sem_l
	; Quadratic Fit
	;quadco=poly_fit(p_sem[fit_ind_sem], eve_data[k,fit_ind],2, chisq=chisqq, yfit=yfit_q)
	;chisq_ar_s[2,k]=chisqq
	;stdv_sem_q=find_stdev(eve_data[k,fit_ind], yfit_q)
	;stdev_ar_s[*,2,k]=stdv_sem_l
	;if keyword_set(plots) then begin
	;	cc=independent_color()
	;	max_x=max(p_sem)
	;	titl_wv_tmp=strtrim(wv[k],2)
	;	if wv[k] lt 100 then titl_wv=strmid(titl_wv_tmp,0,4) else $
	;		titl_wv=strmid(titl_wv_tmp,0,5)
	;	plot, p_sem[fit_ind_sem], eve_data[k,fit_ind]*1e5, psym=4, charsize=2.2,xr=[0,max_x], $
	;		xtitle='SOHO SEM 26-34'
	;	oplot, p_sem[fit_ind_sem], eve_data[k,fit_ind]*1e5, psym=4, color=cc.green
	;	oplot, findgen(5), (linco[0]+linco[1]*findgen(5))*1e5, color=cc.red
	;	expx=findgen(500)*.01
	;	oplot, expx, (quadco[0]+quadco[1]*expx+$
	;		quadco[2]*(expx^2.))*1e5, color=cc.orange
	;	oplot, expx, (expco[0]*exp(expco[1]*expx)+expco[2])*1e5, color=cc.blue
	;	;if k eq 30 then stop
	;endif
	;min_max_sp_sem[1,k]=linco[0]  ; 62/62 - 1 = 0 -> y=b+a*0=b
	;if min_max_sp_sem[1,k] le 0.0 then min_max_sp_sem[1,k]=mineve
	;min_max_sp_sem[2,k]=linco[0]+linco[1]*((max_sem/min_sem)-1.)
	;min_max_sp_sem_e[1,k]=expco[0]+expco[2]  ; 62/62 - 1 = 0 -> y=a+c
	;if min_max_sp_sem_e[1,k] le 0.0 then min_max_sp_sem_e[1,k]=mineve
	;min_max_sp_sem_e[2,k]=expco[0]*exp(expco[1]*((max_sem/min_sem)-1.))+$
	;	expco[2]
	;min_max_sp_sem_q[1,k]=quadco[0]  ; 62/62 - 1 = 0 -> y=b+a*0+c*0^2=b
	;if min_max_sp_sem_q[1,k] le 0.0 then min_max_sp_sem_q[1,k]=mineve
	;min_max_sp_sem_q[2,k]=quadco[0]+quadco[1]*((max_sem/min_sem)-1.)$
	;	+quadco[2]*(((max_sem/min_sem)-1.)^2.)
	
	
	;if k eq 32 and psout ne 0 then open_ps, 'exp_f107it_33.ps'
	;if k eq 107 and psout ne 0 then open_ps, 'exp_f107it_108.ps'
	;if (k eq 33 or k eq 108) and psout ne 0 then close_ps
	;if keyword_set(eps_wv) then begin
	;	if k eq eps_wv then stop
	;endif  
	if keyword_set(plots) and not keyword_set(eps_wv) then read, ans, prompt='Next? '
	;if k eq 30 then stop
	;print, k
        bd_eve_data:
endfor

min_max_sp_f107[0,*]=eve_wv
min_max_sp_mgii[0,*]=eve_wv
min_max_sp_goes[0,*]=eve_wv
min_max_sp_lya[0,*]=eve_wv
min_max_sp_f107_e[0,*]=eve_wv
min_max_sp_mgii_e[0,*]=eve_wv
min_max_sp_goes_e[0,*]=eve_wv
min_max_sp_lya_e[0,*]=eve_wv
min_max_sp_f107_q[0,*]=eve_wv
min_max_sp_mgii_q[0,*]=eve_wv
min_max_sp_goes_q[0,*]=eve_wv
min_max_sp_lya_q[0,*]=eve_wv

if not keyword_set(debug) then begin
        save_pth = expand_path('$fism_save') 
  	print, 'Saving eve_min_sp_3.sav'
	save, min_max_sp_f107, min_max_sp_mgii, min_mgii, max_mgii, min_f107, max_f107, $
	eve_data, min_max_sp_goes, min_max_sp_mgii_e, $
	min_max_sp_f107_e, min_max_sp_goes_e, min_max_sp_mgii_q, $
	min_max_sp_f107_q, min_max_sp_goes_q, chisq_ar_m, chisq_ar_f, chisq_ar_g, $
	min_max_sp_lya, min_max_sp_lya_e, min_max_sp_lya_q, min_lya, max_lya, $
;	min_max_sp_sem, min_max_sp_sem_e, min_max_sp_sem_q, min_sem, max_sem, $
	stdev_ar_m, stdev_ar_f, stdev_ar_l, stdev_ar_s, $ ; min_goes, max_goes, $
	file=save_pth+'/eve_min_sp_3.sav'
endif else begin
	print, 'Keyword DEBUG set, not saving ...'
endelse

;stop
;plots=1
;psout=0
plt_wv_st=5
plt_wv_end=65

!p.multi=0

;
; Compare to WHI solar irradiance reference spectrum (Chamberlin et
; al, 2008; Woods et al., 2008)
;
if keyword_set(plots) or keyword_set(comp_plots) then begin
	if psout ne 0 then open_ps, '$fism_plots/min_max_sp_lin.ps'
	cc=independent_color()
        restore, '~/Reference\ Spectrum/whi_sol_ref_sp_2008.sav'

	plot_io, min_max_sp_f107[0,*], min_max_sp_f107[1,*], $
		psym=10, yr=[1e-7,1e-3], charsize=1.8,	ytitle='W/m^2/nm', xtitle='Wavelength (nm)', $
		title='Reference Spectra-Linear Fit', xr=[5,119], xs=1
	oplot, min_max_sp_mgii[0,*], min_max_sp_mgii[1,*], psym=10, color=cc.red
	;oplot, min_max_sp_mgii[0,*], min_max_sp_mgii[2,*], psym=10, color=cc.yellow
	;oplot, min_max_sp_f107[0,*], min_max_sp_f107[2,*], psym=10, color=cc.aqua
	oplot, min_max_sp_goes[0,*], min_max_sp_goes[1,*], psym=10, color=cc.green
	;oplot, min_max_sp_goes[0,*], min_max_sp_goes[2,*], psym=10, color=cc.orange
	oplot, sol_ref_sp[0,*], sol_ref_sp[1,*], color=cc.blue, psym=10
	xyouts, 50, 6e-4, 'Black: Min EVE/F10.7', charsize=2.0
	xyouts, 50, 4e-4, 'Red: Min EVE/MgII', charsize=2.0, color=cc.red
	xyouts, 50, 1.5e-4, 'Blue: WHI', charsize=2.0, color=cc.blue
	;xyouts, 50, 1.5e-3, 'Aqua: Max SEE/F10.7', charsize=1.6, color=cc.aqua
	;xyouts, 50, 1e-3, 'Yellow: Max SEE/MgII', charsize=1.6, color=cc.yellow
	xyouts, 50, 2.5e-4, 'Green: Min SEE/GOES', charsize=2.0, color=cc.green
	;xyouts, 50, 5e-4, 'Orange: Max SEE/GOES', charsize=1.6, color=cc.orange

	if psout ne 0 then close_ps
	read, ans, prompt='Exponential fit sepctra?'
	
	if psout ne 0 then open_ps, '$fism_plots/min_max_sp_exp.ps'
	plot_io, min_max_sp_f107_e[0,*], min_max_sp_f107_e[1,*], psym=10, yr=[1e-7,1e-3], charsize=1.8,$
		ytitle='W/m^2/nm', xtitle='Wavelength (nm)', xr=[5,119], xs=1, $
		title='Reference Spectra-Exponential Fit'
	oplot, min_max_sp_mgii_e[0,*], min_max_sp_mgii_e[1,*], psym=10, color=cc.red
	;oplot, min_max_sp_mgii_e[0,*], min_max_sp_mgii_e[2,*], psym=10, color=cc.yellow
	;oplot, min_max_sp_f107_e[0,*], min_max_sp_f107_e[2,*], psym=10, color=cc.aqua
	oplot, min_max_sp_goes_e[0,*], min_max_sp_goes_e[1,*], psym=10, color=cc.green
	;oplot, min_max_sp_goes_e[0,*], min_max_sp_goes_e[2,*], psym=10, color=cc.orange
	oplot, sol_ref_sp[0,*], sol_ref_sp[1,*], color=cc.blue, psym=10
	xyouts, 50, 6e-4, 'Black: Min EVE/F10.7', charsize=2.0
	xyouts, 50, 4e-4, 'Red: Min EVE/MgII', charsize=2.0, color=cc.red
	xyouts, 50, 1.5e-4, 'Blue: WHI', charsize=2.0, color=cc.blue
	;xyouts, 50, 1.5e-3, 'Aqua: Max SEE/F10.7', charsize=1.6, color=cc.aqua
	;xyouts, 50, 1e-3, 'Yellow: Max SEE/MgII', charsize=1.6, color=cc.green
	xyouts, 50, 2.5e-4, 'Green: Min SEE/GOES', charsize=2.0, color=cc.green
	;xyouts, 50, 5e-4, 'Orange: Max SEE/GOES', charsize=1.6, color=cc.orange

	if psout ne 0 then close_ps
	read, ans, prompt='Quadratic fit sepctra?'
	
	if psout ne 0 then open_ps, '$fism_plots/min_max_sp_quad.ps'
	plot_io, min_max_sp_f107_q[0,*], min_max_sp_f107_q[1,*], psym=10, yr=[1e-6,1e-3], charsize=1.8,$
		ytitle='W/m^2/nm', xtitle='Wavelength (nm)', xr=[5,119], xs=1, $
		title='Reference Spectra-Quadratic Fit'
	oplot, min_max_sp_mgii_q[0,*], min_max_sp_mgii_q[1,*], psym=10, color=cc.red
	;oplot, min_max_sp_mgii_q[0,*], min_max_sp_mgii_q[2,*], psym=10, color=cc.yellow
	;oplot, min_max_sp_f107_q[0,*], min_max_sp_f107_q[2,*], psym=10, color=cc.aqua
	oplot, min_max_sp_goes_q[0,*], min_max_sp_goes_q[1,*], psym=10, color=cc.green
	;oplot, min_max_sp_goes_q[0,*], min_max_sp_goes_q[2,*], psym=10, color=cc.orange
	oplot, sol_ref_sp[0,*], sol_ref_sp[1,*], color=cc.blue, psym=10
	xyouts, 50, 6e-4, 'Black: Min EVE/F10.7', charsize=2.0
	xyouts, 50, 4e-4, 'Red: Min EVE/MgII', charsize=2.0, color=cc.red
	xyouts, 50, 1.5e-4, 'Blue: WHI', charsize=1.6, color=cc.blue
	;xyouts, 50, 1.5e-3, 'Aqua: Max SEE/F10.7', charsize=1.6, color=cc.aqua
	;xyouts, 50, 1e-3, 'Yellow: Max SEE/MgII', charsize=1.6, color=cc.green
	xyouts, 50, 2.5e-4, 'Green: Min SEE/GOES', charsize=2.0, color=cc.green
	;xyouts, 50, 5e-4, 'Orange: Max SEE/GOES', charsize=1.6, color=cc.orange

	if psout ne 0 then close_ps
	read, ans, prompt='Lin fit Min Ratios?'

	!p.multi=[0,1,3]
	plot, min_max_sp_f107[0,*], min_max_sp_f107[1,*]/min_max_sp_mgii[1,*], $
		ytitle='SEE-F10.7/SEE-MgII', charsize=1.5, psym=10, $
		title='Ratios of Reference Spectra-Linfit', yr=[0,2]
	plot, min_max_sp_f107[0,*], min_max_sp_f107[1,*]/sol_ref_sp[1,*], $
		ytitle='SEE-F10.7/WHI', charsize=1.5, yr=[0,2], psym=10
	plot, min_max_sp_f107[0,*], min_max_sp_mgii[1,*]/sol_ref_sp[1,*], $
		ytitle='SEE-MgII/WHI', charsize=1.5, $
		xtitle='Wavelength (nm)', yr=[0,2], psym=10

	read, ans, prompt='Exp fit Min Ratios?'

	!p.multi=[0,1,3]
	plot, min_max_sp_f107_e[0,*], min_max_sp_f107_e[1,*]/min_max_sp_mgii_e[1,*], $
		ytitle='SEE-F10.7/SEE-MgII', charsize=1.5, psym=10, $
		title='Ratios of Reference Spectra-Exp Fit', yr=[0,2]
	plot, min_max_sp_f107_e[0,*], min_max_sp_f107_e[1,*]/min_data_sp, $
		ytitle='SEE-F10.7/VUV2002', charsize=1.5, yr=[0,2], psym=10
	plot, min_max_sp_f107[0,*], min_max_sp_mgii_e[1,*]/min_data_sp, $
		ytitle='SEE-MgII/VUV2002', charsize=1.5, $
		xtitle='Wavelength (nm)', yr=[0,2], psym=10

	read, ans, prompt='Quad fit Min Ratios?'

	!p.multi=[0,1,3]
	plot, min_max_sp_f107_q[0,*], min_max_sp_f107_q[1,*]/min_max_sp_mgii_q[1,*], $
		ytitle='SEE-F10.7/SEE-MgII', charsize=1.5, psym=10, $
		title='Ratios of Reference Spectra-Quad Fit', yr=[0,2]
	plot, min_max_sp_f107_q[0,*], min_max_sp_f107_q[1,*]/min_data_sp, $
		ytitle='SEE-F10.7/VUV2002', charsize=1.5, yr=[0,2], psym=10
	plot, min_max_sp_f107[0,*], min_max_sp_mgii_q[1,*]/min_data_sp, $
		ytitle='SEE-MgII/VUV2002', charsize=1.5, $
		xtitle='Wavelength (nm)', yr=[0,2], psym=10

	read, ans, prompt='Lin Fit Max/Min Ratios?'

	!p.multi=[0,1,3]
	plot, min_max_sp_f107[0,*], min_max_sp_f107[2,*]/min_max_sp_f107[1,*], $
		ytitle='F10.7: Max/Min', charsize=1.5, psym=10, yr=[0,15], $
		title='Max/Min Ratios of Reference Spectra-Lin Fit'	
	oplot, findgen(200), fltarr(200)+1., linestyle=2
	plot, min_max_sp_f107[0,*], min_max_sp_mgii[2,*]/min_max_sp_mgii[1,*], $
		ytitle='MgII: Max/Min', charsize=1.5, yr=[0,15], psym=10
	oplot, findgen(200), fltarr(200)+1., linestyle=2
	plot, min_max_sp_goes[0,*], min_max_sp_goes[2,*]/min_max_sp_goes[1,*], $
		ytitle='GOES: Max/Min', charsize=1.5, yr=[0,15], psym=10
	oplot, findgen(200), fltarr(200)+1., linestyle=2
	
	read, ans, prompt='Exp Fit Max/Min Ratios?'

	!p.multi=[0,1,3]
	plot, min_max_sp_f107_e[0,*], min_max_sp_f107_e[2,*]/min_max_sp_f107_e[1,*], $
		ytitle='F10.7: Max/Min', charsize=1.5, psym=10, yr=[0,15], $
		title='Max/Min Ratios of Reference Spectra-Exp Fit'	
	oplot, findgen(200), fltarr(200)+1., linestyle=2
	plot, min_max_sp_mgii_e[0,*], min_max_sp_mgii_e[2,*]/min_max_sp_mgii_e[1,*], $
		ytitle='MgII: Max/Min', charsize=1.5, yr=[0,15], psym=10
	oplot, findgen(200), fltarr(200)+1., linestyle=2
	plot, min_max_sp_goes_e[0,*], min_max_sp_goes_e[2,*]/min_max_sp_goes_e[1,*], $
		ytitle='GOES: Max/Min', charsize=1.5, yr=[0,15], psym=10
	oplot, findgen(200), fltarr(200)+1., linestyle=2
	
	read, ans, prompt='Quad Fit Max/Min Ratios?'

	!p.multi=[0,1,3]
	plot, min_max_sp_f107_q[0,*], min_max_sp_f107_q[2,*]/min_max_sp_f107_q[1,*], $
		ytitle='F10.7: Max/Min', charsize=1.5, psym=10, yr=[0,15], $
		title='Max/Min Ratios of Reference Spectra-Quad Fit'	
	oplot, findgen(200), fltarr(200)+1., linestyle=2
	plot, min_max_sp_mgii_q[0,*], min_max_sp_mgii_q[2,*]/min_max_sp_mgii_q[1,*], $
		ytitle='MgII: Max/Min', charsize=1.5, yr=[0,15], psym=10
	oplot, findgen(200), fltarr(200)+1., linestyle=2
	plot, min_max_sp_goes_q[0,*], min_max_sp_goes_q[2,*]/min_max_sp_goes_q[1,*], $
		ytitle='GOES: Max/Min', charsize=1.5, yr=[0,15], psym=10
	oplot, findgen(200), fltarr(200)+1., linestyle=2
	
	stop

endif
!p.multi=0

print, 'End Time create_min_sp: ', !stime

end
