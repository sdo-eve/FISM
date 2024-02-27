;+
; :Author: alpa3266 7/2019
; 
; FILE: fism_update_v2
; 
; PURPOSE: Run FISM V02 in update mode -> should only update last 60 days 
; 
; This will be called by a shell script in Jenkins
;-


pro fism_update_v2
 
 !path = !path+':'+Expand_Path('+/evenetapp/store1/fism/fism2/code/idl')
 ;!PATH = EXPAND_PATH('<IDL_DEFAULT>:+/evenetapp/store1/jenkins/workspace/FISM V02 Validation 2/code/idl:/evenetapp/store1/jenkins/workspace/FISM V02 Validation 2/code/idl/eveidl:/evenetapp/store1/jenkins/workspace/FISM V02 Validation 2/code/idl/utilities:/evenetapp/store1/jenkins/workspace/FISM V02 Validation 2/code/idl/datetime')

  ;fism_version
  
    ;read_noaa_fltxtx, f107_penticton_to_save, mgii_dat_to_save, lya_dat_to_save
    ;create_sc_sr_av, create_goes_daily_pred
  parallel_sprint_u, /to_save
  

  create_mgft_sc_av_pred
  
  find_3_prox_pred

    ;comp_fism_daily, comp_fism_Daily_fuv, comp_fism_daily_xuv
    ;/scsr_split
  parallel_sprint_u, /c_f_d_2
  

    ;concat_fism_daily, concat_fism_daily_fuv, concat_fism_daily_xuv
  parallel_sprint_u, /concat

  create_fism_daily_fuv, /update
  
  combine_fism_daily_v2, /update
  combine_fism_daily_v2, /update, /ncdf

  create_fism_eve_merged_daily, /alltags, /update  

  ; Update keyword leaves gaps at days d-60 to d-65ish, need to debug
  create_fism_merged_daily;, /update

  create_p_ip_p_gp, /update
  
  
    ;create_fism_hr_fuv, create_fism_hr_xuv
  parallel_sprint_u, /create_hr
  
  create_fism_fuv, /update

  comp_fism_flare, /update

  
  
  fism_daily_stan_bands, /update
  fism_daily_stan_bands, /update, /ncdf
  
  combine_fism_flare_v2, /update
  combine_fism_flare_v2, /update, /ncdf
  fism_flare_stan_bands, /update
  fism_flare_stan_bands, /update, /ncdf
  create_merged_netcdf
end
