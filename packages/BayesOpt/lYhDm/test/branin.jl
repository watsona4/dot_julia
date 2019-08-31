branin(x) = branin(x[1], x[2])
branin(x1, x2; a = 1, b = 5.1/(4π^2), c = 5/π, r = 6, s = 10, t = 1/(8π),
       noiselevel = 0.) =
    a * (x2 - b*x1^2 + c*x1 - r)^2 + s*(1 - t)*cos(x1) + s + noiselevel * randn()

minima(::typeof(branin)) = [([-π, 12.275], 0.397887), ([π, 2.275], 0.397887), ([9.42478, 2.475], 0.397887)]

euclidean(x, y) = sqrt(sum((x .- y).^2))
function regret(optimizer, func)
    mins = [m[1] for m in minima(func)]
    (observed_regret = minimum(map(m -> euclidean(m, optimizer), mins)))
end

config = ConfigParameters()
config.verbose_level = 0

lb = [-5., 0.]; ub = [10., 15.]
optimizer, optimum = bayes_optimization(branin, lb, ub, config)
@test regret(optimizer, branin) < .05
