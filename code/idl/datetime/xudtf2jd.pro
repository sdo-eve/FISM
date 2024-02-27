; main_program xudtf2jd
;
; Unit tester for udtf2jd.pro
;
; B. Knapp, 1997-11-14
;           1998-08-31, make 1900 Jan 1.0 the epoch for UDTF format
;
; RCS tags
;
; $Header: /export/timed/CVS//production/science_dp/external_lib/datetime/xudtf2jd.pro,v 9.1 2016/10/28 16:32:00 see_sw Exp $
;
; $Log: xudtf2jd.pro,v $
; Revision 9.1  2016/10/28 16:32:00  see_sw
; update
;
; Revision 10.0  2007/05/08 19:01:12  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:22:31  see_sw
; commit of version 9.0
;
; Revision 8.1  2005/06/13 16:48:21  dlwoodra
; v8
;
; Revision 7.0  2003/03/18 20:02:47  dlwoodra
; commit for version 7.0
;
; Revision 1.1  2003/03/18 20:00:11  dlwoodra
; initial commit
;
; Revision 1.1  2003/02/14 18:48:00  dlwoodra
; initial commit
;
; Revision 1.2  2002/01/08 23:00:20  knapp
; Modify to make the tests round-trip pass-fail tests
;
;
  udtf = [97318L, 60000000L]
; 
; Single date yd, ms
  jd1 = udtf2jd( udtf[0], udtf[1] )
  udtf1 = jd2udtf( jd1 )
  fail = where( udtf ne udtf1, nFail1 )
;
; Single date [yd,ms]
  jd2 = udtf2jd( udtf )
  udtf2 = jd2udtf( jd2 )
  fail = where( udtf ne udtf2, nFail2 )
;
; Multiple dates, two arrays
  n = 5
  yd = replicate( udtf[0], 5 )
  ms = 60000000L+lindgen(5)*1000
  udtf_v = transpose( [ [yd],[ms] ] )
  jd3 = udtf2jd( yd, ms )
  udtf3 = jd2udtf( jd3 )
  fail = where( udtf_v ne udtf3, nFail3 )
;
; Multiple dates, two-dimensional array
  jd4 = udtf2jd( udtf_v )
  udtf4 = jd2udtf( jd4 )
  fail = where( udtf_v ne udtf4, nFail4 )
;
; All tests must pass
  if nFail1 gt 0 or nFail2 gt 0 or nFail3 gt 0 or nFail4 gt 0 then $
     print, 'Fail!' $
  else $
     print, 'Pass.'
  end
