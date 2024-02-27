;Name: compare_eve_data
; 
;Purpose: to compare the EUV range for FISM data to the eve data for validation 
;
;Call: compare_eve_data, daynum=400 (must be between 0 and 3351)
;
;This will populate 3 windows with the data, all tag data, and a percent difference 
;

pro compare_eve_data, daynum=daynum, with_tags=with_tags

if not keyword_set(daynum) then daynum = 0
enddaynum = 2999
;open and load eve merged data and merged files 
read_netCDF, '/Users/alpa3266/fism2/data_sets/lasp/eve/latest_EVE_L3_merged_1a.ncdf', data, attributes, status
if keyword_set(with_tags) then begin
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01.sav'
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01_tag1.sav'
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01_tag2.sav'
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01_tag3.sav'
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01_tag4.sav'
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01_tag5.sav'
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01_tag6.sav'
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01_tag7.sav'
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01_tag8.sav'
restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01_tag9.sav'
endif else begin
  restore, '/Users/alpa3266/fism2/results/merged/FISM_daily_eve_merged_02_01.sav'
endelse

;while daynum lt enddaynum do begin 
;get the yyyydoy of the day being checked
yyyydoy = data.mergeddata.yyyydoy[daynum]
;print, string(yyyydoy) + '-' + string(daynum)

;find the array index for the fism data 
dy = where(day_ar eq yyyydoy)

;make multiple plots for page (4), gets too small after 4 
if keyword_set(with_tags) then begin
  !p.multi = [0,2,2]
endif else begin
  !p.multi = [0,1,2]
endelse
if keyword_set(with_tags) then begin
  ;open in a window
  window, 0
  ;merged with no tag over the eve data
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, title='EUV Final', xtitle='wv', ytitle='irradience'
  oplot, fism_wv, fism_pred[dy,*], color=5000
  xyouts, 0.7, 0.9, string(yyyydoy), charsize=1.5, /normal
  ;difference
  plot,fism_wv, (data.mergeddata.sp_irradiance[*,daynum]-fism_pred[dy,*])/data.mergeddata.sp_irradiance[*,daynum] -1, title='Difference'
  ;plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, title='
  ;merged over the eve data for each tag file 
  ;this is in order to see which tag is being incorrectly used for large issues
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, XTITLE = 'tag1'
  oplot, fism_wv, fism_pred_tag1[dy,*], color=5000
  
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, XTITLE = 'tag2'
  oplot, fism_wv, fism_pred_tag2[dy,*], color=5000
  
  
  window,1 ; make the next 4
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, XTITLE = 'tag3'
  oplot, fism_wv, fism_pred_tag3[dy,*], color=5000
  
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, XTITLE = 'tag4'
  oplot, fism_wv, fism_pred_tag4[dy,*], color=5000
  
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, XTITLE = 'tag5'
  oplot, fism_wv, fism_pred_tag5[dy,*], color=5000
  
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, XTITLE = 'tag6'
  oplot, fism_wv, fism_pred_tag6[dy,*], color=5000
  
  
  window,2 ;and the next 4
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, XTITLE = 'tag7'
  oplot, fism_wv, fism_pred_tag7[dy,*], color=5000
  
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, XTITLE = 'tag8'
  oplot, fism_wv, fism_pred_tag8[dy,*], color=5000
  
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog, XTITLE = 'tag9'
  oplot, fism_wv, fism_pred_tag9[dy,*], color=5000
endif else begin
  plot,data.spectrummeta.wavelength, data.mergeddata.sp_irradiance[*,daynum], /ylog
  oplot, fism_wv, fism_pred[dy,*], color=5000
  xyouts, 0.7, 0.9, string(yyyydoy), charsize=1.5, /normal
  ;difference
  plot,fism_wv, (data.mergeddata.sp_irradiance[*,daynum]-fism_pred[dy,*])/data.mergeddata.sp_irradiance[*,daynum] -1
endelse
;daynum++
wait, 1
;endwhile 
end