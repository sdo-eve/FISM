;
;  NAME: create_mgft_sc_av_pred.pro
;
;  PURPOSE: to create the n-day trailing solar cycle average of the mgii and 
;	f107 proxies, p_sc for all days for FISM prediction
;
;  MODIFICATION HISTORY:
;	PCC	7/22/04		Program Creation
;	PCC	7/25/04		Added GOES proxies
;	PCC	11/15/04	Version 2, uses sc 54 day average then sr residual
;	PCC	3mean(/8/05		Updated to use the GOES proxy as [(log GOES)+8]>0.
;				Added max proxy values to saveset
;	PCC	12/01/06	Updated for MacOSX
;
;       VERSION 02_01
;       PCC     05/23/12        Updated to be based on the SDO/EVE data


pro create_mgft_sc_av_pred,st_yd=st_yd, end_yd=end_yd, today=today

print, 'Running create_mgft_sc_av_pred.pro', !stime

; Get the day range 
cur_yd=get_current_yyyydoy()
if not keyword_set(st_yd) then st_yd=1947045
if not keyword_set(end_yd) then end_yd=cur_yd-1
if keyword_set(today) then st_yd=cur_yd-1

; Create an array of every day from st_yd until present
tmp_yd=st_yd
day_ar_all=tmp_yd
while tmp_yd lt end_yd do begin
	tmp_yd=get_next_yyyydoy(tmp_yd)
	day_ar_all=[day_ar_all,tmp_yd]
endwhile
ndys_all=n_elements(day_ar_all)

; Restore to find the # of days to get the trailing average
restore, expand_path('$tmp_dir') + '/eve_sc_av.sav'

;
;       Get the F10.7 index
;
;restore, expand_path('$fism_data') + '/lasp/f10_7_merged/f107_data.sav'
;new path with new data source
restore, expand_path('$f107_proxy') + '/f107_data.sav'
gd=where(ft_time ge st_yd and ft_time le end_yd) ;(indx_tmp.tyd ge ft_str and indx_tmp.tyd le end_yd)
;print, ft_time
t=ft_time[gd]
;plot, t
;print, t
f107_data=ft[gd] ;indx_tmp.ten7[gd]
;print, f107_data
;Find the previous n-day average - Using this so the predicted
;  spectrum can be found for the current day (except for 1st n-days)
n_days=n_elements(f107_data)
; create the sc n-day average
f107_sc_av=fltarr(n_days)
if center_av eq 0 then begin
	strt_avg_f107=mean(f107_data[0:(sc_avg_dys-1)])
	f107_sc_av[0:(sc_avg_dys-1)]=strt_avg_f107
	for k=sc_avg_dys,n_days-1 do f107_sc_av[k]=mean(f107_data[(k-sc_avg_dys):k])
endif else begin
	f107_sc_av=smooth(f107_data,sc_avg_dys,/edge_truncate)
	;print, f107_sc_av
endelse
f107_sr_res=f107_data-f107_sc_av

; find the minimum <f107>avg_dys for proxies
;get_f10_7, 1947045, 2005070, f107_dat_mm, t_mm, /fix_missing
t_mm=ft_time ;indx_tmp.tyr
f107_dat_mm=ft ;indx_tmp.ten7
max_f107=max(f107_sc_av, min=min_f107)
max_f107_abs=max(f107_dat_mm, min=min_f107_abs)

;
t_yd=t ;fix(yfrac_to_yd(t),type=3)
strt_ed=where(t_yd ge st_yd and t_yd le end_yd)
t_yd=t_yd[strt_ed]
f107_sc_av=f107_sc_av[strt_ed]
f107_sr_res=f107_sr_res[strt_ed]
f107=f107_data[strt_ed]

;	
; Get MgII index
;
;indtmp=read_dat('$fism_data/mgii/mgii_index.dat',/silent) 
restore, expand_path('$fism_data') + '/lasp/mgii/mgii_idx.sav'
;ymd_to_yd, indtmp[0,*], indtmp[1,*], indtmp[2,*], mgii_yd
;Interpolate bad days
;gd_mgii=where(indtmp[4,*] gt 0.)
mgii_data=dblarr(2,n_elements(mgii_ind))
mgii_data[0,*]=mgii_yd
mgii_data[1,*]=mgii_ind

;Find the previous n-day average - Using this so the predicted
;  spectrum can be found for the current day (except for 1st n-days)
n_days_mg=n_elements(mgii_data[0,*])
mgii_sc_av=fltarr(n_days_mg)
if center_av eq 0 then begin
	strt_avg_mgii=mean(mgii_data[1,0:(sc_avg_dys-1)])
	mgii_sc_av[0:(sc_avg_dys-1)]=strt_avg_mgii
	for k=sc_avg_dys,n_days_mg-1 do mgii_sc_av[k]=mean(mgii_data[1,(k-sc_avg_dys):k])
endif else begin
	mgii_sc_av=smooth(reform(mgii_data[1,*]),sc_avg_dys,/edge_truncate)
endelse
mgii_sr_res=mgii_data[1,*]-mgii_sc_av

; find the minimum <mgii>avg_dys for proxies
max_mgii=max(mgii_sc_av, min=min_mgii)
max_mgii_abs=max(mgii_data[1,*], min=min_mgii_abs)

;Remove days prior 
strt_ed=where(mgii_data[0,*] ge st_yd and mgii_data[0,*] le end_yd)
mgii_yd=mgii_data[0,strt_ed]
mgii_sc_av=mgii_sc_av[strt_ed]
mgii_sr_res=mgii_sr_res[strt_ed]
mgii=mgii_data[1,strt_ed]

;
;   Get the GOES index
;
restore, expand_path('$fism_save') + '/goes_daily_pred.sav'
goes_day_arr=dy_ar
n_days_gs=n_elements(goes_day_arr)
goes_sc_av=fltarr(n_days_gs)
strt_avg_goes=mean(goes_daily_l[0:(sc_avg_dys-1)])
goes_sc_av[0:(sc_avg_dys-1)]=strt_avg_goes
for k=sc_avg_dys,n_days_gs-1 do goes_sc_av[k]=mean(goes_daily_l[(k-sc_avg_dys):k])
goes_sr_res=goes_daily_l-goes_sc_av
max_goes_l=max(goes_daily_l, min=min_goes_l)

;Get [log(GOES)+9]>0 data
goes_daily_log=(alog10(goes_daily_l>1.0e-9)+9.)>0. ; [(log GOES)+9]>0.
goes_sc_av_log=fltarr(n_days_gs)
if center_av eq 0 then begin
	strt_avg_goes_log=mean(goes_daily_log[0:(sc_avg_dys-1)])
	goes_sc_av_log[0:(sc_avg_dys-1)]=strt_avg_goes_log
	for k=sc_avg_dys,n_days_gs-1 do goes_sc_av_log[k]=mean(goes_daily_log[(k-sc_avg_dys):k])
endif else begin
	goes_sc_av_log=smooth(goes_daily_log,sc_avg_dys,/edge_truncate)
endelse
goes_sr_res_log=goes_daily_log-goes_sc_av_log
max_goes_log=max(goes_daily_log, min=min_goes_log)


;Remove days in order to fit start/end day range
strt=where(goes_day_arr eq st_yd)
ed=where(goes_day_arr eq end_yd)
if ed[0] eq -1 then ed=n_elements(goes_day_arr)-1
if strt[0] ne -1 then begin
	goes_yd=goes_day_arr[strt:ed]
	goes_sc_av=goes_sc_av[strt:ed]
	goes_sc_av_log=goes_sc_av_log[strt:ed]
	goes_sr_res=goes_sr_res[strt:ed]
	goes_sr_res_log=goes_sr_res_log[strt:ed]
	goes_daily_l=goes_daily_l[strt:ed]
	goes_daily_log=goes_daily_log[strt:ed]
endif else begin
	goes_yd=goes_day_arr
endelse

;
;       Get the Lya index
;
restore, expand_path('$fism_data') + '/lasp/lyman_alpha/lya_index.sav'
n_days=n_elements(lya_data)

;Find the previous n-day average - Using this so the predicted
;  spectrum can be found for the current day (except for 1st n-days)
n_days=n_elements(lya_data)
; create the sc n-day average
lya_sc_av=fltarr(n_days)
if center_av eq 0 then begin
	strt_avg_lya=mean(lya_data[0:(sc_avg_dys-1)])
	lya_sc_av[0:(sc_avg_dys-1)]=strt_avg_lya
	for k=sc_avg_dys,n_days-1 do lya_sc_av[k]=mean(lya_data[(k-sc_avg_dys):k])
endif else begin
	lya_sc_av=smooth(lya_data,sc_avg_dys,/edge_truncate)
endelse
lya_sr_res=lya_data-lya_sc_av

; find the minimum <lya>avg_dys for proxies
max_lya=max(lya_sc_av, min=min_lya)
max_lya_abs=max(lya_data, min=min_lya_abs)

;  Remove beginning days 
strt_ed=where(t_yd_l ge st_yd and t_yd_l le end_yd)
t_yd_l=t_yd_l[strt_ed]
lya_sc_av=lya_sc_av[strt_ed]
lya_sr_res=lya_sr_res[strt_ed]
lya=lya_data[strt_ed]

; Loop through every day an insert proxies into array
;	if present, if not enter -999.00
tmp_yd=st_yd
gd_cnt=0
nel=ndys_all
goes_sc_av_tmp=fltarr(nel)
goes_sc_av_log_tmp=fltarr(nel)
goes_sr_res_tmp=fltarr(nel)
goes_sr_res_log_tmp=fltarr(nel)
goes_daily_l_tmp=fltarr(nel)
goes_daily_log_tmp=fltarr(nel)
mgii_sc_av_tmp=fltarr(nel)
mgii_sr_res_tmp=fltarr(nel)
mgii_tmp=fltarr(nel)
f107_sc_av_tmp=fltarr(nel)
f107_sr_res_tmp=fltarr(nel)
f107_tmp=fltarr(nel)
lya_sc_av_tmp=fltarr(nel)
lya_sr_res_tmp=fltarr(nel)
lya_tmp=fltarr(nel)
while tmp_yd le end_yd do begin
	wf10=where(t_yd eq tmp_yd)
	if wf10[0] eq -1 then begin
		f107_sc_av_tmp[gd_cnt]=-999.0
		f107_sr_res_tmp[gd_cnt]=-999.0
		f107_tmp[gd_cnt]=-999.0
	endif else begin
		f107_sc_av_tmp[gd_cnt]=f107_sc_av[wf10]
		f107_sr_res_tmp[gd_cnt]=f107_sr_res[wf10]
		f107_tmp[gd_cnt]=f107[wf10]
	endelse	
	wmgii=where(mgii_yd eq tmp_yd)
	if wmgii[0] eq -1 then begin
		mgii_sc_av_tmp[gd_cnt]=-999.00
		mgii_sr_res_tmp[gd_cnt]=-999.00
		mgii_tmp[gd_cnt]=-999.00
	endif else begin
		mgii_sc_av_tmp[gd_cnt]=mgii_sc_av[wmgii]
		mgii_sr_res_tmp[gd_cnt]=mgii_sr_res[wmgii]
		mgii_tmp[gd_cnt]=mgii[wmgii]
	endelse
	wgoes=where(goes_yd eq tmp_yd)
	if wgoes[0] eq -1 then begin
		goes_sc_av_tmp[gd_cnt]=-999.00
		goes_sc_av_log_tmp[gd_cnt]=-999.00
		goes_sr_res_tmp[gd_cnt]=-999.00
		goes_sr_res_log_tmp[gd_cnt]=-999.00
		goes_daily_l_tmp[gd_cnt]=-999.00
		goes_daily_log_tmp[gd_cnt]=-999.00
	endif else begin
		goes_sc_av_tmp[gd_cnt]=goes_sc_av[wgoes]
		goes_sc_av_log_tmp[gd_cnt]=goes_sc_av_log[wgoes]
		goes_sr_res_tmp[gd_cnt]=goes_sr_res[wgoes]
		goes_sr_res_log_tmp[gd_cnt]=goes_sr_res_log[wgoes]
		goes_daily_l_tmp[gd_cnt]=goes_daily_l[wgoes]
		goes_daily_log_tmp[gd_cnt]=goes_daily_log[wgoes]
	endelse	
	wlya=where(t_yd_l eq tmp_yd)
	if wlya[0] eq -1 then begin
		lya_sc_av_tmp[gd_cnt]=-999.0
		lya_sr_res_tmp[gd_cnt]=-999.0
		lya_tmp[gd_cnt]=-999.0
	endif else begin
		lya_sc_av_tmp[gd_cnt]=lya_sc_av[wlya]
		lya_sr_res_tmp[gd_cnt]=lya_sr_res[wlya]
		lya_tmp[gd_cnt]=lya[wlya]
	endelse	
	tmp_yd=get_next_yyyydoy(tmp_yd)
	gd_cnt=gd_cnt+1
endwhile

goes_sc_av=goes_sc_av_tmp
goes_sc_av_log=goes_sc_av_log_tmp
goes_sr_res=goes_sr_res_tmp
goes_sr_res_log=goes_sr_res_log_tmp
goes_daily_l=goes_daily_l_tmp
goes_daily_log=goes_daily_log_tmp
mgii_sc_av=mgii_sc_av_tmp
mgii_sr_res=mgii_sr_res_tmp
mgii=mgii_tmp
f107_sc_av=f107_sc_av_tmp
; interpolate bad f107 sc values
gd_f107=where(f107_sc_av gt 0.0)
xall=findgen(n_elements(f107_sc_av))
xgd=xall[gd_f107]
f107_sc_av=interpol(f107_sc_av[gd_f107],xgd,xall)
;print, f107_sc_av
;plot, f107_sc_av
f107_sr_res=f107_sr_res_tmp
f107=f107_tmp
lya_sc_av=lya_sc_av_tmp
lya_sr_res=lya_sr_res_tmp
lya=lya_tmp

end_yd_pred=end_yd
print, 'Saving end_yd_pred.sav'
fname = expand_path('$tmp_dir') + '/end_yd_pred.sav'
save, end_yd_pred, file=fname
print, 'Saving prox_sc_sr_pred.sav'
fname = expand_path('$tmp_dir') + '/prox_sc_sr_pred.sav'
save, day_ar_all, mgii, f107, min_mgii, min_f107, min_goes_l, max_mgii, max_f107, $
	max_goes_l, min_goes_log, max_goes_log,  max_lya, min_lya, $  
	goes_daily_l, goes_sc_av, goes_sr_res, mgii_sc_av, mgii_sr_res, $
	f107_sc_av, f107_sr_res, goes_daily_log, goes_sc_av_log, goes_sr_res_log, $ 
	lya_sc_av, lya_sr_res, lya, end_yd_pred, min_f107_abs, min_lya_abs, $
	min_mgii_abs, $
	file=fname

print, 'End Time create_mgft_sc_av: ', !stime

;stop
end
