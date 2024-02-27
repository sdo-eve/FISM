  function syb2ymd, syb

; Translates SYB-formatted date/time string 'dd-mmm-yyyy hh:mm:ss.ss',
; to double-precision array [yyyy,mm,dd.dd]

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  string_type = 7
  info = size(syb)
  type = info[info[0]+1]
  if type ne string_type then begin
    print,"                                                                  "
    print,"  SYB2YMD translates a Sybase-style date/time string of the form  "
    print,"  'Mmm dd yyyy hh:mm:ss.sssAM', e.g., 'Dec 31 1999 12:59:59.999PM'"
    print,"  to a double precision date of the form [yyyy, mm, dd.dd].       "
    print,"  Either a scalar or an array argument is accepted.               "
    print,"                                                                  "
    print,"  ymd = syb2ymd( syb )                                            "
    return,''
  endif
;
  month_names = ['Jan','Feb','Mar','Apr','May','Jun', $
                 'Jul','Aug','Sep','Oct','Nov','Dec']
;
  mname = strmid(syb,0,3)
  d = fix(strmid(syb,4,2))
  yy = fix(strmid(syb,7,4))
  h = fix(strmid(syb,12,2))
  m = fix(strmid(syb,15,2))
  s = double(strmid(syb,18,6))
  ampm = strmid(syb,24,2)
  am = where(ampm eq 'AM' and h eq 12, nam)
  if nam gt 0 then h[am] = h[am]-12
  pm = where(ampm eq 'PM' and h ne 12, npm)
  if npm gt 0 then h[pm] = h[pm]+12
;
  n_elt = info[info[0]+2]
  mm = intarr(n_elt)
  for j=0,11 do begin
     mhave = where(mname eq month_names[j], nhave)
     if nhave gt 0 then mm[mhave] = j+1
  endfor
;
  return, transpose( [[yy],[mm],[d+h/24.d0+m/1440.d0+s/86400.d0]] )
;
  end
