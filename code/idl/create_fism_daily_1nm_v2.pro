pro create_fism_daily_1nm_v2, ydoy=ydoy

if not keyword_set(ydoy) then ydoy=2017249  
styd=strtrim(ydoy,2)

restore, '$fism_results/daily_hr_data/FISM_daily_'+styd+'_v02_01.sav'

fism_pred_1nm=fltarr(190)
fism_wv_1nm=findgen(190)+0.5

for i=0,189 do begin
   gd_wv=where(fism_wv ge i and fism_wv lt i+1)
   fism_pred_1nm[i]=mean(fism_pred[gd_wv])
endfor

save, fism_pred_1nm, fism_wv_1nm, ydoy, file='$fism_results/daily_1nm_data/FISM_daily_'+styd+'_1nm_v02_01.sav'


end
