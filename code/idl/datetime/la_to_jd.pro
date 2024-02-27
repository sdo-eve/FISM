function la_to_jd, la
;
; Convert LASP ASCII date/time string format to Julian Day Number
;
; B. Knapp, 2003-11-25
;
; $Version$ $Date: 2016/10/28 16:30:40 $
;
; $Header: /export/timed/CVS//production/science_dp/external_lib/datetime/la_to_jd.pro,v 9.1 2016/10/28 16:30:40 see_sw Exp $
;
; $Log: la_to_jd.pro,v $
; Revision 9.1  2016/10/28 16:30:40  see_sw
; update
;
; Revision 10.0  2007/05/08 19:01:10  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:22:30  see_sw
; commit of version 9.0
;
; Revision 8.2  2005/06/13 15:51:37  turkk
; commit for v8 release
;
; Revision 1.1  2003/11/25 21:23:29  knapp
; Initial revision
;
;
; Print usage?
  info = size(la)
  type = info[info[0]+1]
  if type ne 7 then begin
     print,"                                                               "
     print,"  LA_TO_JD translates LASP ASCII (LA) date/time strings of     "
     print,"  the form 'yyyy/ddd-hh:mm:ss' to Julian Day Numbers (and      "
     print,"  fraction).  The input argument may be a scalar or string     "
     print,"  array.                                                       "
     print,"                                                               "
     print,"  jd = la_to_jd( la )                                         "
     return,''
  endif
;
  return, la2jd(la)
end
