pro f107_penticton_to_save

print, 'Running f107_penticton_to_save ', !stime

; Restore the template file used to read the new CSV file

restore, expand_path('$fism_code') + '/idl/f107_penticton_template.sav'
; Read the new Penticton CSV file

a = read_ascii( $
  expand_path('$f107_proxy') + '/penticton_radio_flux.csv', $
  template = f107_penticton_template )

; Create arrays to hold F10.7 flux and time
; field01 represents julian_day
n_flux_csv = n_elements( a.julian_day )

f107_time_jd_all  = dblarr( n_flux_csv )
f107_time_str_all = strarr( n_flux_csv )
f107_flux_all     = fltarr( n_flux_csv )

; Initialize loop variables

line_str          = ''
f107_flux_last    = 0.0
f107_time_yyyyddd = '0000000'

; Open the CSV file

openr, lun, expand_path('$f107_proxy') + '/penticton_radio_flux.csv', /get_lun

; Read the first line in the CSV file and discard it

readf, lun, line_str

; Loop over remaining lines in CSV file
; Read time (jd), observed flux, and adjusted flux

for i = 0l, n_flux_csv-1 do $
  begin ; for i

  ; Read a line from the CSV file

  readf, lun, line_str

  ; Split line into tokens using ',' as delimiter

  tokens = strsplit(strcompress( line_str ),',',/extract)

  julian_day_str    = tokens[ 0 ]
  f107_flux_obs_str = tokens[ 1 ]
  f107_flux_adj_str = tokens[ 2 ]

  ; Use "adjusted" flux

  f107_flux_str = f107_flux_adj_str

  ; Save the Julian date

  f107_time_jd_all[ i ] = double( julian_day_str )

  ; Convert Julian date to strings:
  ; month, day, year, hours, minutes, seconds

  caldat, double( julian_day_str ), month, day, year, hrs, min, sec

  year_str  = string( year,  format='(i4)')
  month_str = string( month, format='(i2.2)')
  day_str   = string( day,   format='(i2.2)')

  ; Convert year, month and day strings into 'YYYYDDD' format
  ; where 'DDD' is the "day-of-year"

  f107_time_yyyyddd = ymd2yd(year_str, month_str, day_str)

  ; Save 'YYYYDDD' string

  f107_time_str_all[ i ] = strtrim(f107_time_yyyyddd, 2)

  ; Filter flux values from CSV file

  f107_flux_i = float( f107_flux_str )

  if f107_flux_i ge 50.0 $
  then f107_flux_all[ i ] = f107_flux_i $
  else f107_flux_all[ i ] = f107_flux_last

  f107_flux_last = f107_flux_i

  end ; for i

; Eliminate zeros

i_good = where( f107_flux_all gt 0.01 )

f107_time_jd  = f107_time_jd_all[  i_good ]
f107_time_str = f107_time_str_all[ i_good ]
f107_flux     = f107_flux_all[     i_good ]

f107_time_jd_per_day  = [0.0]
f107_time_str_per_day = [' ']
f107_flux_per_day     = [0.0]

; Pick one F10.7 value for each day:
; - if there are two values per day, choose the lesser of the two
; - if there are more than two values per day, choose the median

i_f107_uniq          = uniq( f107_time_str, sort( f107_time_str ))
f107_time_str_uniq   = f107_time_str[ i_f107_uniq ]
n_f107_time_str_uniq = n_elements( f107_time_str_uniq )

;stop ; DEBUG

for i_f107_uniq = 0, n_f107_time_str_uniq-1 do $
  begin ; for i_f107_uniq

  f107_time_str_this_day = f107_time_str_uniq[ i_f107_uniq ]

  i_f107_this_day = where( f107_time_str_this_day eq f107_time_str )

  f107_flux_this_day = f107_flux[  i_f107_this_day ]
  n_flux_this_day    = n_elements( i_f107_this_day )

  ;stop ; DEBUG

  if n_flux_this_day eq 1 then $
    begin
    f107_time_jd_per_day  = [ f107_time_jd_per_day,  f107_time_jd[ i_f107_this_day ] ]
    f107_time_str_per_day = [ f107_time_str_per_day, f107_time_str_this_day          ]
    f107_flux_per_day     = [ f107_flux_per_day,     f107_flux_this_day[ 0 ]         ]
    end

  if n_flux_this_day eq 2 then $
    begin
    f107_flux_this_day_min = min( f107_flux_this_day, i_min )
    f107_time_jd_per_day = $
      [ f107_time_jd_per_day,  f107_time_jd[ i_f107_this_day[ i_min ]] ]
    f107_time_str_per_day = $
      [ f107_time_str_per_day, f107_time_str_this_day                  ]
    f107_flux_per_day = $
      [ f107_flux_per_day,     f107_flux_this_day[ i_min ]             ]
    ;stop ; DEBUG
    end

  if n_flux_this_day ge 3 then $
    begin
    f107_flux_this_day_median = median( f107_flux_this_day )
    i_median = where( f107_flux_this_day_median eq f107_flux_this_day )
    f107_time_jd_per_day = $
      [ f107_time_jd_per_day, f107_time_jd[ i_f107_this_day[ i_median[0]]] ]
    f107_time_str_per_day = $
      [ f107_time_str_per_day, f107_time_str_this_day                      ]
    f107_flux_per_day = $
      [ f107_flux_per_day,     f107_flux_this_day[ i_median[0] ]           ]
    ;stop ; DEBUG
    end

  end ; i_f107_uniq

f107_time_jd_per_day  = f107_time_jd_per_day[  1:*]
f107_time_str_per_day = f107_time_str_per_day[ 1:*]
f107_flux_per_day     = f107_flux_per_day[     1:*]

jd_day_0 = f107_time_jd_per_day[0]
jd_day_n =  f107_time_jd_per_day[-1]
jd_day_all = [jd_day_0:jd_day_n:1.0]


caldat, jd_day_all, month, day, year, hrs, min, sec
ndys = n_elements(jd_day_all)
f107_time_str_per_day = []
for i=0, ndys-1 do begin $
  year_str  = string( year[i],  format='(i4)')
  month_str = string( month[i], format='(i2.2)')
  day_str   = string( day[i],   format='(i2.2)')

; Convert year, month and day strings into 'YYYYDDD' format
; where 'DDD' is the "day-of-year"

  f107_time_str_per_day = [f107_time_str_per_day, ymd2yd(year_str, month_str, day_str)]
endfor

f107_flux_per_day_interp = interpol(f107_flux_per_day, f107_time_jd_per_day, jd_day_all)

ft_time = f107_time_str_per_day
ft      = f107_flux_per_day_interp

fname = expand_path('$f107_proxy') + '/f107_data.sav'
save, ft_time, ft, file=fname
print, 'End Time f107_penticton_to_save: ', !stime

;stop ; DEBUG

end
