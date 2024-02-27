function jd2la, jd
;
; Convert Julian Day Number & fraction to LASP ASCII string format
;
; B. Boyle, 2002-08-07
;
; $Version$ $Date: 2016/10/28 16:30:04 $
;
; $Header: /export/timed/CVS//production/science_dp/external_lib/datetime/jd2la.pro,v 9.1 2016/10/28 16:30:04 see_sw Exp $
;
; $Log: jd2la.pro,v $
; Revision 9.1  2016/10/28 16:30:04  see_sw
; update
;
; Revision 10.0  2007/05/08 19:01:10  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:22:29  see_sw
; commit of version 9.0
;
; Revision 8.1  2005/06/13 16:00:11  dlwoodra
; v8
;
; Revision 1.1  2003/11/25 21:23:27  knapp
; Initial revision
;
;
; Print usage?
  info = size(jd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  JD2LA translates Julian Day Numbers (and fraction) to LASP   "
     print,"  ASCII (LA) date/time strings of the form 'yyyy/ddd-hh:mm:ss'."
     print,"  The input argument may be a scalar or array of a 4-byte      "
     print,"  or 8-byte numerical type.                                    "
     print,"                                                               "
     print,"  la = jd2la( jd )                                             "
     return,''
  endif

  yd = jd2yd(jd)
  yr = fix(yd / 1000)
  doy = fix(yd - yr * 1000)
  fraction = yd - long(yd)
  hr = fix((fraction + 0.5d0 / 86400.0d0) * 24)
  minute = fix((fraction - fix(hr) / 24.0d0 + 0.5d0 / 86400.d0) * 1440)
  sec = fix((fraction - fix(hr) / 24.0d0 - fix(minute) / 1440.0d0 + $
    0.5d0 / 86400.0d0)*86400)

  yr = strtrim(yr,2)
  doy = strmid(strtrim(doy+1000,2),1,3)
  hr = strmid(strtrim(hr+100,2),1,2)
  minute = strmid(strtrim(minute+100,2),1,2)
  sec = strmid(strtrim(sec+100,2),1,2)

  la = yr + '/' + doy + '-' + hr + ':' + minute + ':' + sec
  return, la
end
