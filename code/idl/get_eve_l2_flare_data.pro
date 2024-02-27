;;
; NAME: get_eve_l2_flare_data
;
; PURPOSE: to retrieve the eve level 2 data for flares 
;
; HISTORY:
;       VERSION 2_01
;       

; Path of EVE data:
;     ~/EVE/data/level2/YYYY/DOY/
;         YYYY is the year directory
;         DOY is the Day of Year directory
;
; Will get both the EVL* and EVS* files
;phil1617

pro get_eve_l2_flare_data, year=year, doy=doy, st_hr=st_hr, end_hr=end_hr, debug=debug
print, 'Running get_eve_l2_flare_data ', !stime

;
; Flare Days YYYYDOY and UTC time (sec of day) from 'prgev_to_sav.pro'
;
;t_utc= time in seconds of day of the EVE flare, may be usefull later
restore, expand_path('$fism_save')+'/eve_flare_info.sav'
FILE_MKDIR, expand_path('$fism_data') + '/lasp/eve/data'
n_flrs=n_elements(yd)
restore, expand_path('$fism_save')+'/eve_version_file.sav'
if keyword_set(year) then begin
   if keyword_set(doy) then begin
      a=where(yd eq year*1000l+doy)
      if a[0] eq -1 then begin  ; This is for another requested day outside of the defined flare files
         st_ind=0
         if not keyword_set(st_hr) then st_hr=0
         if not keyword_set(end_hr) then end_hr=23
         yr_st=strtrim(year,2)
         dy_st=strtrim(doy,2)
         if strlen(dy_st) eq 1 then dy_st='00'+dy_st
         if strlen(dy_st) eq 2 then dy_st='0'+dy_st
            for k=st_hr,end_hr do begin
               if keyword_set(debug) then print, k
               if k lt 10 then hr_str='0'+strtrim(k,2) else hr_str=strtrim(k,2)
               if k ge 23 then begin ; for the following 2 hours if end of day
                     hr_str='0'+strtrim(k-24,2) 
                endif
               if k lt 0 then begin ; for previous hour if start hour 0
                     hr_str='23'
               endif
               ydoy_st=yr_st+dy_st
               lon_ydoy=fix(ydoy_st,type=3) 
               ; Check to see if files exist. If not, it will download both the EVL*
               ; and EVS* files (needed later)
               ;spawn, 'mkdir ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
               chk_fl=file_search('~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'+'*_'+hr_str+'_*')
               if hr_str eq '24' then stop
               if n_elements(chk_fl) eq 1 then begin
                   eve_get_data,2,lon_ydoy,lon_ydoy, version=version, revision=revision ;, hour=hr_str
                   ;spawn, 'mv ~/ssw/sdo/eve/data/level2/'+yr_st+'/'+dy_st+'/'+$
                   ;       'EVS_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
                   ;spawn, 'mv ~/ssw/sdo/eve/data/level2/'+yr_st+'/'+dy_st+'/'+$
                   ;       'EVL_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
               endif
            endfor  
            goto, spec_day_only
      endif else st_ind=a[0]    
      n_flrs=a[n_elements(a)-1]+1
   endif else begin
      a=where(yd ge year*1000l, wyrs)
      st_ind=a[0]
      ;n_flrs=a[0]+1
   endelse
endif else begin
   st_ind=0
endelse


