  function ud2la, ud
;
; Translates UARS mission day numbers (UARS Day 0.0 = 1991 Sep 11.0) to
; LA time YYYY/DDD-HH:MM:SS
;
; N. Kungsakawin 8/20/2003
;
; Print usage?
  info = size(ud)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  UD2LA translates UARS mission day numbers (UARS Day 0.0 =    "
     print,"  1991/254.0 = 1991 Sep 11.0) to LA time YYYY/DDD-HH:MM:SS     "
     print,"                                                               "
     print,"  la = ud2la( ud )                                             "
     return,''
  endif
;
  jd_to_la,md2jd(ud, 1991254),s
  return, s
;
  end
