;+
; :Author: alpa3266 7/2019
; FILE:Parallel_sprint_1
; 
; PURPOSE: Store all the different sets of parallel processing for FISM V02
; 
; CALL: parallel_sprint, /two 
; The keyword used tells which sprint will be run 
; '
; 
; INFORMATION ABOUT HOW IT WORKS:
; Keywords are based off the files they run when called
; 
; This file uses the IDL_IDLBRIDGE objects, which allow for parallel processing
; within IDL
; Each object runs a child process that runs in another IDL instance 
; For Example:
;       obj = OBJ_NEW('IDL_IDLBridge', output = '')
;       obj->Execute, 'read_noaa_flrtxt, /allyear', /nowait
; 
; obj is the name given to store the bridge object
; Child processes do not normally print their log, 
; Setting the output = '' causes it to print to the console, this can also
;   be given a file name to print to 
; 
; The execute command tells the child process to carry out an execution, the file
;   and any keywords or parameters need to be in the single quotes, 
; The /nowait keyword allows the parent process to continue running 
;   before the child process finishes, which in this file, allows more 
;   child processes to be made
;-

pro parallel_sprint, to_save=to_save, t_p_n=t_p_n, f_c_sol=f_c_sol, f_c_xps=f_c_xps, a_f_c=a_f_c, $
  c_f_d_1=c_f_d_1, daily_error=daily_error, c_f_d_2=c_f_d_2, backup_prox=backup_prox, $
  concat=concat, daily_fuv=daily_fuv, s_goes_comp=s_goes_comp,$
  f_days_comp=f_days_comp, c_f_f_1=c_f_f_1, c_f_f_2=c_f_f_2, create_hr=create_hr, p=p, $
  q=q, r=r, c_f_f_3=c_f_f_3

objs = MAKE_ARRAY(12, 1, /OBJ)
;create the bridge objects, a max of 12 are used at once and only for files 
;that run very fast
for i = 0, 11 do begin $
  obj = OBJ_NEW('IDL_IDLBridge', output = '')
  obj->Execute, '!path = !path+":"+Expand_Path("+/evenetapp/store1/fism/fism2/code/idl")'
  objs[i] = obj
endfor
print, '  '

;print, objs
if keyword_set(to_save) then begin
  objs[0]->Execute, 'read_noaa_flrtxt, /allyear', /nowait
  objs[1]->Execute, 'f107_penticton_to_save', /nowait
  objs[2]->Execute, 'mgii_dat_to_save', /nowait 
  objs[3]->Execute, 'lya_dat_to_save', /nowait 
  objs[4]->Execute, 'create_sc_sr_av, /cent_av', /nowait 
  objs[5]->Execute, 'sem_txt_to_sav', /nowait
  objs[6]->Execute, 'create_goes_daily_pred'

endif 

if keyword_set(t_p_n) then begin
  ;creates a bridge to run the process
  ;the output being an empty string will print to the console
  objs[0]->Execute, 'three_prox_noscsr, tag=1', /nowait
  objs[1]->Execute, 'three_prox_noscsr, tag=2', /nowait
  objs[2]->Execute, 'three_prox_noscsr, tag=3', /nowait
  objs[3]->Execute, 'three_prox_noscsr, tag=4', /nowait
  objs[4]->Execute, 'three_prox_noscsr, tag=5', /nowait
  objs[5]->Execute, 'three_prox_noscsr, tag=6', /nowait
  objs[6]->Execute, 'three_prox_noscsr, tag=7', /nowait
  objs[7]->Execute, 'three_prox_noscsr, tag=8', /nowait
  objs[8]->Execute, 'three_prox_noscsr, tag=9', /nowait
  objs[9]->Execute, 'three_prox_noscsr, tag=10', /nowait
  objs[10]->Execute, 'three_prox_noscsr, tag=11', /nowait
  objs[11]->Execute, 'three_prox_noscsr, tag=12'
endif

if keyword_set(f_c_sol) then begin
  objs[0]->Execute, 'find_fuv_c_sol, tag=0', /nowait
  objs[1]->Execute, 'find_fuv_c_sol, tag=1', /nowait
  objs[2]->Execute, 'find_fuv_c_sol, tag=2'
 
endif

if keyword_set(f_c_xps) then begin
  objs[0]->Execute, 'find_xuv_c_xps, tag=1', /nowait
  objs[1]->Execute, 'find_xuv_c_xps, tag=2', /nowait
  objs[2]->Execute, 'find_xuv_c_xps, tag=3', /nowait
  objs[3]->Execute, 'find_xuv_c_xps, tag=4', /nowait
  objs[4]->Execute, 'find_xuv_c_xps, tag=5', /nowait
  objs[5]->Execute, 'find_xuv_c_xps, tag=6', /nowait
  
  objs[6]->Execute, 'find_xuv_c_xps, tag=8', /nowait
  objs[7]->Execute, 'find_xuv_c_xps, tag=10', /nowait
  objs[8]->Execute, 'find_xuv_c_xps, tag=11', /nowait
  objs[9]->Execute, 'find_xuv_c_xps, tag=12', /nowait
  objs[10]->Execute, 'find_xuv_c_xps, tag=9', /nowait
  objs[11]->Execute, 'find_xuv_c_xps, tag=7'
  

