;
; NAME: pred_eve_flares.pro
;
; PURPOSE: to use the coefficiants produced by 'reg_model.pro' and the input
;	f10.7, <f10.7>81, GOES long, and GOES' to predict the SEE 1nm resolution
;	spectrum.
;
; USAGE:
;	pred_sp=pred_see_v10(yyyydoy, utc, version=version)
;
; OUTPUT:  
;	pred_sp: the predicted see spectrum for the given day and time
;	wv: variable for the wavelength scale
;
; MODIFICATION HISTORY:
;	PCC 2/24/04	Program Creation, 'pred_see_flares.pro'
;	PCC 3/2/04	Added version number keyword
;	PCC 5/6/04	Made more general
;	PCC 5/27/04	Version 7 update
;	PCC 6/9/04	Eliminated wavelength input
;	PCC 7/25/04	Updated for v9
;	PCC 4/7/05	Added keyword /scav to return the sc/sr modeled spectrum
;	PCC 12/04/06	Updated for MacOSX
;
;       VERSION 2_01
;       PCC 7/23/12     Updated for SDO/EVE, 'pred_eve_flares.pro'
;
;+

function pred_eve_flares, yyyydoy, utc, grad_inc, imp_inc, sig_gp, sig_ip

common goes_data_com, goes_day, ychk, dychk, c_ip_c, sec_step_sh, $
   c_gp_c, pred_sp, clv_rat, clv_rat_ip, def_fl_loc, cent_cor_fact, $
   limb_cor_fact, clv_rat_lin, c_gp_c_lin, nwvs, med_gp_delay_time, $
   sigma_c_gp_c, sigma_c_ip_c, yer_c_ip, yer_c_gp


