using DiffEqBase

#DAE Example Problems
export prob_dae_resrob

### DAE Problems

f = function (r, yp, y, p, tres)
    r[1]  = -0.04*y[1] + 1.0e4*y[2]*y[3]
    r[2]  = -r[1] - 3.0e7*y[2]*y[2] - yp[2]
    r[1] -=  yp[1]
    r[3]  =  y[1] + y[2] + y[3] - 1.0
end
u0 = [1.0, 0, 0]
du0 = [-0.04, 0.04, 0.0]
"DAE residual form for the Robertson model"
prob_dae_resrob = DAEProblem(f,du0,u0,(0.0,100000.0))
