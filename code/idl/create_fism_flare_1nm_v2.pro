pro create_fism_flare_1nm_v2, ydoy=ydoy

if not keyword_set(ydoy) then ydoy=2017249  
styd=strtrim(ydoy,2)

restore, '$fism_results/flare_hr_data/FISM_60sec_'+styd+'_v02_01.sav'

ntimes=n_elements(fism_pred[0,*])
fism_pred_1nm=fltarr(190,ntimes)
fism_wv_1nm=findgen(190)+0.5

for i=0,189 do begin
   gd_wv=where(fism_wv ge i and fism_wv lt i+1)
   for j=0,ntimes-1 do begin
      fism_pred_1nm[i,j]=mean(fism_pred[gd_wv,j])
   endfor
endfor

save, fism_pred_1nm, fism_wv_1nm, ydoy, utc, file='$fism_results/flare_1nm_data/FISM_60sec_'+styd+'_1nm_v02_01.sav'


end