endif

if keyword_set(a_f_c) then begin
  objs[0]->Execute, 'an_fit_coefs', /nowait
  objs[1]->Execute, 'an_fit_coefs_xuv', /nowait
  objs[2]->Execute, 'an_fit_coefs_fuv'
  wait, 5
 
endif

if keyword_set(c_f_d_1) then begin
  objs[0]->Execute, 'comp_fism_daily, scsr_split=1, preerr=1', /nowait
  objs[1]->Execute, 'comp_fism_daily_xuv, scsr_split=1, preerr=1', /nowait
  objs[2]->Execute, 'comp_fism_daily_fuv, scsr_split=1, preerr=1'
endif

if keyword_set(daily_error) then begin
  objs[0]->Execute, 'find_daily_error_xuv', /nowait
  objs[1]->Execute, 'find_daily_error', /nowait
  objs[2]->Execute, 'find_daily_error_fuv'
endif

if keyword_set(c_f_d_2) then begin
  objs[0]->Execute, 'comp_fism_daily_fuv, scsr_split=1', /nowait
  objs[1]->Execute, 'comp_fism_daily_xuv, scsr_split=1', /nowait
  objs[2]->Execute, 'comp_fism_daily, scsr_split=1'
endif

if keyword_Set(backup_prox) then begin
  objs[2]->Execute, 'make_backup_best_proxy_xuv', /nowait
  objs[0]->Execute, 'make_backup_best_proxy', /nowait
  objs[1]->Execute, 'make_backup_best_proxy_fuv'
  
endif

if keyword_set(concat) then begin
  objs[0]->Execute, 'concat_fism_daily_xuv', /nowait
  objs[1]->Execute, 'concat_fism_daily', /nowait
  objs[2]->Execute, 'concat_fism_daily_fuv'
  
endif

if keyword_set(s_goes_comp) then begin
  objs[0]->Execute, 'solstice_goes_comp, st_wv=115.00 , end_wv=124.00, /no_ip_sub', /nowait
  objs[1]->Execute, 'solstice_goes_comp, st_wv=124.00 , end_wv=133.00, /no_ip_sub', /nowait
  objs[2]->Execute, 'solstice_goes_comp, st_wv=133.00 , end_wv=142.00, /no_ip_sub', /nowait
  objs[3]->Execute, 'solstice_goes_comp, st_wv=142.00 , end_wv=151.00, /no_ip_sub', /nowait
  objs[4]->Execute, 'solstice_goes_comp, st_wv=151.00 , end_wv=160.00, /no_ip_sub', /nowait
  objs[5]->Execute, 'solstice_goes_comp, st_wv=160.00 , end_wv=169.00, /no_ip_sub', /nowait
  objs[6]->Execute, 'solstice_goes_comp, st_wv=169.00 , end_wv=178.00, /no_ip_sub', /nowait
  objs[7]->Execute, 'solstice_goes_comp, st_wv=178.00 , end_wv=189.93, /no_ip_sub'
  
endif

if keyword_Set(f_days_comp) then begin
  objs[0]->Execute, 'process_fism_flare_days', /nowait
  objs[1]->Execute, 'solstice_xps_goes_comp, /no_ip_sub'
endif

if keyword_set(create_hr) then begin 
  objs[0]->Execute, 'create_fism_hr_xuv', /nowait
  objs[1]->Execute, 'create_fism_hr_fuv'
endif

;comp_fism_flare shoudl only be run by itself in parallel, it will take many
;days to complete, new years will need to be added to the end
;if keyword_set(p) then begin
;  objs[0]->Execute, 'comp_fism_flare, start_yd=1982002, end_yd=1982365', /nowait
;  objs[1]->Execute, 'comp_fism_flare, start_yd=1983001, end_yd=1983365', /nowait
;  objs[2]->Execute, 'comp_fism_flare, start_yd=1984001, end_yd=1984366', /nowait
;  objs[3]->Execute, 'comp_fism_flare, start_yd=1985001, end_yd=1985365', /nowait
;  objs[4]->Execute, 'comp_fism_flare, start_yd=1986001, end_yd=1986365', /nowait
;  objs[5]->Execute, 'comp_fism_flare, start_yd=1987001, end_yd=1987365', /nowait
;  objs[6]->Execute, 'comp_fism_flare,  start_yd=1988001, end_yd=1988366', /nowait
;  objs[7]->Execute, 'comp_fism_flare, start_yd=1989001, end_yd=1989365'
;endif

