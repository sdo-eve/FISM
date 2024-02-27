;
; NAME: find_3_prox_1.pro
;
; PURPOSE: to find the p_sc and p_sr proxies for MgII, F10.7, LYA, and GOES
;
; MODIFICATION HISTORY:
;	PCC	11/15/04	Program Creations (separated from 
;				'create_mgft_sc_av_v2.pro)
;	PCC	3/20/05		Eliminated convolution kernal
;				Used as a step to find MgII, F107, and GOES min
;				that are used to find min see sp that are then
;				used to find lya, 33.5, and 36.5 min values to
;				compute thier proxies
;	PCC	12/01/06	Updated for MacOSX
;       VERSION 2_01
;       PCC     5/23/12         Updated for EVE data
;

pro find_3_prox_1

print, 'Running find_3_prox_1.pro', !stime

restore, expand_path('$tmp_dir') + '/prox_sc_sr_pred.sav'

; Find the solar cycle proxies
p_mgii=(mgii/min_mgii)-1.
p_f107=(f107/min_f107)-1.
p_lya=(lya/min_lya)-1.
p_goes=goes_daily_log ; Can't divide by min as min=0

;stop
print, 'Saving proxies_1.sav'
fname = expand_path('$tmp_dir') + '/proxies_1.sav'
save, day_ar_all, p_mgii, p_f107, p_goes, p_lya, $ 
	file=fname
print, 'End Time find_3_prox_1: ', !stime

end
