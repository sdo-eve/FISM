;
; NAME: linfit_phil.pro
;
; PURPOSE: to get the average linear fit coeficient and constant in fitting 
;	x/y and y/x (See p.13 of FISM v2 notebook)
;
; MODIFICATION HISTORY:
;	8/17/05	PCC	Program Creation
;
; NOTE: if keyword '/stat_meas_errs' is set, then the statistical measurement
;	errors are used (sqrt(abs(IV)) for each independent variable (IV)
;

function linfit_phil, x, y, measure_errors=measure_errors, yfit=yfit, $
	chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
	stat_meas_errs=stat_meas_errs, two_sig=two_sig, low_cut=low_cut
	

;
; Fit x as dependent and y as independent
;
if keyword_set(low_cut) then begin
	xsrt=x[sort(x)]
	nx=n_elements(x)
	xcut=xsrt[fix(nx*low_cut*0.01)]
	ysrt=y[sort(y)]
	ny=n_elements(y)
	ycut=ysrt[fix(ny*low_cut*0.01)]
	wcut=where(y lt ycut); and x lt xcut)
	x=x[wcut]
	y=y[wcut]
	;stop
endif
if keyword_set(stat_meas_errs) then begin
	lcoefs_2=linfit(reform(y),x,measure_errors=sqrt(abs(x)),  $
		chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
		yfit=yfit1)
	
	lcoefs_1=linfit(x,y,measure_errors=sqrt(abs(y)),  $
		chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
		yfit=yfit2)
endif else begin	
	lcoefs_2=linfit(y,x,measure_errors=measure_errors,  $
		chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
		yfit=yfit2)
	
	lcoefs_1=linfit(x,y,measure_errors=measure_errors,  $
		chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
		yfit=yfit1)
endelse

if keyword_set(two_sig) then begin ; Eliminate the values >2sig and redo fit
	stdev1=sqrt((total((yfit1-y)^2.))/n_elements(y))
	stdev2=sqrt((total((yfit2-x)^2.))/n_elements(x))
	gd=where((y-yfit1) gt (-1)*2.*stdev1 and (y-yfit1) lt 2.*stdev1 and $
		(x-yfit2) gt (-1)*2.*stdev2 and (x-yfit2) lt 2.*stdev2)
	if keyword_set(stat_meas_errs) then begin
		lcoefs_2=linfit(y[gd],x[gd],measure_errors=sqrt(abs(x[gd])),  $
			chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
			yfit=yfit1)
	
		lcoefs_1=linfit(x[gd],y[gd],measure_errors=sqrt(abs(y[gd])),  $
			chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
			yfit=yfit2)
	endif else begin	
		lcoefs_2=linfit(y[gd],x[gd],measure_errors=measure_errors,  $
			chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
			yfit=yfit2)
	
		lcoefs_1=linfit(x[gd],y[gd],measure_errors=measure_errors,  $
			chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
			yfit=yfit1)
	endelse
	
	; Repeat to again eliminate 2sig values in original fit
	stdev1=sqrt((total((yfit1-y[gd])^2.))/n_elements(y[gd]))
	stdev2=sqrt((total((yfit2-x[gd])^2.))/n_elements(x[gd]))
	gd2=where((y[gd]-yfit1) gt (-1)*2.*stdev1 and (y[gd]-yfit1) lt 2.*stdev1 and $
		(x[gd]-yfit2) gt (-1)*2.*stdev2 and (x[gd]-yfit2) lt 2.*stdev2)
	if keyword_set(stat_meas_errs) then begin
		lcoefs_2=linfit(y[gd[gd2]],x[gd[gd2]],measure_errors=sqrt(abs(x[gd[gd2]])),  $
			chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
			yfit=yfit1)
	
		lcoefs_1=linfit(x[gd[gd2]],y[gd[gd2]],measure_errors=sqrt(abs(y[gd[gd2]])),  $
			chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
			yfit=yfit2)
	endif else begin	
		lcoefs_2=linfit(y[gd[gd2]],x[gd[gd2]],measure_errors=measure_errors,  $
			chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
			yfit=yfit2)
	
		lcoefs_1=linfit(x[gd[gd2]],y[gd[gd2]],measure_errors=measure_errors,  $
			chisq=chisq, covar=covar, prob=prob, sigma=sigma, $
			yfit=yfit1)
	endelse

endif
		
		
;
; Average the coefs (see p.13 of FISM v2 for explanation)
;
m=(lcoefs_1[1]+(1./lcoefs_2[1]))/2.
b=(lcoefs_1[0]+((-1)*lcoefs_2[0]/lcoefs_2[1]))/2.

av_coefs=[b,m]

; Make a yfit to return
yfit=av_coefs[0]+av_coefs[1]*x

return, av_coefs

end


	


