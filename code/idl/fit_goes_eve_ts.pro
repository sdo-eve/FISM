function fit_goes_eve_ts, goes_ts, utc, eve_flr_data, eve_daily_data, debug=debug

debug=1
goes_mx_gp=max(goes_ts, wmax_goes_gp)
goes_deriv=deriv(utc, goes_ts)>0.0
goes_mx_ip=max(goes_deriv, wmax_goes_ip)
nwvs=n_elements(eve_flr_data[*,0])
ans=''
p_e_array=fltarr(3,nwvs) ; e_gp(wv), e_ip(wv), p_gp, p_ip
for i=0,nwvs-1 do begin
   eve_wv_ts=smooth(eve_flr_data[i,*]-eve_daily_data[i],3)

   ; Find GP time/thermal shift for GOES
   max_eve=max(eve_wv_ts[wmax_goes_gp:*],wmax_eve) ; make sure after GOES GP Peak
   wmax_eve=wmax_eve>0 ; make sure only positive shifts are allowed
   ; Scale GOES to match EVE at peak of GP and IP as first guess
   goes_ts_gp_st=shift(goes_ts*eve_wv_ts[wmax_goes_gp+wmax_eve]/goes_mx_gp,wmax_eve)
   goes_ts_ip_st=goes_deriv*eve_wv_ts[wmax_goes_ip]/goes_mx_ip
   goes_tot=goes_ts_gp_st+goes_ts_ip_st
   if keyword_set(debug) then begin
      cc=independent_color()
      plot, utc, eve_wv_ts
      oplot, utc, goes_tot, color=cc.red
      oplot, utc, goes_ts_gp_st, color=cc.green
      oplot, utc, goes_ts_ip_st, color=cc.blue
      read, ans, prompt='Next wv?'
   endif


endfor

stop

return, p_e_array

end
