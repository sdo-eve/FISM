pro debug_eve_daily, alltags=alltags, sp_only=sp_only

; Restore EVE Daily merged dataset
restore, '$fism_data/EVE/EVE_L3_merged_1a_2012168_003.sav'

; Restore FISM Daily merged dataset
restore, '$fism_results/merged/FISM_daily_merged_02_01.sav'
if keyword_set(alltags) then begin
   restore, '$fism_results/merged/FISM_daily_merged_02_01_tag1.sav'
   restore, '$fism_results/merged/FISM_daily_merged_02_01_tag2.sav'
   restore, '$fism_results/merged/FISM_daily_merged_02_01_tag3.sav'
   restore, '$fism_results/merged/FISM_daily_merged_02_01_tag4.sav'
   restore, '$fism_results/merged/FISM_daily_merged_02_01_tag5.sav'
   restore, '$fism_results/merged/FISM_daily_merged_02_01_tag6.sav'
   restore, '$fism_results/merged/FISM_daily_merged_02_01_tag7.sav'
   restore, '$fism_results/merged/FISM_daily_merged_02_01_tag8.sav'
   restore, '$fism_results/merged/FISM_daily_merged_02_01_tag9.sav'
endif

nwvs=n_elements(eve.spectrummeta.wavelength)
eve_yd=eve.mergeddata.yyyydoy

; Find where FISM data arrays align with EVE data
neve_dys=n_elements(eve.mergeddata.yyyydoy)
for j=0,neve_dys-1 do begin
   if j eq 0 then begin
      wfism=where(day_ar eq eve.mergeddata[j].yyyydoy)
      eve_yfrac=yd_to_yfrac(eve.mergeddata[j].yyyydoy)
   endif else begin
      wfism_tmp=where(day_ar eq eve.mergeddata[j].yyyydoy)
      wfism=[wfism,wfism_tmp]
      eve_yfrac=[eve_yfrac,yd_to_yfrac(eve.mergeddata[j].yyyydoy)]
   endelse
endfor

cc=independent_color()

if keyword_set(sp_only) then goto, spplts
ans=''
for i=0,nwvs-1 do begin
   tlt='Wavelength: '+strmid(strtrim(eve.spectrummeta.wavelength[i],2),0,6)+' nm'
   plot, eve_yfrac, eve.mergeddata.sp_irradiance[i]>0.0, title=tlt, thick=2, $
         charsize=1.5, xtitle='Year', ytitle='W/m!E2!N/nm'
   oplot, eve_yfrac, fism_pred[wfism,i], color=cc.red, thick=2
   if keyword_set(alltags) then begin
      oplot, eve_yfrac, fism_pred_tag1[wfism,i], color=cc.green, linestyle=2
      oplot, eve_yfrac, fism_pred_tag2[wfism,i], color=cc.orange
      oplot, eve_yfrac, fism_pred_tag3[wfism,i], color=cc.yellow
      oplot, eve_yfrac, fism_pred_tag4[wfism,i], color=cc.green
      oplot, eve_yfrac, fism_pred_tag5[wfism,i], color=cc.blue
      oplot, eve_yfrac, fism_pred_tag6[wfism,i], color=cc.light_blue
      oplot, eve_yfrac, fism_pred_tag7[wfism,i], color=cc.purple
      oplot, eve_yfrac, fism_pred_tag8[wfism,i], color=cc.rust
      oplot, eve_yfrac, fism_pred_tag9[wfism,i], color=cc.aqua
      xyouts, 0.1, 0.1, 'Green Dashed: MgII', color=cc.green, /normal
      xyouts, 0.1, 0.1, 'Orange: F10.7', color=cc.orange, /normal
      xyouts, 0.1, 0.1, 'Yellow: GOES', color=cc.yellow, /normal
      xyouts, 0.1, 0.1, 'Green: Ly Alpha', color=cc.green, /normal
      xyouts, 0.1, 0.1, 'Blue: ESP QD', color=cc.blue, /normal
      xyouts, 0.1, 0.1, 'Light Blue: 17.1 nm', color=cc.light_blue, /normal
      xyouts, 0.1, 0.1, 'Purple: 30.4 nm', color=cc.purple, /normal
      xyouts, 0.1, 0.1, 'Rust: 33.5 nm', color=cc.rust, /normal
      xyouts, 0.1, 0.1, 'Aqua: 36.9 nm', color=cc.aqua, /normal
   endif   
   read, ans, prompt='Next wv? '
endfor

spplts:

eve_dy_min=where(eve.mergeddata.yyyydoy eq 2010200)
eve_dy_max=where(eve.mergeddata.yyyydoy eq 2012010)
fism_dy_min=where(day_ar eq 2010200)
fism_dy_max=where(eve.mergeddata.yyyydoy eq 2012010)
x_wv=eve.spectrummeta.wavelength
plot, x_wv, eve.mergeddata[eve_dy_min].sp_irradiance, /ylog, $
      charsize=1.5, yr=[1e-7,1e-2], psym=10, xtitle='Wavelength (nm)', $
      ytitle='W/m!E2!N/nm'
oplot, x_wv, fism_pred[fism_dy_min,*], psym=10, color=cc.red

ans=''
read, ans, prompt='Next wv? '

plot, x_wv, eve.mergeddata[eve_dy_max].sp_irradiance, /ylog, $
      charsize=1.5, yr=[1e-7,1e-2], psym=10, xtitle='Wavelength (nm)', $
      ytitle='W/m!E2!N/nm'
oplot, x_wv, fism_pred[fism_dy_max,*], psym=10, color=cc.red


stop

end
