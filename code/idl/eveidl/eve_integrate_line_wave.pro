;docformat = 'rst'

;+
;Integrate an irradiance from wave_min to wave_max, using an arbitrary
;wavelength scale
;
;This does an integration of a wavelength range with no instrument 
;sensitivity weighting. This is a "line". If you need instrument 
;sensitivity, use integrate_band().
;
;This uses the Midpoint rule to integrate - Each bin is considered to be 
;centered at its wavelength, and the measurement is considered to be the 
;mean measurement over the bin.
;
;:Params:
;  wave_min: in, required
;    minimum wavelength of the line in question, in nanometers
;  wave_max: in, required
;    maximum wavelength
;  irradiance_in: in, required
;    measurement, (W/m^2)/nm
;  wave: in, required
;    center wavelength of each bin of the irradiance in nanometers
;    
;:Keywords:
;  neg: in, optional
;    if set, ignore negative values. Treat them as
;    zero in the integration. If not set, return -1 if any bins
;    are negative.
;:returns:
;  integrated measurement or integrated uncertainty in measurement between the wavelength 
;  units. Since input is in (W/m^2)/nm, output is in W/m^2
;:Categories:
;  user
;-
function eve_integrate_line_wave,wave_min,wave_max,irradiance_in,wave,neg=neg

  ; for integration, replace all fill values with zero
  ; work with a copy of the data
  irradiance = irradiance_in
  ; replace fill values
  x=where(irradiance lt -0.9,n_x)
  if n_x gt 0 then irradiance[x]=-1.

  bin_min=max(where(wave lt wave_min))
  bin_max=min(where(wave ge wave_max))
  if bin_min lt 0 or bin_max lt 0 then return, -1.0
  if bin_min eq bin_max then return,-1.0
;  print,bin_min,bin_max
  delta_lambda=wave[bin_min+1]-wave[bin_min]
  ;Check if any negative values are included, if so we can't integrate
  ;so return a fill value
  ig=indgen(n_elements(irradiance))
  w=where(irradiance lt 0 and ig ge bin_min and ig le bin_max,count)
  
  if count gt 0 then begin
    if keyword_set(neg) then begin
      irradiance[w]=0
    end else begin
      return,-1
    end
  end
  
  return,delta_lambda*total(irradiance[bin_min:bin_max])
end

