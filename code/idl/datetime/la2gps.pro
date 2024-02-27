  function la2gps, la
;
; Convert LA time YYYY/DDD-HH:MM:SS to
; GPS (TAI) seconds since 1980 Jan 6.0 UT.
;
; N. Kungsakawin 8/20/2003
;
; Show usage?
    info = size(la)
    type = info[info[0]+1]
    if type lt 1 or 7 lt type then begin
      print,"                                                              "
      print," LA2GPS translates its argument, LA time YYYY/DDD-HH:MM:SS     "
      print," to a GPS (TAI) seconds since 1980 Jan 6.0 UT.                "
      print,"                                                              "
      print," gps = la2gps( la )                                             "
      return,''
    endif
;
  epoch = 1980006.d0
  return, utc2gps((la_to_jd(la)-yd2jd(epoch))*8.64d4)
;
  end
