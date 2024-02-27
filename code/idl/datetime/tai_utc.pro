  function tai_utc, jd
;
; Given a Julian Day Number & fraction (UTC time), returns the
; difference TAI-UTC, in microseconds.
;
; B. Knapp, 2001-05-14, 2001-08-15
;
; $Header: /export/timed/CVS//production/science_dp/external_lib/datetime/tai_utc.pro,v 9.1 2016/10/28 16:31:19 see_sw Exp $
;
; $Log: tai_utc.pro,v $
; Revision 9.1  2016/10/28 16:31:19  see_sw
; update
;
; Revision 10.0  2007/05/08 19:01:11  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:22:30  see_sw
; commit of version 9.0
;
; Revision 8.1  2005/06/13 16:48:17  dlwoodra
; v8
;
; Revision 1.4  2003/06/04 17:41:21  smilkste
; Add keyword force_end_points to interval() call
;
; Revision 1.3  2003/05/30 22:20:18  knapp
; Fix handling of array arguments
;
;
  common tai_utc_save, n_leap, mjdarr, dtarr
;
  if n_elements(n_leap) eq 0 then begin
;
;   Read the file tai-utc.dat (fron USNO) and compute dt at each
;   of the tabulated dates.
;
;   Arrays to hold mjd, dt
    mjdarr = dblarr(128)
    dtarr = lonarr(128)
    n_leap = -1L
;
    mjd = 0.d0
    dt0 = 0.d0
    mjd0 = 0.d0
    df = 0.d0

;   Determine the location of this routine, which is also
;   where the leap second file will be.  It is called tai-utc.dat
    info = routine_info('tai_utc', /functions, /source)
    file = info.path
    p = strpos(strlowcase(file), 'tai_utc.pro')
    strput, file, '-', p+3
    strput, file, '.dat', p+7

    openr, in, file, /get_lun
    in_fmt = "(19x,f5.0,14x,f10.7,12x,f5.0,5x,f9.7)"
    out_fmt = "(f8.0,f12.7,f7.0,f11.7,f12.7)"
    while not eof( in ) do begin
      readf, in, mjd, dt0, mjd0, df, format=in_fmt
      dt = dt0+(mjd-mjd0)*df
;     print, mjd, dt0, mjd0, df, dt, format=out_fmt
      n_leap = n_leap+1
      mjdarr[n_leap] = mjd
      dtarr[n_leap] = nint(dt*1.d6)  ;microseconds
    endwhile
    close,in
    free_lun,in
;
;   Truncate arrays
    mjdarr = mjdarr[0:n_leap]
    dtarr = dtarr[0:n_leap]
;
  endif
;
; Convert our argument to mjd
  mjd = jd-2400000.5d0
;
; Find the last table entry before (each) argument date
  p = interval(mjdarr, mjd, /force_end_points)
  inTable = where(p ge 0, nInTable)
  result = lonarr(n_elements(jd))
  if nInTable gt 0 then result[inTable] = dtarr[p[inTable]]
  if (size(jd))[0] eq 0 then $
    return, result[0] $
  else $
    return, result
;
  end
