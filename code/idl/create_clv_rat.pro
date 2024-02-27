;
; NAME: create_clv_rat.pro
;
; PURPOSE: to find the CLV flare ratio 
;
; MODIFICATION HISTORY:
;	PCC	6/14/05	Program Creation
;	PCC	7/12/05	Change ratio to L/C instead of C/L
;	PCC	12/04/06 Updated for MacOSX
;
;       VERSION 02_01
;       PCC     7/17/12   Updated for SDO/EVE
;       PCC     7/23/12   Added IP along with GP, and both coef and power now
;       PCC     7/30/12   Limited ratio to be <1.0 - no center to limb brightening

pro create_clv_rat, debug=debug

print, 'Running crate_clv_rat.pro ', !stime

;
; Gradual Phase
;
restore, expand_path('$fism_save')+'/c_gp.sav'

cent_cor_fact=1.0; 1.06
limb_cor_fact=1.0; 0.83
clv_rat_coef=reform((c_gp_l[1,*]*limb_cor_fact)/(c_gp_c[1,*]*cent_cor_fact))
clv_rat_pow=reform((c_gp_l[2,*]*limb_cor_fact)/(c_gp_c[2,*]*cent_cor_fact))

; Force bad CLV ratios of 0, Inf or NAN to be 1 (as in no corretion made)
gd=where(clv_rat_coef gt 0.0 and clv_rat_coef lt 100.0 and clv_rat_pow gt 0.0 and clv_rat_pow lt 100.0)
clv_rat_tmp=fltarr(2,n_elements(clv_rat_coef))+1.0 ; define array
clv_rat_tmp[0,gd]=clv_rat_coef[gd]<1.0 ; set good values to actual values
clv_rat_tmp[1,gd]=clv_rat_pow[gd]<1.0 ; set good values to actual values
clv_rat=clv_rat_tmp 

;
; Impulsive Phase
;

restore, expand_path('$fism_save')+'/c_ip.sav'

clv_rat_coef=reform((c_ip_l[1,*]*limb_cor_fact)/(c_ip_c[1,*]*cent_cor_fact))
clv_rat_pow=reform((c_ip_l[2,*]*limb_cor_fact)/(c_ip_c[2,*]*cent_cor_fact))

; Force bad CLV ratios of 0, Inf or NAN to be 1 (as in no corretion made)
gd=where(clv_rat_coef gt 0.0 and clv_rat_coef lt 100.0 and clv_rat_pow gt 0.0 and clv_rat_pow lt 100.0)
clv_rat_tmp=fltarr(2,n_elements(clv_rat_coef))+1.0 ; define array
clv_rat_tmp[0,gd]=clv_rat_coef[gd]<1.0 ; set good values to actual values
clv_rat_tmp[1,gd]=clv_rat_pow[gd]<1.0 ; set good values to actual values
clv_rat_ip=clv_rat_tmp 


if keyword_set(debug) then begin
   print, 'Debug keyword set, not saving!!!'
   stop
endif else begin
   print, 'Saving clv_rat.sav'
   save, clv_rat, clv_rat_ip, cent_cor_fact, limb_cor_fact, file=expand_path('$fism_save')+'/clv_rat.sav'
endelse

print, 'End Time create_clv_rat: ', !stime

end
