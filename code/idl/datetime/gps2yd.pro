function gps2yd, gps

; Translates double precision TAI seconds since the GPS epoch (1980 Jan
; 6.0) to year/day-of-year-formatted 

; N. Kungsakawin 03.04.17
;           98.06.09, IDL v. 5 compliance

; Print usage?
  info = size(gps)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  GPS2YD translates its argument, double precision TAI seconds "
     print,"  since the GPS epoch (1980 Jan 6.0) to year and day of year   "
     print,"  for example 2003012   "
     print,"                                                               "
     print,"  vms = gps2yd( gps )                                           "
     return,''
  endif
;
  s = jd2yd(gps2jd(gps))
;
; Return scalar or array?
  if info[0] ne 0 and n_elements(gps) eq 1 then $
     return, [s] $
  else $
     return, s
;
  end
