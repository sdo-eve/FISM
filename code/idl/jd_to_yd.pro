FUNCTION jd_to_yd, jd
;
; $Id: jd_to_yd.pro,v 8.1 2006/01/23 23:00:12 dlwoodra Exp $
;
; Given a Julian Day number, returns the corresponding
; longword date of the form yyyyddd.ddd.

; B. G. Knapp, 87/02/06

  d = jd+1931000.5D0
  c = LONG(d/36524.25D0)
  d = d+c-LONG(c/4)
  y = LONG(d/365.250001D0)
  RETURN,(y-9999L)*1000L+(d-LONG(y*365.25D0))

END
