  function la2ud, la
;
; Translates LA time YYYY/DDD-HH:MM:SS to double precision
; UARS mission day.
;
; N. Kungsakawin 8/20/2003
;
; Print usage?
  info = size(la)
  type = info[info[0]+1]
  if type lt 1 or 7 lt type then begin
     print,"                                                               "
     print,"  LA2UD translates its argument, LA time YYYY/DDD-HH:MM:SS     "
     print,"  to a double-precision UARS mission day       "
     print,"  number, where UARS day 0.0 = 1991/254.0 = 1991 Sep 11.0.     "
     print,"  The argument may be a scalar or array.                       "
     print,"                                                               "
     print,"  ud = la2ud( la )                                             "
     return,''
  endif
;
  return,jd2md(la_to_jd(la),1991254)
;
  end

