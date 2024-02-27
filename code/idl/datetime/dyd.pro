  function dyd, yd1, yd2
;
; Given two calendar dates of the form yyyyddd.dd, returns the difference
; in days yd2-yd1.  Either or both arguments may be arrays; if both are
; arrays, they must agree in length.
;
; B. Knapp, 97.11.14
;           98.06.08, IDL v. 5 compliance
;
; $Log: dyd.pro,v $
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
; Revision 5.0  2002/08/05 23:09:44  see_sw
; commit of version 5.0
;
; Revision 1.2  2002/08/05 20:17:38  see_sw
; initial commit
;
; Revision 3.0  2002/02/01 18:52:38  see_sw
; version_3.0_commit
;
; Revision 1.1.1.1  2000/11/21 21:49:23  dlwoodra
; SEE External Library Msis90
;
;
;idver='$Id: dyd.pro,v 9.0 2017/10/30 14:59:42 see_sw Exp $'
;
; If both inputs are arrays, they must be the same length.
  info1 = size(yd1)
  info2 = size(yd2)
  if n_params() lt 2 or (info1[0] gt 0 and info2[0] gt 0 and $
     (info1[0] ne info2[0] or n_elements(yd1) ne n_elements(yd2))) then begin
     print,"                                                               "
     print,"  DYD returns the difference in days between two calendar dates"
     print,"  of the form yyyyddd.dd; that is, it returns the increment in "
     print,"  days from the first argument to the second argument, yd2-yd1."
     print,"  Either or both arguments may be arrays; if both are arrays,  "
     print,"  they must have the same dimensions.                          "
     print,"                                                               "
     print,"  diff = dyd( yd1, yd2 )                                       "
     return,''
  endif
;
  return, yd2jd(yd2)-yd2jd(yd1)
;
  end
