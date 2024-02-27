;
; NAME: make_backkup_best_proxy.pro
;
; PURPOSE: to make a 2nd, 3rd, and 4th dimension for subsequent levels of 
;	backup proxy to use if the optimal proxy is unavailable
;

pro make_backup_best_proxy_xuv, plots=plots, ps_out=ps_out
print, 'Running make_backup_best_proxy ', !stime


restore, expand_path('$fism_save')+'/best_fit_coefs_xuv.sav'
;nwv=n_elements(eve_wv)
n_proxies=12
best_proxy_tmp=intarr(6,nwv) ; 6 is max steps to get to F10.7
best_proxy_tmp[0,*]=best_tag

; Backkup tree
;'(1) mgii' -> f107
;'(2) f107' -> Should alwasy be available (I interpolate if not actually measured)
;'(3) goes' -> QD -> f107
;'(4) lya' -> mgii -> f107
;'(5) QD' -> mgii -> f107
;'(6) 171' -> 304 -> lya -> mgii
;'(7) 304' -> lya -> mgii -> f107
;'(8) 335' -> QD -> mgii -> f107
;'(9) 369' -> QD -> mgii -> f107
;'(10) 171d' -> '171' -> '304' -> 'lya' -> 'mgii' -> f107
;'(11) 304d' -> '304' -> 'lya' -> 'mgii' -> f107
;'(12) lyad' -> 'lya' -> mgii -> f107

; 1st backup
for j=0,4 do begin ; 6 levels to all get down to F10.7
	for i=1,n_proxies do begin 
		a=where(best_proxy_tmp[j,*] eq i)
		if a[0] ne -1 then begin
			case i of
				1:best_proxy_tmp[j+1,a]=2
				2:best_proxy_tmp[j+1,a]=2
				3:best_proxy_tmp[j+1,a]=5
				4:best_proxy_tmp[j+1,a]=1
				5:best_proxy_tmp[j+1,a]=1
				6:best_proxy_tmp[j+1,a]=7
				7:best_proxy_tmp[j+1,a]=4
				8:best_proxy_tmp[j+1,a]=5
				9:best_proxy_tmp[j+1,a]=5
				10:best_proxy_tmp[j+1,a]=6
				11:best_proxy_tmp[j+1,a]=7
				12:best_proxy_tmp[j+1,a]=4
			endcase
		endif
	endfor
endfor

; Force FISM to use only F10.7 as a proxy in the XUV until errors with
; other proxies can be resolved
; Mar 19, 2020 update, now forcing to not use F10.7 as primary proxy
; as it bottoms out severly at solar minimum times
best_tag=best_proxy_tmp
;best_tag[*,*]=2 ;best_proxy_tmp

save, best_tag, file=expand_path('$fism_save')+'/best_proxy_xuv.sav'

if keyword_set(plots) or keyword_set(ps_out) then begin
	if keyword_set(ps_out) then open_ps, '$fism_plots/backup_proxy_xuv.ps',/landscape,/color
	cc=independent_color()
	plot, best_proxy_tmp[0,*], psym=10
	oplot, best_proxy_tmp[1,*], color=cc.red, psym=10
	oplot, best_proxy_tmp[2,*], color=cc.green, psym=10
	oplot, best_proxy_tmp[3,*], color=cc.blue, psym=10
	oplot, best_proxy_tmp[4,*], color=cc.rust, psym=10
	oplot, best_proxy_tmp[5,*], color=cc.purple, psym=10, thick=2
	if keyword_set(ps_out) then close_ps
endif	

print, 'End Time make_backup_best_proxy_xuv: ', !stime

end
				
				 
