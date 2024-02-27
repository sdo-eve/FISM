  function jd2syb, jd

; Given date(s) as Julian Day Number(s) and fraction, return Sybase
; date/time string(s) of the form 'Mmm dd yyyy hh:mm:ss.sssAM' (or PM).

; B. Knapp, 2000-11-25

; Print usage?
  info = size(jd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
    print,"                                                               "
    print,"  JD2SYB translates Julian Day Numbers (and fraction) to       "
    print,"  Sybase date strings of the form 'Mmm dd yyyy hh:mm:ss.sssAM' "
    print,"  (or PM).  The input argument may be a scalar or array of a   "
    print,"  4-byte or 8-byte numerical type.                             "
    print,"                                                               "
    print,"  syb = jd2syb( jd )                                           "
    return,''
  endif
;
  s = ymd2syb( jd2ymd( jd ) )
;
; Return scalar or string?
  if info[0] ne 0 and n_elements(jd) eq 1 then $
    return,[s] $
  else $
    return,s
;
  end
