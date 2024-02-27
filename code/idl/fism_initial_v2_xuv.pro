;+
; :Author: alpa3266 7/2019
;    P. Chamberlin 2/11/2021 - Updated to break out xuv processing only
; 
; FILE:fism_initial_v2_xuv
; 
; PURPOSE: Run all the files needed for the initial run of FISM V02 in
; XUV wavelengths.  To be run when a new version of SORCE/XPS/L4 is released
; 
; This file should be called by a shell script through Jenkins 
;-


pro fism_initial_v2_xuv, ns=ns

    !path = !path+':'+Expand_Path('+/evenetapp/store1/fism/fism2/code/idl')
    if keyword_set(ns) then goto, new_start
    
    ;print, !path
      ;create the version files used later
    ;fism_version
    ;eve_version
    
      ;read_noaa_flrtxt, f107_penticton_to_save, mgii_dat_to_save, lya_dat_to_save
      ;create_sc_sr_av, create_goes_daily_pred
    parallel_sprint, /to_save
    
    create_mgft_sc_av_pred
    find_3_prox_1
    ;create_min_sp, /sc_av
    ;concat_min_sp
    find_3_prox_2
    find_3_prox_pred
    ;find_e_sc_e_sr
    ;find_e_sc_e_sr

    find_e_sc_e_sr_xuv
    
      ;three_prox_no_scsr tags 1-12
    ;parallel_sprint, /t_p_n
    
      ;find_fuv_c_sol tags 0-2
    ;parallel_sprint, /f_c_sol
    
      ;find_xuv_c_xps tags 1-12
    parallel_sprint, /f_c_xps
    
      ;an_fit_coefs, an_fit_coefs_fuv, an_fit_coefs_xuv
    ;parallel_sprint, /a_f_c
    an_fit_coefs_xuv
    
      ;comp_fism_daily, comp_fism_daily_fuv, comp_fism_daily_xuv
      ;/scsr_split, /preerr
    ;parallel_sprint, /c_f_d_1
    comp_fism_daily_xuv, scsr_split=1, preerr=1
    
    find_meas_errors
    
      ;find_daily_error, find_daily_error_fuv, find_daily_error_xuv
    ;parallel_sprint, /daily_error
    find_daily_error_xuv
    
      ;comp_fism_daily, comp_fism_Daily_fuv, comp_fism_daily_xuv
       ;/scsr_split
    ;parallel_sprint, /c_f_d_2
    comp_fism_daily_xuv, scsr_split=1
    
      ;make_backup_best_proxy, make_backup_best_proxy_xuv, make_backup_best_proxy_fuv
    ;parallel_sprint, /backup_prox
    make_backup_best_proxy_xuv
      
      ;concat_fism_daily, concat_fism_daily_fuv, concat_fism_daily_xuv
    ;parallel_sprint, /concat
    concat_fism_daily_xuv
    
    ;create_fism_eve_merged_daily, /alltags ; can remove once debugging is done
    ;create_fism_xuv_merged_daily, /alltags ; can remove once debugging is done
    
      ;create_fism_daily_fuv in parallel
    parallel_sprint, /daily_fuv 
    
    
    combine_fism_daily_v2 
    combine_fism_daily_v2, /ncdf
    
    create_fism_merged_daily
    
    create_p_ip_p_gp
    
      ;Likely only needs to run once since there will not be new data to pull
    ;get_eve_l2_flare_data
    
    
    ;get_eve_l2_flare_data, year=2011, doy=027 ;added because current data doesnt pull this day
          
      ;must compile the whoel file so that the other processes are compiled
      ;if this stops working, moving the other processes to the top of the file 
      ;before the main call should also solve the problem 
    ;RESOLVE_ROUTINE, 'find_ip_gp_powerfunct_eve', /compile_full_file
    ;find_ip_gp_powerfunct_eve, /find_cpow
   
    ;create_clv_rat
    
      ;solstice_goes_comp 115-189.9 nm in 10nm splits
    ;parallel_sprint, /s_goes_comp
      ;process_fism_flare_days, solstice_xps_goes_comp
    
    new_start:  
    solstice_xps_goes_comp, /no_ip_sub
    
    ;process_fism_flare_days
      ;create_fism_hr_fuv, create_fism_hr_xuv
    ;parallel_sprint, /create_hr
    create_fism_hr_xuv

    ;create_fism_fuv
    
    ;find_flare_error
    
     
      ;comp_fism_flare 2003-2010
    ;parallel_sprint, /c_f_f_1
    
      ;comp_fism_flare 2011-2018
    ;parallel_sprint, /c_f_f_2
    
      ;comp_fism_flare 2019-2021+
    ;parallel_sprint, /c_f_f_3
    
    
   
    combine_fism_flare_v2
    combine_fism_flare_v2, /ncdf
    fism_daily_stan_bands
    fism_daily_stan_bands, /ncdf
    fism_flare_stan_bands
    fism_flare_stan_bands, /ncdf
    create_merged_netcdf
end
