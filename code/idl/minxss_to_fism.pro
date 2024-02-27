; Run in SolarSoft!

pro minxss_to_fism

; Restore MinXSS 1 merged file
; Downloaded from MinXSS Dropbox (see MinXSS website)
restore, '$fism_data/minxss/minxss1_l1_mission_length.sav'

; Define wavelength scale, in nm, to bin MinXSS data when converting
; to watts
;energy conversion factor = Planck's constant * speed of light in vaccum
PLANCK_CONSTANT = 6.626069d-34 ; J - sec
SPEED_OF_LIGHT  = 2.997924d8   ; m / sec
HC_PRODUCT = PLANCK_CONSTANT * SPEED_OF_LIGHT / 1.d-9 ; J - nm
joule_to_ev=6.242d15; keV
minxss_wv_nm=HC_PRODUCT/minxsslevel1[0].energy*joule_to_ev

; Convert ph to watts
nwvs_minxss=n_elements(minxsslevel1[0].irradiance)
nmeas_minxss=n_elements(minxsslevel1.time.sod)
minxss_irr_watts=fltarr(nwvs_minxss,nmeas_minxss)
; find the keV and nm bandpass to convert form /keV to /nm data
kev_bandpass=median(minxsslevel1[0].energy-shift(minxsslevel1[0].energy,1))
nm_bandpass=(abs(minxss_wv_nm-shift(minxss_wv_nm,-1))+abs(minxss_wv_nm-shift(minxss_wv_nm,-1)))/2
for i=0,nmeas_minxss-1 do begin
   minxss_irr_watts[*,i]=ph2watt(minxss_wv_nm,(minxsslevel1[i].irradiance*kev_bandpass)/nm_bandpass)
endfor

minxss_wv_nm_1a=findgen(50)/10+0.05 ; Setup final 1a wv bins
nwvs_1a=n_elements(minxss_wv_nm_1a)
minxss_irr_watts_1a=fltarr(nwvs_1a,nmeas_minxss)
for i=0,nmeas_minxss-1 do begin
   for j=0,nwvs_1a-1 do begin
      stop
      minxss_irr_watts_1a[j,i]=eve_integrate_line_wave(minxss_wv_nm_1a[j]-0.05,minxss_wv_nm_1a[j]+0.05, $
          minxss_irr_watts[*,i],minxss_wv_nm)
   endfor
endfor


stop

end
