  function days,date1,date2

; Returns the number of days elapsed between two dates of the
; form yyyyddd.dd.
;
; B. G. Knapp, 1987-02-04, 1997-11-17
;
; RCS Data:
;
; $Header: /export/timed/CVS//production/science_dp/external_lib/datetime/days.pro,v 9.0 2017/10/30 14:59:42 see_sw Exp $
;
; $Log: days.pro,v $
; Revision 9.0  2017/10/30 14:59:42  see_sw
; update
;
; Revision 10.0  2007/05/08 19:01:09  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:22:29  see_sw
; commit of version 9.0
;
; Revision 8.0  2004/07/20 19:57:48  turkk
; commit of version 8.0
;
; Revision 7.0  2003/03/18 20:01:50  dlwoodra
; commit for version 7.0
;
; Revision 1.1  2003/03/18 20:01:11  dlwoodra
; initial commit
;
; Revision 1.1  2003/02/14 18:45:28  dlwoodra
; initial commit
;
; Revision 1.1  1999/12/03 18:37:44  knapp
; Initial revision
;
  if n_params() lt 2 then begin
      print,"                                                              "
      print,"  DAYS requires two arguments representing dates in the form  "
      print,"  yyyyddd.dd. It returns the number of days between the two   "
      print,"  dates.  A positive number of days will be returned if the   "
      print,"  first argument represents an earlier date than the second.  "
      print,"                                                              "
      print,"  ndays = days(date1,date2)                                   "
      return,"                                                              "
  endif
;
  return,dyd(date1,date2)
;
  end
