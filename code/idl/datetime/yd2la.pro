  function yd2la, yd
;
; Translates Gregorian calendar dates of the form yyyyddd.dd to LA time
; YYYY/DDD-HH:MM:SS
;
; N. Kungsakawin 8/20/2003
;
; Print usage?
  info = size(yd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  YD2LA translates its argument of the form yyyyddd.dd to      "
     print,"  LA time YYYY/DDD-HH:MM:SS                                    "
     print,"                                                               "
     print,"  la = yd2la( yd )                                             "
     return,''
  endif
  
  jd_to_la,yd2jd(yd),la
  return, la
  end
