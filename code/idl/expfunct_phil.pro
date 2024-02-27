;
;	expfunct.pro
;
;	exp function for use with curvefit.pro
;
;	Tom Woods
;	1/28/03
;
;  F(x) = A * exp( B * x ) + C
;
pro expfunct_phil, x, a, f, pder

bxi = ((a[1]*x) > (-80.)) < 80.
bx = exp(bxi)

f = a[0] * bx + a[2]

if n_params() ge 4 then $
    pder = [ [bx], [a[0]*x*bx], [replicate(1.0, n_elements(f))] ]

return
end

