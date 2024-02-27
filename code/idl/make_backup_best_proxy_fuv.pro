;
; NAME: make_backkup_best_proxy.pro
;
; PURPOSE: to make a 2nd, 3rd, and 4th dimension for subsequent levels of 
;	backup proxy to use if the optimal proxy is unavailable
;

pro make_backup_best_proxy_fuv, plots=plots, ps_out=ps_out

print, 'Running make_backup_best_proxy_fuv ', !stime


restore, expand_path('$fism_save')+'/best_fit_coefs_fuv.sav'
;nwv=n_elements(eve_wv)
n_proxies=3
best_proxy_tmp=intarr(3,nwv) ; 2 is max steps to get to F10.7
best_proxy_tmp[0,*]=best_tag

; Backkup tree
;'(0) lya' -> mgii -> f107
;'(1) mgii' -> f107
;'(2) f107' -> Should alwasy be available (I interpolate if not actually measured)

; 1st backup
for j=0,1 do begin ; 2 levels to all get down to F10.7
	for i=0,n_proxies-1 do begin 
		a=where(best_proxy_tmp[j,*] eq i)
		if a[0] ne -1 then begin
			case i of
				0:best_proxy_tmp[j+1,a]=1
				1:best_proxy_tmp[j+1,a]=2
				2:best_proxy_tmp[j+1,a]=2
			endcase
		endif
	endfor
endfor

best_tag=best_proxy_tmp

save, best_tag, file=expand_path('$fism_save')+'/best_proxy_fuv.sav'

if keyword_set(plots) or keyword_set(ps_out) then begin
	if keyword_set(ps_out) then open_ps, '$fism_plots/backup_proxy_fuv.ps',/landscape,/color
	cc=independent_color()
	plot, best_proxy_tmp[0,*], psym=10
	oplot, best_proxy_tmp[1,*], color=cc.red, psym=10
	oplot, best_proxy_tmp[2,*], color=cc.green, psym=10
	if keyword_set(ps_out) then close_ps
endif	

print, 'End Time make_backup_best_proxy_fuv: ', !stime

end
				
				 
