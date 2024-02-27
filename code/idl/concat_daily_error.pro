;
; NAME: concat_daily_error.pro
;
; PURPOSE: to concat the UARS based (FUV) and SEE based (EUV) errors into 
;	one error file
;
; MODIFICATION HISTORY:
;	8/30/05	PCC	Program Creation
;	12/01/06 PCC	Updated for MacOSX
;

pro concat_daily_error

print, 'Running concat_daily_error.pro', !stime

restore, expand_path('$fism_save') + '/fism_daily_error_tmp.sav'
fism_sig_uars=fism_sig
fism_sig_abs_uars=fism_sig_abs

;restore, '$fism_save/fism_daily_error_uars.sav'
;fism_sig_uars=fism_sig
;fism_sig_abs_uars=fism_sig_abs
;restore, '$fism_save/fism_daily_error_see_tmp.sav'
;fism_sig[4,119:192]=fism_sig_uars[0,*]
;fism_sig_abs[4,119:192]=fism_sig_abs_uars[0,*]
;fism_sig[0,119:192]=fism_sig_uars[1,*]
;fism_sig_abs[0,119:192]=fism_sig_abs_uars[1,*]
;fism_sig[1,119:192]=fism_sig_uars[2,*]
;fism_sig_abs[1,119:192]=fism_sig_abs_uars[2,*]

print, 'Saving fism_daily_error.sav'
save, fism_sig, fism_sig_abs, file=expand_path('$fism_save') + '/fism_daily_error.sav'

end
