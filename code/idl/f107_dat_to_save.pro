pro f107_dat_to_save

print, 'Running f107_dat_to_save ',!stime

 a=read_ascii(expand_path('$f107_proxy') + '/f10_7_merged.txt') 
num_el=n_elements(a.field1[0,*])

ft_time_tmp=lonarr(num_el)
ft_tmp=fltarr(num_el) 

x=0d
y=0.0
chk=''
trp=0
ylast=y
openr, lun, expand_path('$f107_proxy') + '/f10_7_merged.txt', /get_lun

for i=0l, num_el-1 do begin
	readf, lun, chk
;	if strmid(strcompress(chk),0,4) eq '1947' or trp eq 1 then begin
;		trp=1
		t=strsplit(strcompress(chk),' ',/extract)
		if t[3] le 0 then begin
			fttime = ymd2yd(t[0], t[1], t[2])
			ft_time_tmp[i]=fttime
			ft_tmp[i]=ylast
		endif else begin
			fttime = ymd2yd(t[0], t[1], t[2])
			ft_time_tmp[i]=fttime	
			ft_tmp[i]=float(t[3])
			if ft_tmp[i] lt 50 then ft_tmp[i]=ylast
		endelse
		ylast=ft_tmp[i]
;	endif
endfor

; Eliminate zeros
gd=where(ft_tmp gt 0.01)
ft_time=ft_time_tmp[gd]
ft=ft_tmp[gd]

fname = expand_path('$tmp_dir') + '/f107_data.sav'
save, ft_time, ft, file=fname

end
