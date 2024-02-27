;+
; NAME:
;   GPS_TO_UTC
;
; PURPOSE:
;   Convert GPS (spacecraft) time to Date and Universal Time
;
; CATEGORY:
;   Utility
;
; CALLING SEQUENCE:  
;   gps_to_utc, gps, nleap, year, doy, utc, month, day, hour, min, sec, $
;               vern=vern, auto=auto, julian=julian
;
; INPUTS:
;   gps: GPS time in seconds (e.g., spacecraft_time from PVAT)
;      : gps is expected to contain the leap second offset
;
; OPTIONAL INPUT:
;   nleap: Number of leap seconds since 1980 (e.g., leap_seconds from PVAT)
;        : only used as input if auto=0
;
; OPTIONAL OUTPUT:
;   nleap: Number of leap seconds used in conversion (default nleap behavior)
;   julian: Julian date of the converted UTC times
;
; OUTPUTS:  
;   year:  Year, longword integer
;   doy:   Day of Year, ddd, longword integer
;   utc:   Coordinated Universal Time in seconds of day, floating point
;   month: Month of year, integer
;   day:   Day of month, integer
;   hour:  Hour of day, integer
;   min:   Minute of hour, integer
;   sec:   Second of minute, integer
;
; KEYWORDS:
;   vern: Time vernier, optional, in microseconds, longword integer 
;   auto: Use leap second corrections from the USNO file tai-utc.dat
;         default is 1, set to zero to allow nleap to be an input parameter;
;
; COMMON BLOCKS:
;   common gps_leap_sec_cal, leap_sec_ready_flag, refgps, refjd, leap_sec_value
;      leap_sec_ready_flag: flag indicating that the reference leap second file
;                           has already been loaded
;      refgps: reference GPS seconds for each leap second in the file
;      refjd:  reference julian date from the leap second file
;      leap_sec_value: leap second correction read from the file
;
;   common gps_to_utc_cal, secday, secmin, minhour, sechour, gps0_jday
;      secday: seconds in a day (constant)
;      secmin & minhour: seconds in a minute & minutes in an hour (constant)
;      sechour: seconds in an hour (constant)
;      gps0_jday: julian date of the GPS epoch (Jan 6, 1980 = 2444244.5)
;
; PROCEDURE:
;   Converts from the GPS time used by the TIMED spacecraft to
;   year, day-of-year, and second-of-day in coordinated UT.  An
;   optional time vernier, in microseconds, e.g., position_time_vernier
;   or attitude_time_vernier from the PVAT files, may be included.
;   Month, day, hour, minute, and second are optional output parameters.
;   Uses the IDL routine JULDAY and the modified IDL routine CALDATES
;       (an array-friendly version of CALDAT) to perform conversions.
;   An array of times may be converted in one call.
;   Julian dates may be returned through the julian keyword.
;
; MODIFICATION HISTORY:
;   10/99   Obtained from APL in /geom package as gps2utc
;       Presumably written by R. DeMajistre
;   1/00    Revised, vectorized, and documented by Stan Solomon
;   1/00    Corrected vernier (/1.e6), Stan Solomon
;   2/00    Corrected calls to JULDAY to specify midnight, Stan Solomon
;   12/01   Changed to CALDATES to perform array date conversions, SCS
;   2/02    Bug fix, forcing nleap and gps to be double.
;   6/7/02 Don Woodraska  Finally added usage. 
;   10/14/03 Don Woodraska  Fixed DOY bug with input arrays that span
;       year boundaries.
;   09/27/05 DLW Added code to use USNO tai-ref.dat text file to retrieve
;       leap second times, nleap is ignored unless auto keyword is passed 
;       in and set to zero (auto=0), added two common blocks that are shared
;       with utc_to_gps, added optional julian keyword to return julian dates
;       Note: GPS time is always assumed to include leap seconds.
;
; leap second verification results:
;g=820108810.d0
;IDL> for i=0,5 do begin gi=g+i & gps_to_utc,gi,n,year,doy,utc,j=j & print,gi,year,doy,utc,n,form='(f10.0,x,i4.4,x,i3.3,x,f7.1,x,f5.1)'
;820108810. 2005 365 86397.0  13.0
;820108811. 2005 365 86398.0  13.0
;820108812. 2005 365 86399.0  13.0
;820108813. 2006 001     0.0  13.0
;820108814. 2006 001     0.0  14.0
;820108815. 2006 001     1.0  14.0
;
; REQUIRED FUNCTIONS/PROCEDURES/DATA FILES:
;   tai-utc.dat
;   ymd_to_yd.pro
;   leap_year.pro
;
; $Log: gps_to_utc.pro,v $
; Revision 8.1  2006/01/23 23:00:51  dlwoodra
; updated for another leap second (14)
;
; Revision 9.0  2005/06/16 15:26:36  see_sw
; commit of version 9.0
;
;idver='$Id: gps_to_utc.pro,v 8.1 2006/01/23 23:00:51 dlwoodra Exp $'
;
;-

pro gps_to_utc_see,gps,nleap,year,doy,utc,month,day,hour,min,sec,vern=vern,auto=auto,julian=julian

