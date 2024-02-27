;+
; NAME:
;  ph2watt
;
; PURPOSE:
;  return irradiance in watts/m^2/nm given photons/cm^2/sec
;
; CATEGORY:
;  web
;
; CALLING SEQUENCE:
;  ph2watt
;
; INPUTS:
;  wave  - array of wavelengths in nm
;  irr_ph - array of irradiances in photons/cm^2/sec
;
; OUTPUTS:
;  irr_w - array of irradiances in watts/m^2/nm
;
; COMMON BLOCKS:
;  none
;
; MODIFICATION HISTORY:
;  02-17-03 DLW Original file creation.
;
;idver='$Id: ph2watt.pro,v 6.0 2003/03/05 19:32:43 dlwoodra Exp $'
;
;-

function ph2watt, wave, irr_ph

  if n_params() ne 2 then begin
    print,' Usage: irr_w = ph2watt( wave, irr_ph )'
    print,'  where'
    print,'    wave is the wavelength in nm (vector or scalar)'
    print,'    irr_ph is irradiance in photons/cm^2/second (same length)'
    print,'    irr_w is irradiance in watts/m^2/nm (same length as inputs)'
    return,-1
  endif

  if n_elements(wave) ne n_elements(irr_ph) then begin
    print,' ERROR: wave and irr_w have different number of elements'
    return,-1
  endif

  ;energy conversion factor = Planck's constant * speed of light in vaccum
  PLANCK_CONSTANT = 6.626069d-34 ; J - sec
  SPEED_OF_LIGHT  = 2.997924d8   ; m / sec
  HC_PRODUCT = PLANCK_CONSTANT * SPEED_OF_LIGHT / 1.d-9 ; J - nm

  phcms=(1d-4)/HC_PRODUCT ;times lambda

  conv=wave*phcms

  return, irr_ph/conv

end
