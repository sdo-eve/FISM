;+
; Author:
;   Brian Clarke
;
; PURPOSE:
;   Convert a given time format to a gps time.  The time will be returned
;   as microceconds since the GPS epoch.
;
; INPUT PARAMETERS:
;   time -
;      The time to be converted.
;      May be specified as julian days, year day, gps microseconds, or
;      SORCE mission day numbers, depending upon the keyword parameters
;      provided in the call.
;   
; OUTPUT PARAMETERS:
;   NONE
;
; RETURN VALUE:
;   The converted time in gps.
;
; Keyword Arguments:
;   gps
;        If set, indicates that input time is to be interpreted as
;        microseconds since Jan 6, 1980 midnight UT.
;
;   mission_day
;        If set, indicates that input time is to be interpreted as
;        days elapsed since launch, i.e. mission days.  If specified, 
;        mission_day will be interpreted as a SORCE mission day, unless
;        the project keyword is set.
;
;   julian_day
;        If set, indicates that the input time is to be interpreted as
;        a julian day number.
;
;   year_day
;        If set, indicates that the input time is to be interpreted as
;        a year and decimal day of year, i.e. 2003140.698.
;
;   lasp_ascii
;        If set, indicates that the input time is to be interpreted as
;        a LASP ASCII string, i.e. 2000/001-00:00:00
;
;   vms
;        If set, indicates that the input time is to be interpreted as
;        a VMS date/time string, i.e. 01-Jan-2000 00:00:00.00
;
;   yf4
;        If set, indicates that the input time is to be interpreted as
;        a 4-digit year and fraction, i.e. 2005.0
;   
;   project
;        Used in conjunction with the mission_day keyword.  Specifies
;        the mission/project for which mission days are being provided, 
;        e.g. UARS or SORCE.
;
; Example Usage:
;  Using Julian day numbers:
;   jd_time = yd2jd(2003063.d)
;   data = get_gps_time(jd_time, /julian_day)
;
;  Using mission day numbers:
;   data = get_gps_time(32,  /mission_day, project='SORCE')
;
;-
; MODIFICATION HISTORY:
;      April 19, 2005 by Randy Meisner - added more time format support.
;      

FUNCTION get_gps_time, time, $
                       gps = gps, $
                       mission_day = mission_day, $
                       julian_day = julian_day, $
                       year_day = year_day, $
                       lasp_ascii = lasp_ascii, $
                       vms = vms, yf4 = yf4, $
                       project=project

; determine what type of time format is specified
IF (keyword_set(julian_day)) THEN BEGIN
                                ; user specified julian day.
  gps = jd2gps(time) * 1.d6
ENDIF ELSE IF (keyword_set(gps)) THEN BEGIN
                                ; user specified gp microseconds.
  gps = time
ENDIF ELSE IF (keyword_set(mission_day)) THEN BEGIN
                                ; user specified mission day
  IF (N_ELEMENTS(project) eq 0) THEN BEGIN
    gps = sd2gps(time) * 1.d6 ; assume SORCE
  ENDIF ELSE IF (strupcase(project) eq 'UARS') THEN BEGIN
    gps = ud2gps(time) * 1.d6
  ENDIF ELSE IF (strupcase(project) eq 'SORCE') THEN BEGIN
    gps = sd2gps(time) * 1.d6
  ENDIF ELSE BEGIN
    message, 'Unsupported instrument mode id'
  ENDELSE
ENDIF ELSE IF (keyword_set(year_day)) THEN BEGIN
                                ; user specified year day
  gps = yd2gps(time) * 1.d6
ENDIF ELSE IF(keyword_set(lasp_ascii)) THEN BEGIN
                                ; user specified LASP ASCII string
   gps = la2gps(time) * 1.d6
ENDIF ELSE IF(keyword_set(vms)) THEN BEGIN
                                ; user specified VMS date/time string
   gps = vms2gps(time) * 1.d6
ENDIF ELSE IF(keyword_set(yf4)) THEN BEGIN
                                ; user specified YF4 format
   gps = jd2gps(yf42jd(time)) * 1.d6
 ENDIF

if (n_elements(gps) eq 0) then begin
  doc_library, 'get_gps_time'
endif

return, gps

END
