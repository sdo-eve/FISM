;+
; NAME:
;   get_current_yyyydoy
;
; PURPOSE:
;   provide mechanism for calculating the current yyyydoy that
;   handles year boundaries and leap years
;
; CATEGORY:
;   Library
;
; CALLING SEQUENCE:
;   cyyyydoy = get_current_yyyydoy()
;
; INPUTS:
;
; OUTPUTS:
;   cyyyydoy is returned in year day-of-year format
;
; COMMON BLOCKS:
;   none
;
; RESTRICTIONS:
;   none
;
; PROCEDURE:
;   1) Calculate and return cyyyydoy
;
; MODIFICATION HISTORY:
; 10/18/04 Matt Kelly Original File Creation
;

function get_current_yyyydoy

date=bin_date(systime(/utc))
yyyydoy = ymd2yd(date[0],date[1],date[2])

return,yyyydoy

end
