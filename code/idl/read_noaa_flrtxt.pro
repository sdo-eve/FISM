;
; NAME: read_noaa_flrtxt.pro
;
; PURPOSE: to read the flare information from a textfile from the
;   NOAA website
;
; CALLING PRO:
;   read_noaa_flrtxt, yr
;       yr: the year you want to find the flares for (eg. 2002 $
;       or [2002,2003])
;
; MODIFICATION HISTORY:
;   3/8/04  PCC     Program Creation
;   3/26/05 PCC Automatically finds the current yyyydoy
;           Now saves start and end times as sod, not hhmm
;           Saves location as just the longitude deg
;;CALLING PRO
;allyear
;silent
;
;+

pro read_noaa_flrtxt, year, allyear=allyear, silent=silent

print, 'Running read_noaa_flrtxt.pro ', !stime

cur_yd=strmid(strtrim(get_current_yyyydoy(),2), 0, 7)
cur_y=strmid(strtrim(cur_yd,2),0,4)

FILE_MKDIR, expand_path('$tmp_dir')
; If a year wasn't given, and the allyear keyword wasn't set, do the current
; year.
if (not keyword_set(year)) and (not keyword_set(allyear)) then $
    year=fix(cur_y, type=2)

; If the allyear keyword was set, do every year from 1996 until the current
; year.
if keyword_set(allyear) then begin
    cur_year = fix(cur_y, type=2)
    nyrs = cur_year - 1996 + 1
    year = findgen(nyrs) + 1996
    strt_yrdy = 1l + fix(year[0], type=3) * 1000l + 213
 endif else begin
    strt_yrdy = 1l + fix(year[0], type=3) * 1000l
endelse

n_yr=n_elements(year)

end_yrdy = 365l + fix(year[n_yr-1], type=3) * 1000l

; Special cases for the year 2000.
if year[0] eq 2000 then strt_yrdy = strt_yrdy + 1
if year[n_yr-1] eq 2000 then end_yrdy = end_yrdy + 1l

; Special case if the end year is the current year.
if year[n_yr-1] eq cur_y then end_yrdy = cur_yd

prev_yr = year[0]
yrdy = strt_yrdy

;Declare Variables for the final saveset
yrdoy = 2000000
st_tm = 3600 * 24l
typ = 'SSS' ; stores the type of the event from the txt file
loc = 'SSS' ; stores location of event
event = 9999 ; stores the event number given by swpc

