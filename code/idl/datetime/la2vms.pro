  function la2vms, la

; Given date(s) as LA time YYYY/DDD-HH:MM:SS,
; return string(s) of the form 'dd-mmm-yyyy hh:mm:ss.ss'.

; N. Kungsakawin 8/20/2003

; Print usage?
  info = size(la)
  type = info[info[0]+1]
  if type lt 1 or 7 lt type then begin
     print,"                                                               "
     print,"  LA2VMS translates LA time YYYY/DDD-HH:MM:SS to      "
     print,"  VMS date strings of the form 'dd-mmm-yyyy hh:mm:ss.ss'.      "
     print,"  The input argument may be a scalar or array of a 4-byte      "
     print,"  or 8-byte numerical type.                                    "
     print,"                                                               "
     print,"  vms = la2vms( la )                                           "
     return,''
  endif
;
  s = ymd2vms( la2ymd( la ) )
;
; Return scalar or string?
  if info[0] ne 0 and n_elements(la) eq 1 then $
     return,[s] $
  else $
     return,s
;
  end
