  function gps2la, gps
;
; Convert double precision GPS (TAI) seconds since 1980 Jan 6.0 to
; LA time YYYY/DDD-HH:MM:SS
;
; N. Kungsakawin 8/20/2003
;
; Show usage?
  info = size(gps)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                              "
     print," GPS2LA translates double precision GPS (TAI) seconds         "
     print," since 1980 Jan 6.0 to LA time YYYY/DDD-HH:MM:SS              "
     print,"                                                              "
     print," la = gps2la(gps)                                             "
     return,''
  endif
;
  jd_to_la,gps2jd(gps),s
  return, s  
end

