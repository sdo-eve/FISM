  function syb2jd, syb

; Given Sybase-style date/time string 'Mmm dd yyyy hh:mm:ss.sssAM',
; returns double-precision Julian Day Number ddddddd.dd

; B. Knapp, 2003-11-25

; Print usage?
  string_type = 7
  info = size(syb)
  type = info[info[0]+1]
  if type ne string_type then begin
    print,"                                                               "
    print,"  SYB2JD translates its string argument to a double precision  "
    print,"  Julian Day Number.  Either a scalar argument containing      "
    print,"  a string of the form 'Mmm dd yyyy hh:mm:ss.sssAM' (or PM),   "
    print,"  e.g., 'Jan   1 2000  0:00:00.000AM', or an array of such, is "
    print,"  accepted.                                                    "
    print,"                                                               "
    print,"  jd = syb2jd( syb )                                           "
    return,''
  endif
;
  jd = ymd2jd( syb2ymd( syb ) )
;
; Return scalar or array?
  if info[0] eq 0 then $
    return, jd[0] $
  else $
    return, jd
;
  end
