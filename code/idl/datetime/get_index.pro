  function get_index, miss=miss_value, help=help
;
; Read  "solar_index.dat" data file and return all data in a stucture
; of arrays--each index in its own array--with common timetag arrays,
; and with all missing data represented by the value miss_value.
;
; B. Knapp, 1996-02-12
;
  compile_opt idl2
;
; Change log:
;
; B. Knapp, 1998-06-09, IDL v. 5 compliance
;           1999-01-12, Add Sunspot Number
; T. Rood,  1999-07-26, Change sunos data_dir path, eliminate lymang from
;                       output structure and rename lyman1 to lyman
; B. Knapp, 1999-08-04, Remove VMS support & accomodate Halley installaltion
; T. Rood,  1999-10-20, Add read of three SNOE X-ray measurements, snoe2_7,
;                       snoe7_17, and snoe17_20 from solar_index.dat.
; T. Rood,  2000-01-05, Now output t and tyr as double precision,
;                       instead of single precision, floating point
;                       numbers.
; T. Rood,  2000-01-13, Now use the  $solndx_data environment variable
;                       instead of a hard coded directory to define
;                       data_dir.
; T. Rood,  2000-10-27, Changed the output from a named to an anonymous
;                       structure.
; G. Goehle, 2000-12-11, Corrected snoe range from 7-17 to 6-19
; B. Knapp, 2002-09-30, Fix where() results of -1 with "if np gt 0..."
; D. Woodraska 2007-04-20 Modified to use SEE environment variable


; Host-dependent parameters
  data_dir = '$see_solndx_data/'
;
  if keyword_set( help ) then begin
     print,' '
     print,' GET_INDEX is a function which returns all of the solar'
     print,' activity indices from the associated variable data file'
     print,' solar_index.dat.  The data are returned in a structure,'
     print,' of arrays, each index in its own array, along with two'
     print,' common timetag arrays.  Missing data are optionally'
     print,' replaced by a user-specified missing value flag.  The'
     print,' fields (arrays) are named as follows:'
     print,'  '
     print,' lyman         = SME/UARS SOLSTICE Lyman Alpha (photons/sec/cm^2)'
     print,' ssn           = International Sunspot Number'
     print,' ten7          = Ottawa/Penticton 10.7 cm radio flux'
     print,' ap            = Fredericksburg Ap geomagnetic activity index'
     print,' hei           = Kitt Pk He-I 1083 nm full disk irr. eq. wid.'
     print,' magbav        = Full disk Mag. field |B|av (gauss)'
     print,' noaa_mgii     = NOAA Mg-II Core/Wing Index'
     print,' solstice_mgii = SOLSTICE Mg-II Core/Wing Index'
     print,' ps            = Sunspot Blocking Factor (J. Lean)'
     print,' acrim         = ACRIM Total Irradiance'
     print,' acrsd         = ACRIM Std. Dev.'
     print,' xray          = GOES X-ray background (W/m^2)'
     print,' snoe2_7       = SNOE 2-7 nm X-ray irradiance (ergs/sec/cm^2)'
     print,' snoe6_19      = SNOE 6-19 nm X-ray irradiance (ergs/sec/cm^2)'
     print,' snoe17_20     = SNOE 17-20 nm X-ray irradiance (ergs/sec/cm^2)'
     print,' '
     print,' tyd           = Time (YYYYDDD format)'
     print,' tyr           = Time (year.fraction) for plotting'
     print,'  '
     print,' Usage (keyword arguments optional):'
     print,' '
     print,'     solar_indices = get_index( miss=miss_value, /help )'
     return,' '
  endif
;
  get_lun, lun
  openr, lun, data_dir+'solar_index.dat',/swap_if_big_endian
  finfo = fstat( lun )
  n_rows = 17L
  n_elts = finfo.size/(4*n_rows)
  a = assoc( lun, fltarr( n_elts ) )
  tyd = double(a[0])
  lyman = a[1]
  ten7 = a[2]
  hei = a[3]
  noaa_mgii = a[4]
  ps = a[5]
  acrim = a[6]
  acrsd = a[7]
  tyr = 1900d + double(a[8])
  magbav = a[9]
  ap = a[10]
  xray = a[11]
  solstice_mgii=a[12]
  ssn=a[13]
  snoe2_7 = a[14]
  snoe6_19 = a[15]
  snoe17_20 = a[16]
  close, lun
  free_lun, lun
;
; Flag missing data. (Note: this cannot be done in a loop, because
; the criteria for missing data can be different for different
; indices.  For example, a Sunspot Index (Ri) of 0 is a valid value.)
  if n_elements( miss_value ) gt 0 then begin
     p = where(lyman le 0, np)
     if np gt 0 then lyman[p] = miss_value
     p = where(ssn le 0, np)
     if np gt 0 then ssn[p] = miss_value
     p = where(ten7 le 0, np)
     if np gt 0 then ten7[p] = miss_value
     p = where(ap le 0, np)
     if np gt 0 then ap[p] = miss_value
     p = where(hei le 0, np)
     if np gt 0 then hei[p] = miss_value
     p = where(magbav le 0, np)
     if np gt 0 then magbav[p] = miss_value
     p = where(noaa_mgii le 0, np)
     if np gt 0 then noaa_mgii[p] = miss_value
     p = where(solstice_mgii le 0, np)
     if np gt 0 then solstice_mgii[p] = miss_value
     p = where(ps le 0, np)
     if np gt 0 then ps[p] = miss_value
     p = where(acrim le 0, np)
     if np gt 0 then begin
       acrim[p] = miss_value
       acrsd[p] = miss_value
     endif
     p = where(xray le 0, np)
     if np gt 0 then xray[p] = miss_value
     p = where(snoe2_7 le 0, np)
     if np gt 0 then snoe2_7[p] = miss_value
     p = where(snoe6_19 le 0, np)
     if np gt 0 then snoe6_19[p] = miss_value
     p = where(snoe17_20 le 0, np)
     if np gt 0 then snoe17_20[p] = miss_value
  endif
;
; Now construct the array of structures
  return, { lyman: lyman, $
            ssn: ssn, ten7: ten7, ap: ap, $
            hei: hei, magbav: magbav, $
            noaa_mgii: noaa_mgii, solstice_mgii: solstice_mgii, $
            ps: ps, $
            acrim: acrim, acrsd: acrsd, xray: xray, $
            snoe2_7: snoe2_7, snoe6_19: snoe6_19, snoe17_20: snoe17_20, $
            tyd: tyd, tyr: tyr }
;
  end
