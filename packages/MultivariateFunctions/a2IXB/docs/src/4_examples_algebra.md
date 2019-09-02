# Examples - Algebra

## Univariate: Basic algebra

Consider we have a two functions f and g and want to add them, multiply them by some other function h, then square it and finally integrate the result between 2.0 and 2.8. This can be done analytically with MultivariateFunctions:
```
f = PE_Function(1.0, 2.0, 4.0, 5)
g = PE_Function(1.3, 2.0, 4.3, 2)
h = PE_Function(5.0, 2.2, 1.0,0)
result_of_operations = (h*(f+g))^2
integral(result_of_operations, 2.0, 2.8)
```


## Multivariate: Basic algebra

Consider we have a three functions $$f(x) = x^2 - 8$$ and $$g(y) = e^{y}$$ and want to add them, multiply them by some other function $$h(x,y) = 4 x e^{y}$$, then square it and finally integrate the result between 2.0 and 2.8 in the x domain and 2 and 3 in the y domain. This can be done analytically with MultivariateFunctions.

The additional complication from the univariate case here is that we need to define the names of the dimensions as we have more than one dimension.
```
f = PE_Function(1.0, Dict(:x => PE_Unit(0.0,0.0,2))) - 8
g = PE_Function(1.0, Dict(:y => PE_Unit(1.0,0.0,0)))
h = PE_Function(4.0, Dict([:x, :y] .=> [PE_Unit(0.0,0.0,1), PE_Unit(1.0,0.0,0)]))
result_of_operations = (h*(f+g))^2
integration_limits = Dict([:x, :y] .=> [(2.0,2.8), (2.0,3.0)])
integral(result_of_operations, integration_limits)
```
