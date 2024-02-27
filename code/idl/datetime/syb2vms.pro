  function syb2vms, syb

; Given date(s) as SYB time YYYY/DDD-HH:MM:SS,
; return string(s) of the form 'dd-mmm-yyyy hh:mm:ss.ss'.

; B. Knapp, 2003-11-25

; Print usage?
  info = size(syb)
  type = info[info[0]+1]
  if type lt 1 or 7 lt type then begin
    print,"                                                               "
    print,"  SYB2VMS translates Sybase time 'Mmm dd yyyy hh:mm:ss.sssAM'  "
    print,"  (or PM) to VMS time of the form 'dd-mmm-yyyy hh:mm:ss.ss'.   "
    print,"  The input argument may be a scalar or array.                 "
    print,"                                                               "
    print,"  vms = syb2vms( syb )                                         "
    return,''
  endif
;
  s = ymd2vms( syb2ymd( syb ) )
;
; Return scalar or string?
  if info[0] ne 0 and n_elements(syb) eq 1 then $
    return,[s] $
  else $
    return,s
;
  end
