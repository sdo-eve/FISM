;+
; NAME:
;	UTC_TO_GPS
;
; PURPOSE:
;	Convert Date and Universal Time to GPS (spacecraft) time
;
; CATEGORY:
;	Utility
;
; CALLING SEQUENCE:  
;	utc_to_gps, yyyydoy, utc, gps, gpsleap=gpsleap, auto=auto
;
; INPUTS:
;	yyyydoy: Year-Day_of_Year (long)
;	utc: Coordinated Universal Time, seconds of day (floating point)
;
; OPTIONAL INPUT:
;	gpsleap: number of leap seconds to use in the date/time conversion
;          : gpsleap is ignored unless auto keyword is set to zero
;   auto: set to 0 to allow gpsleap to be used as input
;       : if auto is not passed in, it is assumed to be set to 1
;
; OUTPUTS:
;	gps: GPS time in seconds (e.g., spacecraft_time from PVAT)
;      : gps contains the leap second offset
;
; OPTIONAL OUTPUTS:
;   gpsleap: the value of leap seconds used (as an array)
;
; COMMON BLOCKS:
;  common gps_leap_sec_cal, leap_sec_ready_flag, refgps, refjd, leap_sec_value
;      leap_sec_ready_flag: flag indicating that the reference leap second file
;                           has already been loaded
;      refgps: reference GPS seconds for each leap second in the file
;      refjd:  reference julian date from the leap second file
;      leap_sec_value: leap second correction read from the file
;
;  common gps_to_utc_cal, secday, secmin, minhour, sechour, gps0_jday
;      secday: seconds in a day (constant)
;      secmin & minhour: seconds in a minute & minutes in an hour (constant)
;      sechour: seconds in an hour (constant)
;      gps0_jday: julian date of the GPS epoch (Jan 6, 1980 = 2444244.5)
;
; PROCEDURE:
;	Converts input year, day-of-year, and second-of-day in coordinated UT
;	to GPS time used by the TIMED spacecraft
;
; MODIFICATION HISTORY:
;	2/11/00		Tom Woods	Opposite conversion by gps_to_utc.pro
;	8/25/00		Tom Woods	Added guess for leap seconds correction
;	3/09/01		Don Woodraska	Modified to be IDL 5.4 compatible (fix uhr)
;	1/15/02		Don Woodraska	Modified to use 13 leap seconds as the
;	                            default. Added gpsleap keyword to
;	                            allow the user to override this value.
;	6/7/02		Don Woodraska	Logic change for bug fix that
;	                            prevented 0 from being a valid leapsecond.
;   09/27/05  DLW Added auto keyword and changed default bahavior to use
;                 the two common blocks defined in gps_to_utc. These contain
;                 the USNO leap seconds and the default is to use them. 
;                 gpsleap is ignored unless auto is set to zero. If gpsleap
;                 keyword is set to a variable, this procedure overwrites
;                 the contents with the used values for leap seconds.
;
; leap second verification results:
;IDL> for i=0,5 do begin sod=86397+i & utc_to_gps,2005365,sod,g & print,g,sod,form='(f10.0,x,i5.5)'
;820108810. 86397
;820108811. 86398
;820108812. 86399
;820108814. 86400
;820108815. 86401
;820108816. 86402
;
; REQUIRED FUNCTIONS/PROCEDURES:
;   gps_to_utc.pro
;   yyyydoy2ymd.pro
;
; $Log: utc_to_gps.pro,v $
; Revision 8.1  2006/01/23 23:00:51  dlwoodra
; updated for another leap second (14)
;
; Revision 9.0  2005/06/16 15:26:37  see_sw
; commit of version 9.0
;
;idver='$Id: utc_to_gps.pro,v 8.1 2006/01/23 23:00:51 dlwoodra Exp $'
;
;-

pro utc_to_gps, yyyydoy, utc, gps, gpsleap=gpsleap, auto=auto

common gps_leap_sec_cal, leap_sec_ready_flag, refgps, refjd, leap_sec_value
common gps_to_utc_cal, secday, secmin, minhour, sechour, gps0_jday

if n_params() lt 3 then begin
    print,''
    print,' Usage: utc_to_gps, yyyydoy, utc, gps [,gpsleap=13]'
    print,''
    return
endif

if size(secday,/type) eq 0 then begin
    ; load common block data by calling gps_to_utc
    gps_to_utc,0,0,tmp
    ; loads the following values
    ;secday=86400L
    ;secmin=60L
    ;minhour=60L
    ;sechour= secmin*minhour
    ;gps0_jday = julday(1,6,1980,0,0,0)
endif

yyyydoy2ymd, yyyydoy, uyear, umm, udd
uhr = ulong(utc / sechour)
umin = ulong((utc mod sechour)/secmin)
usec = ulong(utc mod secmin)
in_jday = julday( umm, udd, uyear, fix(uhr), umin, usec )

; insert leap seconds
use_usno_leap_sec_val = 1 ;default is to use the leap second file data
if size(auto,/type) ne 0 then begin
    if auto eq 0 then begin
        use_usno_leap_sec_val = 0
        print,'WARNING: utc_to_gps is ignoring the USNO leap second definition and using the input parameter gpsleap'
    endif
endif
if use_usno_leap_sec_val eq 1 then begin
    ; use leap second values from the USNO tai-utc.dat file
    leapsec = dblarr(n_elements(in_jday))
    for i=0L,n_elements(leapsec)-1 do begin
        below = where(in_jday[i] ge refjd,n_below)
        if n_below ne 0 then leapsec[i] = max(leap_sec_value[below])
    endfor
endif else begin
    ;allow user to specify a different leap second offset
    leapsec = gpsleap
endelse

gps = ulong((in_jday - gps0_jday) * secday + leapsec + 0.5) 
;0.5 prevents round-off errors

; if a scalar was input, then return only scalars
if size(yyyydoy,/n_dim) eq 0 then begin
    gps=gps[0]
    leapsec=leapsec[0]
endif

if arg_present(gpsleap) then gpsleap=leapsec

return
end
