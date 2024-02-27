  function la2yd, la
;
; Translates LA time YYYY/DDD-HH:MM:SS to Gregorian calendar date
; of the form yyyyddd.dd.  (Note: civil year 1 BC is Gregorian year 0.)
;
; N. Kungsakawin 8/20/2003
;
; Print usage?
  info = size(la)
  type = info[info[0]+1]
  if type lt 1 or 7 lt type then begin
     print,"                                                               "
     print,"  LA2YD translates its argument, LA time YYYY/DDD-HH:MM:SS     "
     print,"  to a double-precision 'longdate' of the form                 "
     print,"  yyyyddd.dd, that is, the year and day-of-year represented as "
     print,"  a numerical scalar.  The argument may be a scalar or array   "
     print,"  of a 4-byte or 8-byte numerical type.                        "
     print,"                                                               "
     print,"  yd = la2yd( la )                                             "
     return,''
  endif
;
; Add 10000 years (to handle negative years to -10000) and subtract LA
; number for day 1.0, year 0, Gregorian proleptic calendar
;  j = la + 3652425.0d0 - 1721059.5d0
;
; What portion of a 400-year cycle do we have?
;  a = j mod 146097.0d0
;
; How many (non-leap year) centuries have elapsed in this cycle?
;  m = floor( (a-366.0d0)/36524.0d0 )
;  z = where( a lt 36890.0d0, nz )
;  if nz gt 0 then m[z] = 0
;
; How many days in the current 4-year cycle have elapsed?
;  b = (a+m) mod 1461.0d0
;
; Determine the number of years elapsed in the 4-year cycle, and the
; number of days in the year
;  n = floor( (b-1)/365.0d0 )
;  d = b-n*365.0d0
;  z = where( b lt 366.0d0, nz )
;  if nz gt 0 then begin
;     n[z] = 0L
;     d[z] = b[z]+1
;  endif
;
; Compute the year, taking back the 10000 year offset
;  y = floor( j/146097.0d0 )*400 + floor( (a+m)/1461.0d0 )*4 + n - 10000L
;
; Construct date of form yyyyddd.dd
;  yd = abs( y )*1000.0d0 + d
;  z = where( y lt 0, nz )
;  if nz gt 0 then yd[z] = -yd[z]
;  return,yd
;

return, jd2yd(la_to_jd(la))
  end
