;
;  NAME: mult_min.pro
;
;  PURPOSE: to create the ratio of the SEE data to the newly created minimum
;	spectrum for FISM 
;
;  MODIFICATION HISTORY:
;	PCC	5/25/04		Program Creation
;	PCC	7/25/04		Updated for f107 also
;	PCC	12/01/06	Updated for MacOSX
;
;       VERSION 2_01
;       PCC     6/20/12         Updated for SDO/EVE
;                               Changed name from 'get_see_mult_min.pro' to 'mult_min.pro'
;
;+

function mult_min_fuv, e_div_emin, tag

restore, expand_path('$fism_save') + '/fuv_min_sp_tag'+strtrim(tag,2)+'.sav'

pred_sp=fuv_min_sp*e_div_emin

return, pred_sp

end
