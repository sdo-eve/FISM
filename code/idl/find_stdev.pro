;
;  NAME: find_stdev.pro
;
;  PURPOSE: to find the absolute and the percent standard deviation
;	for the input observed and predicted arrays
;
;  INPUTS:
;	obs_ar: the array of n observations or measurements
;	pred_ar: the array of n modeled or predicted values
;
;  OUTPUTS:
;	stdev_ar[2]:    [0]: the absolute standard deviation of the 
;		pred_ar from the obs_ar
;			[1]: the percent standard deviation of the 
;		pred_ar from the obs_ar (Already multiplied by 100.)
;
;  PROGRAM CREATION:
;	PCC	6/28/05	Program Creation

function find_stdev, obs_ar, pred_ar

nobs=n_elements(obs_ar)
npre=n_elements(pred_ar)

sub_a=sqrt((total((pred_ar-obs_ar)^2.))/nobs)
sub_p=sqrt((total(((pred_ar-obs_ar)/obs_ar)^2.,/NAN))/nobs)*100.

stdev_ar=[sub_a,sub_p]

;print, sub_a, sub_p

return, stdev_ar

end