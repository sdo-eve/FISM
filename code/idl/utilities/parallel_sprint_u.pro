;+
; :Author: alpa3266 7/2019
; FILE:Parallel_sprint_update
; 
; PURPOSE: Store all the different sets of parallel processing for FISM V02 in update mode
; 
; CALL: parallel_sprint_u, /two 
; The keyword used tells which sprint will be run 
; '
; 
; INFORMATION ABOUT HOW IT WORKS:
; Keywords are based off of the files that are run when they are called 
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

pro parallel_sprint_u, to_save=to_save, c_f_d_2=c_f_d_2, concat=concat, create_hr=create_hr

objs = MAKE_ARRAY(12, 1, /OBJ)
;create the bridge objects, a max of 12 are used at once and only for files 
;that run very fast
for i = 0, 11 do begin $
  obj = OBJ_NEW('IDL_IDLBridge', output = '')
  obj->Execute, '!path = !path+":"+Expand_Path("+/evenetapp/store1/fism/fism2/code/idl")'
  objs[i] = obj
endfor
;print, objs
if keyword_set(to_save) then begin
 
  objs[0]->Execute, 'read_noaa_flrtxt', /nowait
  objs[1]->Execute, 'f107_penticton_to_save', /nowait
  objs[2]->Execute, 'mgii_dat_to_save', /nowait 
  objs[3]->Execute, 'lya_dat_to_save', /nowait 
  objs[4]->Execute, 'create_sc_sr_av, /cent_av', /nowait 
  objs[5]->Execute, 'sem_txt_to_sav'

endif 

if keyword_set(c_f_d_2) then begin
  objs[0]->Execute, 'comp_fism_daily_fuv, scsr_split=1, /update', /nowait
  objs[1]->Execute, 'comp_fism_daily_xuv, scsr_split=1, /update', /nowait
  objs[2]->Execute, 'comp_fism_daily, scsr_split=1, /update'
endif

if keyword_set(concat) then begin
  objs[0]->Execute, 'concat_fism_daily_xuv, /update', /nowait
  objs[1]->Execute, 'concat_fism_daily, /update', /nowait
  objs[2]->Execute, 'concat_fism_daily_fuv, /update'
  
endif

if keyword_set(create_hr) then begin 
  objs[0]->Execute, 'create_fism_hr_xuv, /update', /nowait
  objs[1]->Execute, 'create_fism_hr_fuv, /update'
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