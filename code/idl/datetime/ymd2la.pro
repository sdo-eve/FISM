  function ymd2la, y, m, d

; Translates date(s) in the form of [yyyy, mm, dd.dd] to LA time
; YYYY/DDD-HH:MM:SS 

; N. Kungsakawin 8/20/2003

; Input must be three scalars or three 1-dimensional arrays of length n,
; or single 1-dimensional array of length 3, or a 2-dimensional array
; with dimensions [3,n].
  info = size(y)
  case n_params() of
       1:begin
           show_usage = info[1] ne 3
         end
       3:begin
           ny = n_elements(y)
           nm = n_elements(m)
           nd = n_elements(d)
           show_usage = ny ne nm or ny ne nd
         end
    else:show_usage = 1 eq 1
  endcase
  
  if show_usage then begin
     print,"                                                               "
     print,"  YMD2LA translates dates of the form [yyyy, mm, dd.dd] to     "
     print,"  LA time YYYY/DDD-HH:MM:SS                                    "
     print,"  The argument may be a single date (three scalars y, m, d,    "
     print,"  or a 1-dimensional array of length 3) or multiple dates      "
     print,"  (three 1-dimensional arrays of the same length n, or a       "
     print,"  2-dimensional array with dimensions [3,n]).                  "
     print,"                                                               "
     print,"  la = ymd2la( ymd )                                           "
     return,''
  endif
;
  case n_params() of
    1:return, yd2la( ymd2yd( y ) )
    3:return, yd2la( ymd2yd( y, m, d ) )
  endcase
;
  end
