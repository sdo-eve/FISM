;
; Path of EVE data:
;     ~/EVE/data/level2/YYYY/DOY/
;         YYYY is the year directory
;         DOY is the Day of Year directory
;
; Will get both the EVL* and EVS* files
;

pro get_eve_data, timerange = timerange, year=year, doy=doy, testing=testing

; Determine current working directory
  ;if not keyword_set(testing) then wd = curdir()
  ;x = test_dir( '~/EVE/data/level2/'+strtrim(year,2)+'/'+doy+'/')
; Check if EVE_DATA directory exists. If not, create it
  ;if ( x eq 0 ) then spawn, 'mkdir ~/EVE/data/level2/'+strtrim(year,2)+'/'+doy+'/'
  spawn, 'mkdir ~/EVE/data/level2/'+strtrim(year,2)+'/'+doy+'/'
; CD into EVE_DATA directory
  cd, '~/EVE/data/level2/'+strtrim(year,2)+'/'+doy+'/'
; Create EVE object
  ;e = obj_new( 'eve' )
  ;files = e -> search( timerange[ 0 ], timerange[ 1 ] )
; Check if files already exist
  ;file_string = strmid( files, 76, 31 )
  ;index = file_exist( file_string )
  ;y = where( index eq 0 )
; Copy over all files that don't exist
  ;if ( y[ 0 ] eq -1 ) then print, '% All files are present and correct.' else begin
    ;print, '% Copying files withing specified time range...'
    ;if keyword_set(testing) then begin
       print, 'Copy and paste the following line into a new terminal to get EVE testing data (LASP/VPN must be on): '
       ;print, 'scp -r chamberlin@evesci4:/eve_analysis/testing/data/'+strtrim(year,2)+'/'+doy+'/'+' ~/EVE/data/level2/'+strtrim(year,2)+'/'+doy+'/'
       spawn, 'scp -r chamberlin@evesci4:/eve_analysis/testing/data/'+strtrim(year,2)+'/'+doy+'/'+' ~/EVE/data/level2/'+strtrim(year,2)+'/'+doy+'/'
stop
    ;endif else begin
    ;      sock_copy, files[ y ]
    ;endelse
  ;endelse
; Change back to working directory
 ; cd, wd

end
