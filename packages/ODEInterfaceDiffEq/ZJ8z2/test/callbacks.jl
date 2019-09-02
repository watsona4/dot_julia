using ODEInterfaceDiffEq, Test

callback_f = function (du,u,p,t)
  du[1] = u[2]
  du[2] = -9.81
end

condtion= function (u,t,integrator) # Event when event_f(u,t,k) == 0
  u[1]
end

affect! = nothing
affect_neg! = function (integrator)
  integrator.u[2] = -integrator.u[2]
end

callback = ContinuousCallback(condtion,affect!,affect_neg!)

u0 = [50.0,0.0]
tspan = (0.0,25.0)
prob = ODEProblem(callback_f,u0,tspan)

sol = solve(prob,dopri5(),callback=callback,dtmax=0.5)
@test sol(4.0)[1] > 0
sol = solve(prob,dopri5(),callback=callback,save_everystep=true)
@test sol(4.0)[1] > -1e-12
