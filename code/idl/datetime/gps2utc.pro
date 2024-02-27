  function gps2utc, gps
;
; Returns the UTC clock time (elapsed seconds since 1980 Jan 6.0)
; given the GPS time (elapsed TAI seconds since 1980 Jan 6.0).
;
; B. Knapp, 2001-05-15
;
; $Header: /export/timed/CVS//production/science_dp/external_lib/datetime/gps2utc.pro,v 9.1 2016/10/28 16:30:04 see_sw Exp $
;
; $Log: gps2utc.pro,v $
; Revision 9.1  2016/10/28 16:30:04  see_sw
; update
;
; Revision 10.0  2007/05/08 19:01:10  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:22:29  see_sw
; commit of version 9.0
;
; Revision 8.2  2005/06/13 15:47:25  turkk
; commit for v8 release
;
; Revision 1.2  2003/05/30 22:20:12  knapp
; Fix handling of array arguments
;
;
; GPS epoch
  jd0 = yd2jd(1980006.d0)
  dTAI0 = tai_utc(jd0)
  dTAI = dblarr(n_elements(gps))
;
; Assume the argument is UTC, then iterate until the correct dTAI
; is found
  jd1 = jd0 + gps/8.64d4
  dTAI1 = tai_utc(jd1)-dTAI0
  jd2 = jd1 - dTAI1/8.64d10
  dTAI2 = tai_utc(jd2)-dTAI0
  p1 = where(dTAI2 eq dTAI1, np1)
  if np1 gt 0 then dTAI[p1] = dTAI2[p1]
;
  p2 = where(dTAI2 ne dTAI1, np2)
  if np2 gt 0 then begin
    jd3 = jd1-dTAI2/8.64d10
    dTAI3 = tai_utc(jd3)-dTAI0
    p3 = where(dTAI3 eq dTAI2, np3)
    if np3 gt 0 then dTAI[p3] = dTAI3[p3]
;
    p4 = where(dTAI3 ne dTAI2, np4)
    if np4 gt 0 then begin
      jd4 = jd1-dTAI3/8.64d10
      dTAI[p4] = (tai_utc(jd4)-dTAI0)[p4]
    endif
  endif
;
  result = gps-dTAI/1.d6
  if (size(gps))[0] eq 0 then $
    return, result[0] $
  else $
    return, result
  end
