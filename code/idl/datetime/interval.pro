  function interval, x0, x, force_end_points=force_end_points
;
; Given target array x0, strictly monotonic increasing, and query
; array x (no monotonicity requirement), return index array p, s.t.
; x0[p[j]] le x[j] lt x0[p[j]+1], for j=0l,n_elements(x)-1.
;
; B. Knapp, 1997-04-23 (c.f. Numerical Recipes' subroutine Hunt.for)
;           1998-06-09 IDL v. 5 compliance
;
; $Header: /export/timed/CVS//production/science_dp/external_lib/datetime/interval.pro,v 9.0 2017/10/30 14:59:42 see_sw Exp $
;
; $Log: interval.pro,v $
; Revision 9.0  2017/10/30 14:59:42  see_sw
; update
;
; Revision 1.2  2003/06/04 17:39:55  smilkste
; Add keyword force_end_points
;
; Revision 1.1  2003/06/02 20:41:09  knapp
; Initial revision
;
;
  nx0 = n_elements(x0)-1
  nx = n_elements(x)
  p = lonarr(nx)
  jlo = 0L
  jhi = jlo
;
  for j=0l,nx-1 do begin
;
;   Check end points
    if (x[j] le x0[0]) then begin
      if (keyword_set(force_end_points)) then begin
        p[j] = -1
      endif else begin
        p[j] = 0
      endelse
    endif else if (x[j] gt x0[nx0]) then begin
      if (keyword_set(force_end_points)) then begin
        p[j] = nx0
      endif else begin
        p[j] = nx0-1
      endelse
    endif else begin
;
;     Expand search interval to bracket x[j]
      inc = 1L
      while jhi lt nx0 and x[j] ge x0[jhi] do begin ;increase jhi
        jlo = jhi
        jhi = (temporary(jhi)+inc) < nx0
        inc = temporary(inc)*2
      endwhile
      while jlo gt   0 and x[j] lt x0[jlo] do begin ;decrease jlo
        jhi = jlo
        jlo = (temporary(jlo)-inc) >   0
        inc = temporary(inc)*2
      endwhile
;
;     Assert  x0[jlo] le x[j] and x[j] lt x0[jhi] or jlo eq 0 or jhi eq nx0
      if not (x0[jlo] le x[j] and x[j] lt x0[jhi] or jlo eq 0 or jhi eq nx0) $
        then goto, error

;     Use binary search to locate bracketing interval
      while jhi-jlo gt 1 do begin
        m = long((jlo+jhi)/2)
        if x0[m] le x[j] then jlo=m else jhi=m
      endwhile
;
;     Assert  x0[jlo] le x[j] and x[j] lt x0[jhi] or jlo eq 0 or jhi eq nx0
      if not (x0[jlo] le x[j] and x[j] lt x0[jhi] or jlo eq 0 or jhi eq nx0) $
        then goto, error

      p[j] = jlo
    endelse
  endfor
  return,p
;
  error:
  message,' Invariant violation in interval.pro', /info
  return, -1
;
  end
