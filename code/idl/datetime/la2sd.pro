  function la2sd, la
;
; Translates LA time YYY/DDD-HH:MM:SS to double precision
; SORCE mission day.
;
; N. Kungsakawin 8/20/2003
;
; Print usage?
  info = size(la)
  type = info[info[0]+1]
  if type lt 1 or 7 lt type then begin
     print,"                                                              "
     print," LA2SD translates its argument, LA time YYYY/DDD-HH:MM:SS     "
     print," to a double-precision SORCE mission day      "
     print," number, where SORCE day 0.0 = 2003/024.0 = 2003 Jan 24.0.    "
     print," The argument may be a scalar or array.                       "
     print,"                                                              "
     print," sd = la2sd( la )                                             "
     return,''
  endif
;
  s = jd2md(la_to_jd(la),2003024);
; Return scalar or string?
  if info[0] ne 0 and n_elements(la) eq 1 then $
     return,[s] $
  else $
     return,s
;
  end


