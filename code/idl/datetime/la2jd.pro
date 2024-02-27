function la2jd, la
;
; Convert LASP ASCII date/time string format to Julian Day Number &
; fraction.
;
; B. Boyle, 2002-08-07
;
; $Version$ $Date: 2016/10/28 16:30:40 $
;
; $Header: /export/timed/CVS//production/science_dp/external_lib/datetime/la2jd.pro,v 9.1 2016/10/28 16:30:40 see_sw Exp $
;
; $Log: la2jd.pro,v $
; Revision 9.1  2016/10/28 16:30:40  see_sw
; update
;
; Revision 10.0  2007/05/08 19:01:10  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:22:30  see_sw
; commit of version 9.0
;
; Revision 8.1  2005/06/13 16:00:13  dlwoodra
; v8
;
; Revision 1.2  2004-05-21 16:48:12+00  knapp
; Make loop index a long integer
;
; Revision 1.1  2003-11-25 21:23:28+00  knapp
; Initial revision
;
;
; Print usage?
  info = size(la)
  type = info[info[0]+1]
  if type ne 7 then begin
     print,"                                                               "
     print,"  LA2JD translates LASP ASCII (LA) date/time strings of the    "
     print,"  form 'yyyy/ddd-hh:mm:ss' to Julian Day Numbers (and          "
     print,"  fraction).  The input argument may be a scalar or string     "
     print,"  array.                                                       "
     print,"                                                               "
     print,"  jd = la2jd( la )                                             "
     return,''
  endif
;
  year = double(strmid(la,0,4))
  doy = double(strmid(la,5,3))
  hour = double(strmid(la,9,2))
  minute = double(strmid(la,12,2))
  for i=0L,n_elements(la)-1 do $
  second = double(strmid(la(i),15,strlen(la(i))-15))
  yyddd=year*1000 + doy + hour/24.0d0 + minute/1440.0d0 + second/86400.0d0
;
  return, yd2jd(yyddd)
end
