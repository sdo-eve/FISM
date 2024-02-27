; main_program xud2jd
;
; Unit tester for ud2jd.pro and jd2ud.pro
;
; B. Knapp, 1997-11-13
;           1998-06-09, IDL v. 5 compliance
;
; Generate an array of random UARS dates
  n = 1000L
  ud = randomu( seed, n )*2500.d0
;
  jd = ud2jd( ud )
  u2 = jd2ud( jd )
;
  du = where( ud ne u2, nd )
  if nd gt 0 then begin
     for j=0,nd-1 do $
        print,ud[j],u2[j],ud[j]-u2[j],format="(2f25.10,e12.3)"
     print, 'Test failed!'
  endif else begin
     print, 'Test passed.'
  endelse
;
  end
