;+
; NAME:
;	yyyydoy2ymd.pro
;
; PURPOSE:
;	Convert yyyydoy to year-month-day
;
; CATEGORY:
;	Library function
;
; CALLING SEQUENCE:  
;	yyyydoy2ymd, yyyydoy, year, month, day
;
; INPUTS:
;	yyyydoy = year + day of year
;
; OUTPUTS:  
;	year = 4 digit year
;	month = 1-12 for Jan-Dec
;	day = 1-31 for day of month
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;	1.  Check input parameters
;	2.  Convert yyyydoy to year-month-day
;		Correct for leap year if necessary
;
; MODIFICATION HISTORY:
;	2/11/00		Tom Woods	Original creation for Version 1.0.0
;	6/13/02		DLW & KBT Bug fix for vectors.
;
; $Log: yyyydoy2ymd.pro,v $
; Revision 8.0  2005/06/15 18:51:22  see_sw
; commit of version 8.0
;
; Revision 8.0  2004/07/20 20:18:38  turkk
; commit of version 8.0
;
; Revision 7.0  2004/07/08 23:03:03  turkk
; commit of version 7.0
;
; Revision 6.0  2003/03/05 19:32:46  dlwoodra
; version 6 commit
;
; Revision 5.20  2002/09/06 23:21:36  see_sw
; commit of version 5.0
;
; Revision 4.1  2002/06/13 21:22:07  dlwoodra
; bug fix in leap year vector calculation
; logic was grouped incorrectly
;
; Revision 4.0  2002/05/29 18:10:03  see_sw
; Release of version 4.0
;
; Revision 3.0  2002/02/01 18:55:29  see_sw
; version_3.0_commit
;
; Revision 1.1.1.1  2000/11/21 21:49:17  dlwoodra
; SEE Code Library Import
;
;
;idver='$Id: yyyydoy2ymd.pro,v 8.0 2005/06/15 18:51:22 see_sw Exp $'
;
;-

pro yyyydoy2ymd, yyyydoy, theYear, theMonth, theDay

;
;	set default output values
;
theYear = 1900L
theMonth = 1L
theDay = 1L

;
;	define day arrays for quick calculation
;
day_max    = [ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ]
doy_offset = [  0L, 31, 59, 90,120,151,181,212,243,273,304,334,365 ]
doy_ly_offset = [ 0L, 31, 60, 91,121,152,182,213,244,274,305,335,366 ]

;
;	1.  Check input parameters
;
if (n_params(0) lt 2) then begin
	print, 'USAGE:  yyyydoy2ymd, yyyydoy, year, month, day'
	return
endif

;
;	2.  Convert yyyydoy to year-month-day
;		Correct for leap year if necessary
;
theYear = long( yyyydoy/1000L )
DOY = long( yyyydoy mod 1000L )
n_days = n_elements(DOY)

leapYear = theYear - theYear
if (n_days gt 1) then begin
	wleap = where( $
                   ( ((theYear mod 4) eq 0) and ((theYear mod 100) ne 0 ) ) $
                   or ((theYear mod 400) eq 0), n_leap )
	;wleap = where( (theYear mod 4) eq 0) and $
	;			( ((theYear mod 100) ne 0) or ((theYear mod 400) eq 0) )
	if (n_leap gt 0) then leapYear[wleap] = 1
endif else begin
	leapYear = ( ((theYear mod 4) eq 0) and ((theYear mod 100) ne 0 ) ) $
      or ((theYear mod 400) eq 0)
	;leapYear = ( (theYear mod 4) eq 0) and $
	;			( ((theYear mod 100) ne 0) or ((theYear mod 400) eq 0) )
endelse

;
;	process for each day
;
theMonth = DOY
theDay = DOY
for k=0,n_days-1 do begin
	if (leapYear[k] ne 0) then doff = doy_ly_offset else doff = doy_offset
	theMonth[k] = (where( (doff - DOY[k]) ge 0 ))[0]
	if (theMonth[k] lt 1) then theMonth[k] = 1
	if (theMonth[k] gt 12) then theMonth[k] = 12
	theDay[k] = DOY[k] - doff[theMonth[k]-1]
endfor

return
end
