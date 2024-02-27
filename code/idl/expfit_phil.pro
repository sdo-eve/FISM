;
;	expfit.pro
;
;	Fit exp function to data using curvefit.pro and expfunct.pro
;
;	Tom Woods
;	1/28/03
;
;	Returns parameters:   A * exp( B * x) + C
;		param[0] = A
;		param[1] = B
;		param[2] = C
;
function  expfit_phil, x, y, chisq, debug=debug

if n_params() lt 2 then begin
  print, 'USAGE:  param = expfit(x, y)'
  print, '   where  F = A * exp( B*x ) + C'
  return, [ 0, 0, 0.]
endif

;
;	first fit line to get guess at parameters
;
c1 = poly_fit(x, y, 1, yfit )

param = dblarr(3)
param[2] = min(yfit)/2.
param[0] = max(yfit) - param[2]
param[1] = c1[1] / param[0]

weights = 1. / y

if (keyword_set(debug)) then print, 'param guess = ', param

result = curvefit( x, y, weights, param, sigma, function='expfunct_phil', $
	tol=1E-6,  chisq=chisq, iter=iternum,itmax=100)

if (keyword_set(debug)) then begin
  print, ' '
  print, 'Chi^2 = ', chisq, ' in ' + strtrim(iternum,2) + ' iterations'
  print, ' '
  print, 'param fit (A,B,C) = ', param
  print, 'For function:  A * exp( B * x) + C'
  print, ' '
endif
return, param
end
