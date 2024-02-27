  function yd2gps, yd
;
; Translates Gregorian calendar dates of the form yyyyddd.dd to 
; double precision TAI seconds since the GPS epoch (1980 Jan
; 6.0).
;
; N. Kungsakawin, 03.04.07
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(yd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  YD2GPS translates its argument of the form yyyyddd.dd to     "
     print,"  double precision TAI seconds since the GPS epoch (1980 Jan   "
     print,"  6.0)                                                         "
     print,"  scalar or array.                                             "
     print,"                                                               "
     print,"  gps = yd2gps(yd)                                             "
     return,''
  endif
;
  return, jd2gps( yd2jd( yd ) )  
;
  end
