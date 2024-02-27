  function la2ymd, la
;
; Translates LA time YYYY/DDD:`-HH:MM:SS to Gregorian calendar date
; of the form [yyyy, mm, dd.dd].
;
; N. Kungsakawin 8/20/2003
;
; Print usage?
  info = size(la)
  type = info[info[0]+1]
  if type lt 1 or 7 lt type then begin
     print,"                                                               "
     print,"  LA2YMD translates its argument, LA time YYYY/DDD-HH:MM:SS    "
     print,"  to a double-precision calendar date triple                   "
     print,"  of the form [yyyy, mm, dd.dd]. The argument may be a scalar  "
     print,"  or array of a 4-byte or 8-byte numerical type.               "
     print,"                                                               "
     print,"  ymd = la2ymd( la )                                           "
     return,''
  endif
;
  return, yd2ymd(jd2yd(la_to_jd(la)))
;
  end