while yrdy ne end_yrdy do begin
    ; Convert YDOY date into a YMD date.
    yrdyarr = yd2ymd(yrdy)
    yr = strmid(strtrim(yrdyarr[0],2), 0, 4)
    mnth = yrdyarr[1]
    dy = yrdyarr[2]

    ; Save the data if this day is the beginning of a new year.
    if yr ne prev_yr then begin
        ntot = n_elements(st_tm)
        svfl = expand_path('$tmp_dir') + '/noaa_flr_data_' + $
            strtrim(prev_yr, 2) + '.sav'

        ; Create an array of structure for the flare saveset
        noaa_flare_dat_tmp = {yyyydoy: 0l, strt_time: 0l, locat: ''}
        noaa_flare_dat = replicate(noaa_flare_dat_tmp, ntot-1)

        ; Create a structure for the flare saveset
        noaa_flare_dat.yyyydoy = yrdoy[1:ntot-1]
        noaa_flare_dat.strt_time = st_tm[1:ntot-1]
        noaa_flare_dat.locat = loc[1:ntot-1]

        print, 'Saving ', svfl
        save, noaa_flare_dat, file=svfl

        ; Reinitialize arrays to eliminate previous years data
        yrdoy = 2000000
        st_tm = 3600 * 24
        typ = 'SSS'
        loc = 'SSS'
        event = 9999
    endif

    ; Convert the month and day numbers into strings.
    if mnth lt 10 then mnth = '0' + strtrim(mnth, 2) else $
        mnth = strtrim(mnth, 2)
        mnth = strmid(mnth, 0,2)
    if dy lt 10 then dy= '0' + strtrim(dy, 2) else dy = strtrim(dy, 2)
      dy = strmid(dy, 0, 2)
    syr = strtrim(yr, 2)
    ;syr = strmid(syr, 0, 4)

    ; For the current year, get the NOAA events files from the internet.
    ; For any other year, get the local events files.
    ;if yr eq cur_y then begin
    ;    tmp_file = expand_path('$tmp_dir') + '/flare_tmp.txt'
    ;    cmd = 'wget -O ' + tmp_file + ' -q' + $
    ;          ' http://www.sec.noaa.gov/ftpdir/warehouse/' + syr + '/' + $
    ;          syr + '_events/' + syr + mnth + dy + 'events.txt'
    ;    spawn, cmd
    ;
    ;    get_lun, lun
    ;    openr, lun, tmp_file
    ;endif else begin
        txtfl=expand_path('$fism_data')+'/noaa/noaa_event_reports/' + syr + '_events/' + syr + mnth + dy + $
            'events.txt'
        get_lun, lun
        openr, lun, txtfl, error=err
        if err ne 0 then goto, nofile
    ;endelse

    ; Headers are marked beginning May 9th, 1998. Before then, the headers
    ; were not identified in any way. This just skips the lines in the
    ; header. (The marked headers in 1998 are also skipped.)
    if yr le 1998 then begin
        line = ''
        readf, lun, line
        readf, lun, line
        readf, lun, line
        readf, lun, line
        readf, lun, line
        readf, lun, line
    endif

    ; For the time conversions.
    ind = 0
    while ~ EOF(lun) do begin
        ; Various booleans to trigger things I don't qute understand.
        xr_trip = 0
        flr_trip = 0
        nx_flr_trip = 0

        ; Read in a line from the file, split it by whitespace, and count the
        ; number of columns so we can guess at what's in that line.
        line = ''
        readf, lun, line
        dat = strsplit(line, /extract)
        num_col_dat = n_elements(dat)
    
        ; Skip the marked header.
        if strmid(dat[0], 0, 1) eq ':' then continue
        if strmid(dat[0], 0, 1) eq '#' then continue

        ;if (num_col_dat gt 9) and strmid(dat[0], 0, 1) ne '#' then begin
        if (num_col_dat gt 9) then begin
            if fix(dat[6], type=7) eq 'XRA' then begin ; type is X-ray event from SWPC's Primary or Secondary GOES spacecraft
                yrdoy = [yrdoy, yrdy]
                st_tm = [st_tm, hhmm_to_sod(dat[1])]
                typ = [typ, dat[6]]
                event = [event, dat[0]]
                xr_trip = 1       
            endif 
            if fix(dat[7], type=7) eq 'XRA' then begin
                yrdoy = [yrdoy, yrdy]
                st_tm = [st_tm, hhmm_to_sod(dat[2])]
                typ = [typ, dat[7]]
                event = [event, dat[0]]
                xr_trip = 1       
            endif 
            evnt_chk = where(event eq dat[0] and (fix(dat[6], type=7) eq 'FLA' $
                or fix(dat[6], type=7) eq 'XFL')) ; SXI X-ray flare from GOES Solar X-ray Imager (SXI)
            if evnt_chk[0] ne -1 then begin
                ; Need to use last element as NOAA events cycle after 9999, and
                ; need to get correct, latest event
                nevent_chk = n_elements(evnt_chk)
                loc[evnt_chk[nevent_chk-1]] = dat[7]
                flr_trip = 1
            endif
            if (fix(dat[6], type=7) eq 'FLA' or fix(dat[6], type=7) eq 'XFL') $ ; Optical flare observed in H-alpha 
                and evnt_chk[0] eq -1 then begin
                yrdoy = [yrdoy, yrdy]
                st_tm = [st_tm, hhmm_to_sod(dat[1])]
                typ = [typ, dat[6]]
                event = [event, dat[0]]
                loc = [loc ,dat[7]]
                nx_flr_trip = 1
            endif
            if fix(dat[7], type=7) eq 'FLA' and evnt_chk[0] ne -1 then begin
                nuel = n_elements(loc)
                loc[evnt_chk[0]] = dat[8]
                flr_trip = 1
            endif
            if fix(dat[7], type=7) eq 'FLA' and evnt_chk[0] eq -1 then begin
                yrdoy = [yrdoy, yrdy]
                st_tm = [st_tm, hhmm_to_sod(dat[2])]
                typ = [typ, dat[7]]
                event = [event, dat[0]]
                loc = [loc, dat[8]]
                nx_flr_trip = 1
            endif
            if xr_trip eq 1 and flr_trip eq 0 then loc = [loc,'0']

            ; This used to compare to max_tm, but that was removed.
            ; Why did it use max time?
            if n_elements(loc) ne n_elements(st_tm) then stop
        endif

     endwhile
    nofile:
    free_lun, lun
    prev_yr = yr
    yrdy = get_next_yyyydoy(yrdy)
endwhile

; Save the last years data
ntot = n_elements(st_tm)
svfl = expand_path('$tmp_dir') + '/noaa_flr_data_' + $
    syr + '.sav'

; Create an array of structure for the flare saveset
noaa_flare_dat_tmp = {yyyydoy: 0l, strt_time: 0l, locat: ''}  
noaa_flare_dat = replicate(noaa_flare_dat_tmp, ntot)

; Create a structure for the flare saveset
noaa_flare_dat.yyyydoy = yrdoy
noaa_flare_dat.strt_time = st_tm
noaa_flare_dat.locat = loc

print, 'Saving ', svfl
save, noaa_flare_dat, file=svfl
print, 'End Time read_noaa_flrtxt: ', !stime

end