for j=st_ind,n_flrs-1 do begin

	;  Get EVE data and compile into a single array
        if keyword_set(debug) then print, 'Start:', goes_hr_start[j], ' End: ', goes_hr_end[j]
        if keyword_set(debug) then print, j, ' of ', n_flrs-1
        if  goes_hr_start[j] le goes_hr_end[j] then begin ; More than one hour, same day
            for k=(goes_hr_start[j]-2)>0,(goes_hr_end[j]+3)<23 do begin
               ;print, k
               if keyword_set(debug) then print, k
               yr_st=strmid(strtrim(yd[j],2),0,4)
               dy_st=strmid(strtrim(yd[j],2),4,3)
               if k lt 10 then hr_str='0'+strtrim(k,2) else hr_str=strtrim(k,2)
               if k ge 23 then begin ; for the following 2 hours if end of day
                     hr_str='0'+strtrim(k-24,2) 
                     dy_st=strmid(strtrim(yd[j]+1,2),4,3)
               endif
               if k lt 0 then begin ; for previous hour if start hour 0
                     hr_str='23'
                     dy_st=strmid(strtrim(yd[j]-1,2),4,3)
               endif
               ydoy_st=yr_st+dy_st
               lon_ydoy=fix(ydoy_st,type=3) 
               ; Check to see if files exist. If not, it will download both the EVL*
               ; and EVS* files (needed later)
               ;spawn, 'mkdir ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
               chk_fl=file_search('~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'+'*_'+hr_str+'_*')
               
               if hr_str eq '24' then stop
               if n_elements(chk_fl) eq 1 then begin
                  eve_get_data,2,lon_ydoy,lon_ydoy, version=version, revision=revision; , hour=hr_str
                   ;spawn, 'mv ~/ssw/sdo/eve/data/level2/'+yr_st+'/'+dy_st+'/'+$
                   ;       'EVS_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
                   ;spawn, 'mv ~/ssw/sdo/eve/data/level2/'+yr_st+'/'+dy_st+'/'+$
                   ;       'EVL_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
                   
               endif
            endfor
         endif else begin ; More than one hour, crosses day boundary
            for k=goes_hr_start[j]-2,23 do begin ; First Day
               if keyword_set(debug) then print, k
               yr_st=strmid(strtrim(yd[j],2),0,4)
               dy_st=strmid(strtrim(yd[j],2),4,3)
               if k lt 10 then hr_str='0'+strtrim(k,2) else hr_str=strtrim(k,2)
               if k lt 0 then begin ; for previous hour if start hour 0
                     hr_str='23'
                     dy_st=strmid(strtrim(yd[j]-1,2),4,3)
               endif
               ydoy_st=yr_st+dy_st
               lon_ydoy=fix(ydoy_st,type=3) 
               ; Check to see if files exist. If not, it will download both the EVL*
               ; and EVS* files (needed later)
               ;spawn, 'mkdir ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
               chk_fl=file_search('~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'+'*_'+hr_str+'_*')
               if n_elements(chk_fl) eq 1 then begin
                   eve_get_data,2,lon_ydoy,lon_ydoy, version=version, revision=revision;, hour=hr_str
                   ;spawn, 'mv ~/ssw/sdo/eve/data/level2/'+yr_st+'/'+dy_st+'/'+$
                   ;       'EVS_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
                   ;spawn, 'mv ~/ssw/sdo/eve/data/level2/'+yr_st+'/'+dy_st+'/'+$
                   ;       'EVL_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
               endif
            endfor
            for k=0,goes_hr_end[j]+3 do begin ; Second Day, get 3 hours after
               if keyword_set(debug) then print, k
               yr_st=strmid(strtrim(get_next_yyyydoy(yd[j]),2),0,4)
               dy_st=strmid(strtrim(get_next_yyyydoy(yd[j]),2),4,3)
               if k lt 10 then hr_str='0'+strtrim(k,2) else hr_str=strtrim(k,2)
               if k ge 23 then begin ; for the following 2 hours
                      hr_str='0'+strtrim(k-24,2)
                      dy_st=strmid(strtrim(yd[j]+1,2),4,3)
               endif
               ydoy_st=yr_st+dy_st
               lon_ydoy=fix(ydoy_st,type=3) 
               ; Check to see if files exist. If not, it will download both the EVL*
               ; and EVS* files (needed later)
               ;spawn, 'mkdir ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
               chk_fl=file_search('~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'+'*_'+hr_str+'_*')
               if n_elements(chk_fl) eq 1 then begin
                   eve_get_data,2,lon_ydoy,lon_ydoy, version=version, revision=revision;, hour=hr_str
                   ;spawn, 'mv ~/ssw/sdo/eve/data/level2/'+yr_st+'/'+dy_st+'/'+$
                   ;       'EVS_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
                   ;spawn, 'mv ~/ssw/sdo/eve/data/level2/'+yr_st+'/'+dy_st+'/'+$
                   ;       'EVL_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
                ;spawn, 'scp -r chamberlin@evesci4:/eve_analysis/testing/data/level2/'+yr_st+'/'+dy_st+'/'+$
                ;    'EVS_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
                ;spawn, 'scp -r chamberlin@evesci4:/eve_analysis/testing/data/level2/'+yr_st+'/'+dy_st+'/'+$
                ;    'EVL_L2_'+yr_st+dy_st+'_'+hr_str+'_'+version+'.fit.gz ~/EVE/data/level2/'+yr_st+'/'+dy_st+'/'
               endif
            endfor
         endelse

endfor

print, 'End Time get_eve_l2_flare_data: ', !stime

spec_day_only:

end
