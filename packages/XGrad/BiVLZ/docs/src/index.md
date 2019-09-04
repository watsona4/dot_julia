
# XGrad.jl Documentation

```@meta
CurrentModule = XGrad
```

XGrad.jl is a package for symbolic differentiation of expressions and functions in Julia.
A 30 second example of its usage:

```
# in file loss.jl
predict(W, b, x) = W * x .+ b

loss(W, b, x, y) = sum((predict(W, b, x) .- y).^2)
```

```
# in REPL or another file
include("loss.jl")
W = rand(3,4); b = rand(3); x = rand(4); y=rand(3)
dloss = xdiff(loss; W=W, b=b, x=x, y=y)
dloss_val, dloss!dW, dloss!db, dloss!dx, dloss!dy = dloss(W, b, x, y)
```

or, using caching shortcut `xgrad`:

```
# in REPL or another file
include("loss.jl")
W = rand(3,4); b = rand(3); x = rand(4); y=rand(3)
dloss_val, dloss!dW, dloss!db, dloss!dx, dloss!dy = xgrad(loss; W=W, b=b, x=x, y=y)
```

See [Tutorial](@ref) for a more detailed introduction.




