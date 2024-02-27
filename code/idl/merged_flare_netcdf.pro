;
; Purpose: To create needed merged netcdf files for the FISM v02 flare data
; 
; INPUTS: 
;   stydoy - should come from the create_merged_netcdf file. Will be the desired start date 
;     for the file
;   edydoy - should come from the create_merged_netcdf file. Will be the desired end date
;     for the file
;   numdys - This is what controls the file size. This dictates the number of days to put in 
;     each file. 
;   update - This keyword shoudl be passed from the create_merged_netcdf file. It will dictate
;     that files should be updated instead of overwritten. This will fill in any days that were
;     not updated or create/replace files up until the current or desired end day from whatever 
;     day was last saved. 
;     
;     How to call in create_merged_netcdf.pro:
;     
;     merged_flare_netcdf, stydoy= lastdy_f, edydoy=enddy_f
;     merged_flare_netcdf, stydoy= lastdy_f, edydoy=enddy_f, /update
;     
;     You can also add a numdys to this to change the size, it will default to years right now 
;     
;Helper function 
function find_offset, f, dim
  compile_opt idl2
  did = ncdf_dimid(f, dim) ;get dimension id
  ncdf_diminq, f, did, name, offset
  return, offset
end

pro merged_flare_netcdf, stydoy= stydoy, edydoy=edydoy, numdys=numdys, update=update
  ;initial set if no information is provided 
  year = 0 ; this variable will not be set if numdys is provided, otherwise it causes the years
  if not keyword_set(stydoy) then stydoy = 2003001
  if not keyword_set(edydoy) then edydoy = get_prev_yyyydoy(get_current_yyyydoy(), 8)
  checkf = 0 ; this variable dictates if a file already exists or not, it is 0 if it does not
  if not keyword_Set(numdys) then begin
    numdys = 365 ; set initial numdys
    year = 1 
  endif
  ;make sure update will only go back one file
  if numdys lt 61 then numdys = 61
  
  ;tracker is used to track how many days have been palced into a file so far
  tracker = 0 
  ;last file keeps track of the last file edited for the sake of updating
  lastfile = ''
  ;if this needs to be updatef 
  if keyword_set(update) then begin
    ;get the last file that was edited by getting a list of the files and looking at the
    ;mtime portion of file info 
    cd, expand_path('$fism_results') + '/flare_hr_data'
    files = file_search('*.nc')
    max = 0 
    for i = 0, n_elements(files) -1 do begin
      info = file_info(files[i])
      if info.mtime gt max then begin
        max = info.mtime
        lastfile = files[i]
      endif
    endfor
    
    ;open the last edited file and get the day that was last added
    if file_test(expand_path('$fism_results') + '/flare_hr_data/' + lastfile) then begin
      f = ncdf_open(expand_path('$fism_results') + '/flare_hr_data/' + lastfile)
      doy = NCDF_VARID(f, 'date')
      NCDF_VARGET, f, doy, doyArr
      lastdy_f = fix(doyArr[size(doyArr, /N_ELEMENTS) -1], type=3)
      lastdy_f = get_prev_yyyydoy(lastdy_f, 60)
      checkf = 1
      ;make sure the tracker is accurate based on the number of days in a file
      tracker = jd_to_yd(lastdy_f) - jd_to_yd(strmid(lastfile, 6, 7)) 
      NCDF_CLOSE, f
      ;make the start day correct 
      stydoy = lastdy_f ; get_next_yyyydoy(lastdy_f)
      ;only say the file doesnt exist if its the end of the last file
      if strmid(lastfile,14,7) eq strmid(get_next_yyyydoy(stydoy), 5,7) then begin
        checkf = 0 
      endif
    endif
  endif
  
  print, 'Creating merged files for flare data'
  if (keyword_set(update) eq 0) or (checkf eq 0) then begin
    y = strmid(stydoy, 5, 4)
    yd = strmid(stydoy, 5, 7)
      ;make sure that if the first year input is a leap year that it changes to 366
      ly = leap_year(fix( y , type=3))
      if ly eq 1 then numdys = 366
      if ly eq 0 then numdys = 365
    endd = strmid(get_next_yyyydoy(stydoy, numdys - 1), 5, 7)
    restore, expand_path('$fism_results') + '/flare_hr_data/2003/FISM_60sec_2003001_v02_01.sav'
    ncdf_file = NCDF_CREATE(expand_path('$fism_results') + '/flare_hr_data/flare_' + yd + '_' + endd + '.nc', /CLOBBER, /NETCDF4_FORMAT)
    NCDF_CONTROL, ncdf_file, /FILL

    ;create dimensions
    wvid = NCDF_DIMDEF(ncdf_file, 'wavelength', 1900)
    utcid = NCDF_DIMDEF(ncdf_file, 'utc', 1440)
    timeid = NCDF_DIMDEF(ncdf_file, 'date', /UNLIMITED)

    ; create variables
    predid = NCDF_VARDEF(ncdf_file, 'irradiance', [wvid, utcid, timeid],/FLOAT, chunk_dimensions=[1900, 1440, 1], gzip=2)
    errid = NCDF_VARDEF(ncdf_file, 'uncertainty', [wvid, utcid,timeid],  /float, chunk_dimensions=[1900, 1440, 1], gzip=2)
    wavid = NCDF_VARDEF(ncdf_file, 'wavelength', [wvid], /float)
    utcid = NCDF_VARDEF(ncdf_file, 'utc', [utcid], /double)
    doyid = NCDF_VARDEF(ncdf_file, 'date', [timeid], /string)
    ;add global and variable attributes
    NCDF_ATTPUT, ncdf_file, /GLOBAL, 'title', 'FISM2 is an empirical model of the Solar Spectral Irradiance from 0.01-190nm at 0.1 nm spectral bins. This is the flare product with one spectrum every 60 seconds.'
    NCDF_ATTPUT, ncdf_file, /GLOBAL, 'product_version', '2.0'

    NCDF_ATTPUT, ncdf_file, predid, 'units', 'W/m^2/nm', /CHAR
    NCDF_ATTPUT, ncdf_file, predid, 'long_name', 'FISM Prediction', /CHAR

    NCDF_ATTPUT, ncdf_file, wavid, 'units', 'nm', /CHAR
    NCDF_ATTPUT, ncdf_file, wavid, 'long_name', 'FISM Wavelength', /CHAR

    NCDF_ATTPUT, ncdf_file, utcid, 'units', 'Seconds after 00:00', /CHAR
    NCDF_ATTPUT, ncdf_file, utcid, 'long_name', 'Unix time', /CHAR

    NCDF_ATTPUT, ncdf_file, doyid, 'units', 'YYYYDDD', /CHAR
    NCDF_ATTPUT, ncdf_file, doyid, 'long_name', 'Year - Day of year', /CHAR

    NCDF_ATTPUT, ncdf_file, errid, 'units', '', /CHAR
    NCDF_ATTPUT, ncdf_file, errid, 'long_name', 'FISM Error', /CHAR

    NCDF_CONTROL, ncdf_file, /ENDEF
    
    ; put data into variables
    NCDF_VARPUT, ncdf_file, predid, irradiance
    NCDF_VARPUT, ncdf_file, wavid, wavelength
    NCDF_VARPUT, ncdf_file, utcid, utc
    NCDF_VARPUT, ncdf_file, doyid, ydoy
    NCDF_VARPUT, ncdf_file, errid, uncertainty
    NCDF_CLOSE, ncdf_file
    
    tracker = 1
  endif
  tmpyd = get_next_yyyydoy(stydoy)

  ;set the vairables needed for file access to initial values
  y = strmid(stydoy, 5, 4)
  yd = strmid(stydoy, 5, 7)
  endd = strmid(get_next_yyyydoy(stydoy, numdys - 1), 5, 7)
  ;correct values for update
  if keyword_set(update) then begin
    y = strmid(lastfile, 6, 4)
    yd = strmid(lastfile, 6, 7)
    endd = strmid(get_next_yyyydoy(fix(strmid(lastfile, 6, 7), type=3), numdys - 1), 5, 7)
  endif
  
  while tmpyd ne edydoy do begin
    ;print, tmpyd, ' ', edydoy
    left = yd2jd(edydoy) - yd2jd(tmpyd)
    ;if the proper number of days were put in the netcdf file, then start the next one
      if tracker eq numdys then begin
        ;make sure numdys is accurate for year
        if year eq 1 then begin
          ;check leap yea
          ly = leap_year(fix(strmid(tmpyd, 5, 4), type=3))
          if ly eq 1 then numdys = 366
          if ly eq 0 then numdys = 365
        endif
        y = strmid(tmpyd, 5, 4)
        yd = strmid(tmpyd, 5, 7)
        tracker = 0
        endd = strmid(get_next_yyyydoy(tmpyd, numdys - 1), 5, 7)
        restore, expand_path('$fism_results') + '/flare_hr_data/' + y + '/FISM_60sec_' + yd + '_v02_01.sav'
       
        ncdf_file = NCDF_CREATE(expand_path('$fism_results') + '/flare_hr_data/flare_' + yd + '_' + endd + '.nc', /CLOBBER, /NETCDF4_FORMAT)
        ;stop
        NCDF_CONTROL, ncdf_file, /FILL

        ;create dimensions
        wvid = NCDF_DIMDEF(ncdf_file, 'wavelength', 1900)
        utcid = NCDF_DIMDEF(ncdf_file, 'utc', 1440)
        timeid = NCDF_DIMDEF(ncdf_file, 'date', /UNLIMITED)

        ; create variables
        predid = NCDF_VARDEF(ncdf_file, 'irradiance', [wvid, utcid, timeid],/FLOAT, chunk_dimensions=[1900, 1440, 1], gzip=2)
        errid = NCDF_VARDEF(ncdf_file, 'uncertainty', [wvid, utcid,timeid],  /float, chunk_dimensions=[1900, 1440, 1], gzip=2)
        wavid = NCDF_VARDEF(ncdf_file, 'wavelength', [wvid], /float)
        utcid = NCDF_VARDEF(ncdf_file, 'utc', [utcid], /double)
        doyid = NCDF_VARDEF(ncdf_file, 'date', [timeid], /string)

        ;add global and variable attributes
        NCDF_ATTPUT, ncdf_file, /GLOBAL, 'title', 'FISM2 is an empirical model of the Solar Spectral Irradiance from 0.01-190nm at 0.1 nm spectral bins. This is the flare product with one spectrum every 60 seconds.'
        NCDF_ATTPUT, ncdf_file, /GLOBAL, 'product_version', '2.0'
    
        NCDF_ATTPUT, ncdf_file, predid, 'units', 'W/m^2/nm', /CHAR
        NCDF_ATTPUT, ncdf_file, predid, 'long_name', 'FISM Prediction', /CHAR
    
        NCDF_ATTPUT, ncdf_file, wavid, 'units', 'nm', /CHAR
        NCDF_ATTPUT, ncdf_file, wavid, 'long_name', 'FISM Wavelength', /CHAR
    
        NCDF_ATTPUT, ncdf_file, utcid, 'units', 'Seconds after 00:00', /CHAR
        NCDF_ATTPUT, ncdf_file, utcid, 'long_name', 'Unix time', /CHAR
    
        NCDF_ATTPUT, ncdf_file, doyid, 'units', 'YYYYDDD', /CHAR
        NCDF_ATTPUT, ncdf_file, doyid, 'long_name', 'Year - Day of year', /CHAR
    
        NCDF_ATTPUT, ncdf_file, errid, 'units', '', /CHAR
        NCDF_ATTPUT, ncdf_file, errid, 'long_name', 'FISM Error', /CHAR

        NCDF_CONTROL, ncdf_file, /ENDEF
        
        ; put data into variables
        NCDF_VARPUT, ncdf_file, predid, irradiance
        NCDF_VARPUT, ncdf_file, wavid, wavelength
        NCDF_VARPUT, ncdf_file, utcid, utc
        NCDF_VARPUT, ncdf_file, doyid, ydoy
        NCDF_VARPUT, ncdf_file, errid, uncertainty
        NCDF_CLOSE, ncdf_file
        goto, next
      endif
      f = ncdf_open(expand_path('$fism_results') + '/flare_hr_data/flare_' + yd + '_' + endd + '.nc', /write)
      ydoy = strmid(tmpyd, 5, 7)
      yr = strmid(ydoy, 0, 4)
      doy = strmid(ydoy, 4, 3)
      restore, '$fism_results/flare_hr_data/' + yr + '/FISM_60sec_'+ydoy+'_v02_01.sav'
      offset = find_offset(f, 'date')
      ydoy = strmid(ydoy, 5, 7)
      ;how many days in old file to update 
      new_days = yd2jd(edydoy) - yd2jd(get_next_yyyydoy(lastdy_f, 60))
      ;if you need to update back to old file 
      prev = 0
      
      ; if the file is being updated and needs to go back to the previous file
      if keyword_set(update) and (left ge offset + new_days) then begin
        ; find the number of days needed to be updated in the old file
        old_file_days = left - offset - new_days ; the new days is necessary to make sure that no extra days are updated and new days are added
        ; get file name for last file
        last_file_start =  strmid(get_prev_yyyydoy(fix(yd, type=3), numdys + 1), 5, 7)
        last_file_end =  strmid(get_prev_yyyydoy(fix(endd, type=3), numdys + 1), 5, 7)
        ; open that file, 
        fprev = ncdf_open(expand_path('$fism_results') + '/flare_hr_data/flare_' + last_file_start + '_' + last_file_end + '.nc', /write)
        ; write to that instead
        ncdf_varput, fprev, 'irradiance', irradiance, offset=[0, 0, fix(numdys - old_file_days, type = 2)]
        ncdf_varput, fprev, 'uncertainty', uncertainty, offset=[0, 0, fix(numdys - old_file_days, type=2)]
        ncdf_varput, fprev, 'date', ydoy, offset= fix(numdys -old_file_days, type=2)
        prev = 1
        ncdf_close, fprev
      endif 
      ;updating current file
      if keyword_set(update) and (left lt offset + new_days) and (left ge new_days) then begin
        ncdf_varput, f, 'irradiance', irradiance, offset=[0, 0, (offset + new_days) - left - 1]
        ncdf_varput, f, 'uncertainty', uncertainty, offset=[0, 0, (offset + new_days) - left - 1]
        ncdf_varput, f, 'date', ydoy, offset=(offset + new_days) - left - 1
      endif else begin
      ;adding new data 
        if prev eq 1 then goto, n
         ncdf_varput, f, 'irradiance', irradiance, offset=[0, 0, offset]
         ncdf_varput, f, 'uncertainty', uncertainty, offset=[0, 0, offset]
         ncdf_varput, f, 'date', ydoy, offset=offset
         n:
      endelse
      
      ncdf_close, f
      next:
      tmpyd = get_next_yyyydoy(tmpyd)
      tracker++ 
      ;numdys-- 
  endwhile
end