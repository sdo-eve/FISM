pro lya_dat_to_save

print, 'Running lya_dat_to_save ',!stime

a=read_ascii(expand_path('$fism_data') + '/lasp/lyman_alpha/composite_lya.dat')
num_el=n_elements(a.field1[0,*])

t_yd_l_tmp=lonarr(num_el)
lya_index_tmp=fltarr(num_el) 
lya_inst_tmp=intarr(num_el)

x=0d
y=0.0
chk=''
trp=0
ylast=y

openr, lun, expand_path('$fism_data') + '/lasp/lyman_alpha/composite_lya.dat', /get_lun

for i=0l, num_el-1 do begin
	readf, lun, chk
	if strmid(strcompress(chk),0,4) eq '1947' or trp eq 1 then begin
		trp=1
		t=strsplit(strcompress(chk),' ',/extract)
		t_yd_l_tmp[i]=t[0]
		lya_index_tmp[i]=t[1]
		lya_inst_tmp[i]=t[2]	
	endif
endfor

; Eliminate zeros
gd=where(lya_index_tmp gt 0 and (lya_inst_tmp ne 4 and lya_inst_tmp ne 5))
t_yd_l=t_yd_l_tmp[gd]
lya_index=lya_index_tmp[gd]
lya_inst=lya_inst_tmp[gd]

; Convert to Watts from Photons
lyawv=replicate(121.6,n_elements(t_yd_l))
lya_data=ph2watt(lyawv,lya_index*1.e11)

save, t_yd_l, lya_data, lya_inst, file=expand_path('$fism_data') + '/lasp/lyman_alpha/lya_index.sav'

print, 'End Time lya_dat_to_save: ', !stime

end
