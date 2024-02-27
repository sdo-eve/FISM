; Enter Keywords as strings
; Make sure to be in SSWIDL

pro debug_eve_flare, yd=yd, hr=hr

if not keyword_set(yd) then yd='2011221'
if not keyword_set(hr) then hr='08'

; Restore the FISM data
restore, expand_path('$fism_results')+'/flare_data/'+strmid(yd,0,4)+'/FISM_60sec_'+yd+'_02_01.sav'

; Restore the EVE data
a=file_search('~/EVE/data/level2/'+strmid(yd,0,4)+'/'+strmid(yd,4,3)+'/EVS_L2_*_'+hr+'_*')
eve=read_generic_fits(a[0])

; Put EVE into 1A bins
nsod=n_elements(eve.spectrum.sod)
nwvs=n_elements(fism_wv)
eve_flr_data_1a=fltarr(nwvs,nsod)
eve_flr_prec_1a=fltarr(nwvs,nsod)
for h=0,nwvs-1 do begin
           wgd_1a=where(eve.spectrummeta.wavelength ge fism_wv[h]-0.05 and eve.spectrummeta.wavelength lt fism_wv[h]+0.05)
           n1a=n_elements(wgd_1a) ; divide by this to keep as W/m^2/nm but a 1A bins
           eve_flr_data_1a[h,*]=total(eve.spectrum.irradiance[wgd_1a],1)/n1a
           eve_flr_prec_1a[h,*]=total(eve.spectrum.precision[wgd_1a],1)/n1a/n1a ; should this be mean()/n instead of sum()/n? two div is mean
endfor

nwvs=n_elements(fism_wv)
ans=''
cc=independent_color()
for i=0,nwvs-1 do begin
   gd=where(eve_flr_data_1a[i,*] gt 0.0)
   if gd[0] eq -1 then goto, bdwv
   tlt='Wavelength: '+strmid(strtrim(fism_wv[i],2),0,5)+' nm'
   ymx1=max(eve_flr_data_1a[i,gd])
   ymx2=max(fism_pred[*,i])
   ymx=max([ymx1,ymx2])
   plot, eve.spectrum[gd].sod, eve_flr_data_1a[i,gd]*1000., psym=10, title=tlt, $
         charsize=1.5, yr=[0,ymx*1000.], thick=2, ytitle='mW/m!E2!N/nm', $
         xtitle='Seconds of Day'
   oplot, utc, fism_pred[*,i]*1000., psym=10, color=cc.red, thick=2
   oplot, utc, (fism_pred[*,i]-imp_flare[*,i])*1000., psym=10, color=cc.blue
   oplot, utc, (fism_pred[*,i]-grad_flare[*,i])*1000., psym=10, color=cc.green
   oplot, utc, (fism_pred[*,i]-grad_flare[*,i]-imp_flare[*,i])*1000., psym=10, color=cc.light_blue
   read, ans, prompt='Next wv (return, or 2 to stop): '
   if ans eq 2 then stop
   bdwv:
endfor


stop

end
