;
;  NAME: find_e_sc_e_sr.pro
;
;  PURPOSE: to create the ratio of the SEE data to the newly created minimum
;	spectrum for FISM version 10
;
;	E_sc=(EVE_sc_av/EVE_sc_av_min)-1.
;	E_sr=(EVE_l3_daily-EVE_sc_av)/EVE_sc_av_min
;
;  MODIFICATION HISTORY:
;	PCC	5/25/04		Program Creation
;	PCC	7/5/04		Modified for the SEE data l3 and l3a split
;	PCC	7/22/04		Changes for v9 to find E_sc and E_sr
;	PCC	8/3/04		Added the # of trailing days to average to
;				the saveset (from see_sc_av.sav)
;	PCC	3/28/05		v2. Adds a e_tot that does not split up the 
;				SC and SR components
;				NOTE: for lya, 33.5, and 36.5 proxies, just
;				use the mgii reference spectrum
;				use the exponential fit to avoid negative values
;	PCC	6/13/05		Now divide the SR by SC to get % change proxy
;	PCC	12/01/06	Updated for MacOSX
;       ***** VERSION 2_1
;       PCC     5/21/12         Updated to use SDO/EVE data
;       PCC     1/11/17         Updated for SORCE/XPS data 
;
;+

pro find_e_sc_e_sr_xuv

print, 'Running find_e_sc_e_sr_xuv.pro', !stime

; Restore the SORCE XPS L4 daily data file
data_path=expand_path('$fism_data') 
read_netcdf, data_path+'/lasp/sorce/sorce_xps/sorce_xps_L4_c24h_r0.1nm_latest.ncdf', src_dy ; start with 2003

; Find the minimum spectrum
nwv=n_elements(src_dy[0].modelflux_median)
xuv_min_sp=fltarr(nwv)
for i=0,nwv-1 do begin
    xuv_min_sp[i]=min(smooth(src_dy.modelflux_median[i],108,/edge_truncate))
endfor
save_pth=expand_path('$fism_save') 
print, 'Saving xuv_min_sp.sav'
save, xuv_min_sp, file=save_pth+'/xuv_min_sp.sav'

; Find the E_SC and E_SR using 108 day smooth and residual
ndys=n_elements(src_dy.date)
xuv_sc_av=fltarr(ndys,nwv)
xuv_sr_res=fltarr(ndys,nwv)
sc_avg_dys=108
for j=0,nwv-1 do begin
   xuv_sc_av[*,j]=smooth(src_dy.modelflux_median[j],sc_avg_dys)
   xuv_sr_res[*,j]=src_dy.modelflux_median[j]-xuv_sc_av[*,j]
endfor

tmp_pth=expand_path('$tmp_dir')
save, xuv_sc_av, xuv_sr_res, file=tmp_pth+'/xuv_sc_av.sav'

;	Center
e_sr_xuv=fltarr(ndys,nwv)
e_sc_xuv=fltarr(ndys,nwv)
e_tot_xuv=fltarr(ndys,nwv)
for i=0,nwv-1 do e_sc_xuv[*,i]=(reform(xuv_sc_av[*,i])/xuv_min_sp[i])-1.
; NOTE: see_sr res is already (E-Esc), so no need to subtract 1
for i=0,nwv-1 do e_sr_xuv[*,i]=reform(xuv_sr_res[*,i])/xuv_min_sp[i]
for i=0,nwv-1 do e_tot_xuv[*,i]=(reform(src_dy.modelflux_median[i])/xuv_min_sp[i])-1.

print, 'Saving xuv_e_sc_e_sr.sav'
save, e_sr_xuv, e_sc_xuv, src_dy, sc_avg_dys, $
      e_tot_xuv, file=save_pth+'/xuv_e_sc_e_sr.sav'

print, 'End Time find_e_sc_e_sr_xuv: ', !stime

;stop

end
