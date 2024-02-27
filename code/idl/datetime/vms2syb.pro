  function vms2syb, vms

; Given VMS-style date/time string 'dd-mmm-yyyy hh:mm:ss.ss',
; returns Sybase time 'Mmm dd yyyy hh:mm:ss.sssAM' (or PM).

; B. Knapp, 2003-11-25

; Print usage?
  string_type = 7
  info = size(vms)
  type = info[info[0]+1]
  if type ne string_type then begin
     print,"                                                               "
     print,"  VMS2SYB translates its string argument to                    "
     print,"  Sybase time 'Mmm dd yyyy hh:mm:ss.sssAM' (or PM).            "
     print,"                                                               "
     print,"  syb = vms2syb( vms )                                         "
     return,''
  endif
  return, ymd2syb(vms2ymd(vms))
  end
