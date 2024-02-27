;+
; :Author: Phil Chamberlin
; 
; FILE: sem_txt_to_save
; 
; Purpose: convert sem data from txt to sav file
;-


pro sem_txt_to_sav
print, 'Running sem_txt_to_sav ... ', !stime

st_yr=1996
end_yr=2019
sem_yd=fltarr(1)
sem_irr=dblarr(1) ; 26-34 nm
sem_irr_0_50=dblarr(1) ; 0-50nm


sem_data_path=expand_path('$fism_data') + '/soho_sem/'
for i=st_yr,end_yr do begin
   sem_flnm=strmid(strtrim(i,2),2,2)+'_v3.day.txt'
   a=read_ascii(sem_data_path+sem_flnm, comment_symbol=';')
   fact=dblarr(n_elements(a.field01[1,*]))+1000
   sem_yd_tmp=a.field01[1,*]*fact+a.field01[2,*]
   sem_yd=[sem_yd,transpose(sem_yd_tmp)]
   sem_irr=[sem_irr,transpose(a.field01[14,*])]
   sem_irr_0_50=[sem_irr_0_50,transpose(a.field01[15,*])]
endfor

ndys=n_elements(sem_yd)
sem_yd=sem_yd[1:ndys-1]
sem_irr=ph2watt(fltarr(ndys-1)+30.0, sem_irr[1:ndys-1]/8.) ; Need *8 becuase function needs /nm
sem_irr_0_50=ph2watt(fltarr(ndys-1)+25.0, sem_irr_0_50[1:ndys-1]/50.); Need *50 becuase function needs /nm

save, sem_yd, sem_irr, sem_irr_0_50, file='$fism_data/soho_sem/sem_data.sav'

print, 'End time sem_txt_to_sav: ', !stime

end
