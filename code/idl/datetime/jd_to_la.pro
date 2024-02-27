pro jd_to_la, jd, la
;
; Procedure (as opposed to function) to convert Julian Day Number
; and fraction to LASP ASCII string time format
;
; B. Knapp, 2003-11-25
;
; $Version$ $Date: 2016/10/28 16:30:40 $
;
; $Header: /export/timed/CVS//production/science_dp/external_lib/datetime/jd_to_la.pro,v 9.1 2016/10/28 16:30:40 see_sw Exp $
;
; $Log: jd_to_la.pro,v $
; Revision 9.1  2016/10/28 16:30:40  see_sw
; update
;
; Revision 10.0  2007/05/08 19:01:10  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:22:29  see_sw
; commit of version 9.0
;
; Revision 8.2  2005/06/13 15:45:55  turkk
; commit for v8 release
;
; Revision 1.1  2003/11/25 21:23:27  knapp
; Initial revision
;
;
; Print usage?
  info = size(jd)
  type = info[info[0]+1]
  if n_params() lt 2 or type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  JD_TO_LA is a procedure which translates Julian Day Numbers  "
     print,"  (and fraction) to LASP ASCII (LA) date/time strings of the   "
     print,"  form 'yyyy/ddd-hh:mm:ss'.  The input argument may be a scalar"
     print,"  or array of a 4-byte or 8-byte numerical type.               "
     print,"                                                               "
     print,"  jd_to_la, jd, la                                             "
     print,''
     return
  endif

  la = jd2la(jd)
  return
end