;yyyydoy=fix(yyyydoy,type=3)
pred_e_ip=fltarr(nwvs)
pred_e_gp=fltarr(nwvs)
sigma_gp=fltarr(nwvs)
sigma_ip=fltarr(nwvs)
   ;Find the average of the two GOES measurements on either side of the
   ;utc time
   utc_to_gps, yyyydoy, utc, gps_tm, /auto ;, gpsleap=13 ; make sure not in ssw
   ; Took out GP delay time here!!!
   gp_gps_tm=gps_tm             ; -ulong(med_gp_delay_time[k]) ; shift for GP time delay
   pre_inds=where(goes_day.time le gps_tm)
   pre_inds_gp=where(goes_day.time le gp_gps_tm)
   ; IP pre values
   if pre_inds[0] eq -1 then begin
	pre_meas_pri=0.
	pre_time=gps_tm
	fl_loc=def_fl_loc ; Set default
   endif else begin
	n_pre=n_elements(pre_inds)
	pre_meas_pri=goes_day[pre_inds[n_pre-1]].ip
	pre_time=goes_day[pre_inds[n_pre-1]].time
	fl_loc=goes_day[pre_inds[n_pre-1]].fl_loc
   endelse
   ; GP pre values
   if pre_inds_gp[0] eq -1 then begin
	maxgd=max(goes_day.gp,min=pre_meas)
	pre_meas_gp=pre_meas>0.0
	pre_time_gp=gp_gps_tm
	fl_loc=def_fl_loc ; Set default
   endif else begin
	n_pre=n_elements(pre_inds_gp)
	pre_meas_gp=goes_day[pre_inds_gp[n_pre-1]].gp>0.0
	pre_time_gp=goes_day[pre_inds_gp[n_pre-1]].time
	fl_loc=goes_day[pre_inds[n_pre-1]].fl_loc
   endelse
   ; IP post values
   post_inds=where(goes_day.time gt gps_tm)
   if post_inds[0] eq -1 then begin
	post_meas_pri=0.0
	post_time=gps_tm+1ul
   endif else begin
	post_meas_pri=goes_day[post_inds[0]].ip
	post_time=goes_day[post_inds[0]].time
	fl_loc=goes_day[post_inds[0]].fl_loc
   endelse
   ; GP post values 
   post_inds=where(goes_day.time gt gp_gps_tm)
   if post_inds[0] eq -1 then begin
	maxgd=max(goes_day.gp,min=post_meas_gp)
	post_time=gps_tm+1ul
   endif else begin
	post_meas_gp=goes_day[post_inds[0]].gp>0.0
	post_time_gp=goes_day[post_inds[0]].time
	fl_loc=goes_day[post_inds[0]].fl_loc
   endelse
     ; Find pre and post average 
     xint=[pre_time_gp,gp_gps_tm,post_time_gp]
     xval=[pre_time_gp,post_time_gp]
     yval=[pre_meas_gp,post_meas_gp]
     yint=interpol(yval,xval,xint)
     xint_pri=[pre_time,gps_tm,post_time]
     xval_pri=[pre_time,post_time]
     yval_pri=[pre_meas_pri,post_meas_pri]
     yint_pri=interpol(yval_pri,xval,xint)
     gs=yint[1]
     gs_pri=yint_pri[1]
     def_fl_loc=fl_loc
	
     ;
     ; Apply the CLV to the gp coefs
     ;

     gp_clv_cor_coef=clv_rat[0,*]+(cos(fl_loc*!pi/180.)*(1.-clv_rat[0,*]))
     gp_clv_cor_pow=clv_rat[1,*]+(cos(fl_loc*!pi/180.)*(1.-clv_rat[1,*]))
     ip_clv_cor_coef=clv_rat_ip[0,*]+(cos(fl_loc*!pi/180.)*(1.-clv_rat_ip[0,*]))
     ip_clv_cor_pow=clv_rat_ip[1,*]+(cos(fl_loc*!pi/180.)*(1.-clv_rat_ip[1,*]))

     for k=0,nwvs-1 do begin
        ; Find the increase in flux due to the gradual phase flare
        ;cgp=reform(cent_cor_fact*c_gp_c[1,*])*gp_clv_cor
        ; Find B1.0 equivalent to subtract off to 'zero' out offset
        b1sub=c_gp_c[1,k]*gp_clv_cor_coef[k]*(1.e-7^(c_gp_c[2,k]/gp_clv_cor_pow[k]))
        pred_e_gp[k]=(c_gp_c[1,k]*gp_clv_cor_coef[k]*(gs^(c_gp_c[2,k]/gp_clv_cor_pow[k]))-b1sub)>0.0
        ;plus_1sig=(c_gp_c[1,k]+sigma_c_gp_c[1,k])*gp_clv_cor_coef[k]*(gs^((c_gp_c[2,k]+sigma_c_gp_c[2,k])*gp_clv_cor_pow[k]))
        ;plus_1sig=(gp_clv_cor_coef[k]*sigma_c_gp_c[1,k])*(gs^(sigma_c_gp_c[2,k]/gp_clv_cor_pow[k]))
        ;sigma_gp[k]=(plus_1sig-pred_e_gp[k])>0.0
        sigma_gp[k]=(yer_c_gp[k]*pred_e_gp[k])>0.0
        ;print, yer_c_gp[k], pred_e_gp[k], sigma_gp[k]
        ; Find the increase in flux due to the impulsive phase flare
        ; Find ~B1.0 equivalent to subtract off to 'zero' out offset
        b1sub_ip=c_ip_c[1,k]*ip_clv_cor_coef[k]*(1.e-10^((c_ip_c[2,k])/ip_clv_cor_pow[k]))
        pred_e_ip[k]=(c_ip_c[1,k]*ip_clv_cor_coef[k]*(gs_pri^((c_ip_c[2,k])/ip_clv_cor_pow[k]))-b1sub_ip)>0.0
        ;plus_1sig_ip=(ip_clv_cor_coef[k]*sigma_c_ip_c[1,k])*(gs_pri^(sigma_c_ip_c[2,k]/ip_clv_cor_pow[k]))
        ;sigma_ip[k]=(plus_1sig_ip-pred_e_ip[k])>0.0
        sigma_ip[k]=(yer_c_ip[k]*pred_e_ip[k])>0.0
        ;print, yer_c_ip[k], pred_e_ip[k], sigma_ip[k]
        ;stop
     endfor

; Add imp and grad flare contributions to return
flr_cont=pred_e_ip+pred_e_gp


; Popluate imp and grad arrays to return via function in/out arrays
grad_inc=pred_e_gp
imp_inc=pred_e_ip
sig_gp=sigma_gp
sig_ip=sigma_ip

;stop

return, flr_cont

end