;if keyword_set(q) then begin
;  objs[0]->Execute, 'comp_fism_flare, start_yd=1990001, end_yd=1990365', /nowait
;  objs[1]->Execute, 'comp_fism_flare, start_yd=1991001, end_yd=1991365', /nowait
;  objs[2]->Execute, 'comp_fism_flare, start_yd=1992001, end_yd=1992366', /nowait
;  objs[3]->Execute, 'comp_fism_flare, start_yd=1993001, end_yd=1993365', /nowait
;  objs[4]->Execute, 'comp_fism_flare, start_yd=1994001, end_yd=1994365', /nowait
;  objs[5]->Execute, 'comp_fism_flare, start_yd=1995001, end_yd=1995365', /nowait
;  objs[6]->Execute, 'comp_fism_flare, start_yd=1996001, end_yd=1996366', /nowait
;  objs[7]->Execute, 'comp_fism_flare, start_yd=1997001, end_yd=1997365'
;endif

;if keyword_set(r) then begin
  ;objs[0]->Execute, 'comp_fism_flare, start_yd=1998001, end_yd=1998365', /nowait
  ;objs[1]->Execute, 'comp_fism_flare, start_yd=1999001, end_yd=1999365', /nowait
  ;objs[2]->Execute, 'comp_fism_flare, start_yd=2000001, end_yd=2000366', /nowait
  
  ;objs[4]->Execute, 'comp_fism_flare, start_yd=2001001, end_yd=2001365', /nowait
  ;objs[5]->Execute, 'comp_fism_flare, start_yd=2002001, end_yd=2002365', /nowait
  
;endif

if keyword_set(c_f_f_1) then begin
  objs[5]->Execute, 'comp_fism_flare, start_yd=2003001, end_yd=2003365', /nowait
  objs[6]->Execute, 'comp_fism_flare, start_yd=2004001, end_yd=2004366', /nowait
  objs[7]->Execute, 'comp_fism_flare, start_yd=2005001, end_yd=2005365', /nowait
  objs[0]->Execute, 'comp_fism_flare, start_yd=2006001, end_yd=2006365', /nowait
  objs[1]->Execute, 'comp_fism_flare, start_yd=2007001, end_yd=2007365', /nowait
  objs[2]->Execute, 'comp_fism_flare, start_yd=2008001, end_yd=2008366', /nowait
  objs[3]->Execute, 'comp_fism_flare, start_yd=2009001, end_yd=2009365', /nowait
  objs[4]->Execute, 'comp_fism_flare, start_yd=2010001, end_yd=2010365'
  
endif

if keyword_set(c_f_f_2) then begin
  objs[6]->Execute, 'comp_fism_flare, start_yd=2011001, end_yd=2011365', /nowait
  objs[7]->Execute, 'comp_fism_flare, start_yd=2012001, end_yd=2012366', /nowait
  objs[0]->Execute, 'comp_fism_flare, start_yd=2013001, end_yd=2013365', /nowait
  objs[1]->Execute, 'comp_fism_flare, start_yd=2014001, end_yd=2014365', /nowait
  objs[2]->Execute, 'comp_fism_flare, start_yd=2015001, end_yd=2015365', /nowait
  objs[3]->Execute, 'comp_fism_flare,start_yd=2016001, end_yd=2016366', /nowait
  objs[4]->Execute, 'comp_fism_flare,start_yd=2017001, end_yd=2017365', /nowait
  objs[5]->Execute, 'comp_fism_flare,start_yd=2018001, end_yd=2018365'
  
endif

if keyword_set(c_f_f_3) then begin
  objs[0]->Execute, 'comp_fism_flare, start_yd=2021001', /nowait
  objs[1]->Execute, 'comp_fism_flare, start_yd=2019001, end_yd=2019365', /nowait
  objs[2]->Execute, 'comp_fism_flare, start_yd=2020001, end_yd=2020366'
  
  ;new years need to be added here up to eight
endif

if keyword_set(daily_fuv) then begin 
 objs[0]->Execute, 'create_fism_daily_fuv, styr=1947, doy=045, edyr=1957, eddoy=365', /nowait
 objs[1]->Execute, 'create_fism_daily_fuv, styr=1958, doy=001, edyr=1967, eddoy=365', /nowait
 objs[2]->Execute, 'create_fism_daily_fuv, styr=1968, doy=001, edyr=1977, eddoy=365', /nowait
 objs[3]->Execute, 'create_fism_daily_fuv, styr=1978, doy=001, edyr=1987, eddoy=365', /nowait
 objs[4]->Execute, 'create_fism_daily_fuv, styr=1988, doy=001, edyr=1997, eddoy=365', /nowait
 objs[5]->Execute, 'create_fism_daily_fuv, styr=1998, doy=001, edyr=2007, eddoy=365', /nowait
 objs[6]->Execute, 'create_fism_daily_fuv, styr=2008, doy=001, edyr=2017, eddoy=365', /nowait
 objs[7]->Execute, 'create_fism_daily_fuv, styr=2018, doy=001'
endif 

;destory the objects to avoid memory leaks
;only destory if it is finished
ndone = 0 
while ndone lt 12 do begin 
  for z = 0, 11 do begin
    if OBJ_VALID(objs[z]) then begin
      if (objs[z]->Status() ne 1) then begin
        ;print, "Freeing "  + string(z);
        OBJ_DESTROY, objs[z]
        ndone++ 
      endif
    endif
  endfor
  wait, 5
endwhile 

end