if n_params() le 2 then begin
    print,''
    print,' USAGE: gps_to_utc, gps, nleap, yyyy, doy, utc, month, day, hh, mm, ss, vern=vern, auto=auto, julian=julian'
    print,' where: gps is atomic time relative to 0 hours on Jan 6, 1980.' 
    print,'        nleap is number of leap seconds (probably 13)'
    print,'        yyyy is year, doy is day of year'
    print,'        utc is seconds of day'
    print,'        month is 1-12, day is 1-31'
    print,'        hh is 0-23, mm is 0-59, ss is 0-59'
    print,'        vern is a number of microseconds 0-1e6'
    print,'        auto: 0 uses nleap specified, 1 determines leap sec automatically'
    print,'        julian=julian, option to return julian date'
    print,''
    return
endif

common gps_leap_sec_cal, leap_sec_ready_flag, refgps, refjd, leap_sec_value
common gps_to_utc_cal, secday, secmin, minhour, sechour, gps0_jday

if size(secday,/type) eq 0 then begin
    ;define gps_to_utc_cal common block variables
    secday=86400l
    secmin=60l
    minhour=60l
    sechour= secmin*minhour
    gps0_jday= julday(1,6,1980,0,0,0)
endif

if size(leap_sec_ready_flag,/type) eq 0 then begin
    ref_file=getenv('fism_code')+'/idl/tai-utc.dat'
    if file_test(ref_file) eq 0 then begin
        ref_file='$fism_code/idl/tai-utc.dat'
        if file_test(ref_file) eq 0 then begin
            print,'ERROR: GPS_TO_UTC could not locate tai-utc.dat in see_cal_data or ./'
            print,'*** FATAL ERROR: GPS_TO_UTC cannot continue ***'
            stop
        endif
    endif
    nlines=file_lines(ref_file)
    yyyy=lonarr(nlines)
    mon=lonarr(nlines)
    day=lonarr(nlines)
    
    leap_sec_value=fltarr(nlines)
    reftai=dblarr(nlines)
    refjd=dblarr(nlines)
    
    s=''
    monthstr=['NON','JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT', 'NOV','DEC']
    
    openr,lun,/get_lun,ref_file
    for i=0L,nlines-1 do begin
        readf,lun,s
        ; format: YYYY MON DD =JD JJJJJJJ.J  TAI_UTC=  NN.N
        sstr=strsplit(strtrim(s,2),' ',/extract)
        yyyy[i]=long(sstr[0]) ;long
        mon[i]=(where(sstr[1] eq monthstr))[0] ;string
        day[i]=long(sstr[2]) ;long (always 1)
        refjd[i]=double(sstr[4]) ;floating point julian date
        leap_sec_value[i]=float(sstr[6]) ;floating point leap seconds
    endfor
    free_lun,lun

;   CONVERT FILE DATES INTO TAI seconds to compare against TAI

    ;add up seconds in each year since 1958
    secinleapyear=86400.d0*366.d0
    secinyear=86400.d0*365.d0
    secinday=86400.d0
    for j=0L,nlines-1 do begin
        for iL=1958L,yyyy[j]-1 do begin
            if i mod 4 eq 0 then $
              reftai[j] = reftai[j] + secinleapyear else $
              reftai[j] = reftai[j] + secinyear
        endfor
    endfor

    ymd_to_yd_see,yyyy,mon,day,yd
    ;add seconds in the days
    reftai = reftai + ((yd mod 1000L)*secinday)
    ;add seconds of day (always 0 for leap second days)
    ;reftai = reftai + 0
    
    leap_sec_value = leap_sec_value - 19L ;19 leap sec between TAI0 and GPS0
    wpos=where(leap_sec_value ge 0)
    leap_sec_value = leap_sec_value[wpos]
    refjd  = refjd[wpos]
    refgps = reftai[wpos] - 694656000L - 86400 ;TAI @ jan 6, 1980

    leap_sec_ready_flag=1 ;prevent re-reading data file over and over
;stop
endif

ver=0.d0

if keyword_set(vern) then ver=vern

use_usno_leap_sec_val = 1
if size(auto,/type) ne 0 then begin
    if auto eq 0 then begin
        use_usno_leap_sec_val = 0
        print,'WARNING: gps_to_utc is ignoring the USNO leap second definition and using the input parameter'
    endif
endif
if use_usno_leap_sec_val eq 1 then begin
    ;determine leap second correction for input gps times
    nleap=dblarr(n_elements(gps))
    for i=0L,n_elements(gps)-1 do begin
        below = where(gps[i] ge (refgps+leap_sec_value),n_below)
        if n_below ne 0 then nleap[i] = max(leap_sec_value[below])
    endfor
endif
;stop

utcbin=double(gps)-double(nleap) ;remove leap seconds from gps argument
days1=long(utcbin/secday) ;number of days (GPS days - 1)

jday_utc = gps0_jday + days1
caldat, jday_utc, um, ud, uy ;convert JD to month, day, year

if arg_present(julian) then julian = jday_utc

;jul0 = julday(1,1,uy) - 0.5d0 ; no round-off from julday
;doy=long(jday_utc-jul0+1.d0)
; convert month, day, year into yyyydoy
ymd_to_yd_see, uy, um, ud, yyyydoy
doy = yyyydoy mod (uy*1000L)

us  = (double(utcbin) mod secday) + (ver/1.d6)
ss  = us mod secmin
mm  = long(us/secmin) mod minhour
hh  = long(us/sechour)

; save memory by reassigning addresses a new name
year  = temporary(uy) ;temporary(long(uy)) already a long
utc   = temporary(us)
month = temporary(um)
day   = temporary(ud)
hour  = temporary(hh)
min   = temporary(mm)
sec   = temporary(ss)

return
end
