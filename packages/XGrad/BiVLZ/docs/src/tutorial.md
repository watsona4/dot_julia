
# Tutorial

XGrad.jl is a package for symbolic tensor differentiation that lets you automatically
derive gradients of algebraic expressions or Julia functions with such expressions.
Let's start right from examples.

## Expression differentiation

```
using XGrad

xdiff(:(y = sum(W * x .+ b)); W=rand(3,4), x=rand(4), b=rand(3))
```

In this code:

 * `:(sum(W * x .+ b))` is an expression we want to differentiate
 * `W`, `x` and `b` are example values, we need them to understand type of variables
    in the expression (e.g. matrix vs. vector vs. scalar)


The result of this call should look something like this:

```
quote
    tmp692 = @get_or_create(mem, :tmp692, Array(zeros(Float64, (3,))))
    dy!dW = @get_or_create(mem, :dy!dW, Array(zeros(Float64, (3, 4))))
    dy!dx = @get_or_create(mem, :dy!dx, Array(zeros(Float64, (4,))))
    tmp698 = @get_or_create(mem, :tmp698, Array(zeros(Float64, (1, 4))))
    tmp696 = @get_or_create(mem, :tmp696, Array(zeros(Float64, (3,))))
    dy!db = @get_or_create(mem, :dy!db, Array(zeros(Float64, (3,))))
    dy!dy = (Float64)(0.0)
    y = (Float64)(0.0)
    tmp700 = @get_or_create(mem, :tmp700, Array(zeros(Float64, (4, 3))))
    tmp691 = @get_or_create(mem, :tmp691, Array(zeros(Float64, (3,))))
    dy!dy = 1.0
    tmp691 .= W * x
    tmp692 .= tmp691 .+ b
    tmp695 = size(tmp692)
    tmp696 .= ones(tmp695)
    dy!db = tmp696
    dy!dx .= W' * (tmp696 .* dy!dy)
    dy!dW .= dy!db * x'
    y = sum(tmp692)
    tmp702 = (y, dy!dW, dy!dx, dy!db)
end
```

First 10 lines (those starting with `@get_or_create` macro) are variable initialization.
Don't worry about them right now, I will explain them later in this tutorial.
The rest of the code
calculates gradients of the result variable $y$ w.r.t. input arguments, i.e.
$\frac{dy}{dW}$, $\frac{dy}{dx}$ and $\frac{dy}{db}$. Note that the last expression is a tuple
holding both - `y` and all the gradients. Differentiation requires computing `y` anyway, but
you can use it or dismiss depending on your workflow.

The generated code is somewhat ugly, but much more efficient than a naive one (which we will
demonstrate in the following section). To make it run, you need first to define a `mem::Dict`
variable. Try this:

```
# since we will evaluate expression in global scope, we need to initialize variables first
W = rand(3,4)
x = rand(4)
b = rand(3)

# save derivative expression to a variable
dex = xdiff(:(y = sum(W * x .+ b)); W=W, x=x, b=b)

# define auxiliary variable `mem`
mem = Dict()
eval(dex)
```
which should give us something like:

```
(4.528510092075925, [0.679471 0.727158 0.505823 0.209988; 0.679471 0.727158 0.505823 0.209988; 0.679471 0.727158 0.505823 0.209988], [0.919339, 1.61009, 1.74046, 1.9212], [1.0, 1.0, 1.0])
```

Instead of efficient code you may want to get something more readable. Fortunately, XGrad's
codegens are pluggable and you can easily switch default codegen to e.g. `VectorCodeGen`:


```
ctx = Dict(:codegen => VectorCodeGen())
xdiff(:(y = sum(W * x .+ b)); ctx=ctx, W=rand(3,4), x=rand(4), b=rand(3))
```
this produces:
```
quote
    tmp796 = transpose(W)
    dy!dy = 1.0
    tmp794 = transpose(x)
    tmp787 = W * x
    tmp788 = tmp787 .+ b
    tmp791 = size(tmp788)
    tmp792 = ones(tmp791)
    dy!db = tmp792 .* dy!dy
    dy!dtmp787 = tmp792 .* dy!dy
    dy!dx = tmp796 * dy!dtmp787
    dy!dW = dy!dtmp787 * tmp794
    y = sum(tmp788)
    tmp798 = (y, dy!dW, dy!dx, dy!db)
end
```

See more about different kinds of code generators in the corresponding section on the left [TODO].

## Function differentiation

In most optimization tasks you need not an expression, but a function for calculating
derivatives. XGrad provides a convenient wrapper for it as well:

```
# in file loss.jl
predict(W, b, x) = W * x .+ b

loss(W, b, x, y) = sum((predict(W, b, x) .- y)^2)

# in REPL or another file
include("loss.jl")
W = rand(3,4); b = rand(3); x = rand(4); y=rand(3)
dloss = xdiff(loss; W=W, b=b, x=x, y=y)
dloss(W, b, x, y)
```
And voilà! We get a value of the same structure as in previous section:

```
(3.531294775990527, [1.0199 1.09148 0.75925 0.315196; 1.92224 2.05715 1.43099 0.594062; 1.33645 1.43025 0.994905 0.413026], [1.50102, 2.82903, 1.9669], [2.20104, 3.07484, 3.31411, 4.33103], [-1.50102, -2.82903, -1.9669])
```

!!! note

    XGrad works on Julia source code. When differentiating a function, XGrad first tries to read
    its source code from a file where it was defined
    (using [Sugar.jl](https://github.com/SimonDanisch/Sugar.jl)) and, if failed,
    to recover code from a lowered AST. The latter doesn't always work, so if you are working in REPL,
    it's a good idea to put functions to differentiate to a separate file and then `include(...)` it.
    Also see [Code Discovery](@ref) for some other rules.

Compiling function derivatives beforehand may be tedious, so there's also a convenient shortcut - `xgrad` -
that compiles derivatives dynamically and caches them for later use. We can rewrite previous example as:

```
include("loss.jl")
W = rand(3,4); b = rand(3); x = rand(4); y=rand(3)
xgrad(loss; W=W, b=b, x=x, y=y)
```

This is very convenient when using in a training loop in machine learning, e.g. something like this:

```
W, b = ...
for (x, y) in batchview((X, Y))
    dW, db, dx, dy = xgrad(loss; W=W, b=b, x=x, y=y)   # compiled once, applied at each iteration
    update_params!(W, b, dW, db)
end
```

## Memory buffers

Remember a strange `mem` variable that we've seen in the [Expression differentiation](@ref)
section? It turns out that significant portion of time for computing a derivative (as well as
any numeric code with tensors) is spend on memory allocations. The obvious way to fix it is to use
memory buffers and in-place functions. This is exactly the default behavior of XGrad.jl:
it allocates buffers for all temporary variables in `mem` dictionary and rewrites expressions
using BLAS, broadcasting and in-place assignments. To take advantage of this feature, just
add a buffer of type  `Dict{Any,Any}()` as a last argument to the derivative function:

```
mem = Dict()
dloss(W, b, x, y, mem)
```

If you take a look at the value of `mem` after this call, you will find a number of keys
for each intermediate variable. Here's a full example:

```
include("loss.jl")
W = rand(1000, 10_000); b = rand(1000); x = rand(10_000, 100); y=rand(1000)
dloss = xdiff(loss; W=W, b=b, x=x, y=y)

using BenchmarkTools

# without mem
@btime dloss(W, b, x, y)
# ==> 155.191 ms (84 allocations: 175.52 MiB)

# with mem
mem = Dict()
@btime dloss(W, b, x, y, mem)
# ==> 100.354 ms (26 allocations: 797.86 KiB)
```

`xgrad` supports memory buffers using keyword parameter `mem`:

```
@btime xgrad(loss; W=W, b=b, x=x, y=y, mem=mem)
# ==> 100.640 ms (113 allocations: 802.36 KiB)
```

## Struct derivatives

So far our loss functions were pretty simple taking only a couple of parameters,
but in real life machine learning models have many more of them. Copying a dozen of arguments
all over the code quickly becomes a pain in the neck. To fight this issue, XGrad supports
derivatives of (mutable) structs. Here's an example:

```
# in file linear.jl
mutable struct Linear
    W::Matrix{Float64}
    b::Vector{Float64}
end

# we need a default constructor to instantiate a struct
# fields shouldn't necessary have meaningful values
Linear() = Linear(zeros(1,1), zeros(1))

predict(m::Linear, x) = m.W * x .+ m.b

loss(m::Linear, x, y) = sum((predict(m, x) .- y).^2)


## in REPL or another file
include("linear.jl")
m = Linear(randn(3,4), randn(3))
x = rand(4); y = rand(3)
dloss = xdiff(loss; m=m, x=x, y=y)
y_hat, dm, dx, dy = dloss(m, x, y)
# or using `xgrad`
y_hat, dm, dx, dy = xgrad(loss; m=m, x=x, y=y)
```
Just like with arrays in previous example, `dm` has the same type (`Linear`) and size of its
fields (`dm.W` and `dm.b`) as original model, but holds gradients of paramaters instead of
their values. If you are doing something like SGD on model parameters, you can then update
the model like this:

```
for fld in fieldnames(typeof(m))
    theta = getfield(m, fld)
    theta .-= getfield(dm, fld)
    setfield!(m, fld, theta)
end
```


## How it works

XGrad works similar to reverse-mode automatic differentiation, but operates on symbolic
variables instead of actual values. If you are familiar with AD, you should already know
most details, if not - don't worry, it's pretty simple. The main idea is to decompose
an expression into a chain of some primitive function calls that we already know how to
differentiate, assign the deriviative of the result a "seed" value of 1.0 and then
propagate derivatives back to the input parameters. Here's an example.

Let's say, you have an expression like this (where $x$ is a plain number):

$$z = exp(sin(x))$$

It consists of 2 function calls that we write down, adding an intermediate variable $y$:

$$y = sin(x)$$
$$z = exp(y)$$

We aim to go through all variables $v_i$ and collect derivatives $\frac{\partial z}{\partial v_i}$.
The first variable is $z$ itself. Since derivative of a variable w.r.t. itself is 1.0, we set:

$$\frac{dz}{dz} = 1.0$$

The next step is to find the derivative of $\frac{\partial z}{\partial y}$.
We know that the derivative of `exp(u)` w.r.t. $u$ is also $exp(u)$. If there has been some
accomulated derivative from variables later in the chain, we should also multiply by it:

$$\frac{dz}{dy} = \frac{d(exp(y))}{dy} \cdot \frac{dz}{dz} = exp(y) \cdot \frac{dz}{dz}$$

Finally, from math classes we know that the derivative of $sin(u)$ is $cos(u)$, so we add:

$$\frac{dz}{dx} = \frac{d(sin(x))}{dx} \cdot \frac{dz}{dy} = cos(x) \cdot \frac{dz}{dy}$$

The full derivative expression thus looks like:


$$\frac{dz}{dz} = 1.0$$
$$\frac{dz}{dy} = exp(y) \cdot \frac{dz}{dz}$$
$$\frac{dz}{dx} = cos(x) \cdot \frac{dz}{dy}$$

In case of scalar-valued function of multiple variables (i.e. $R^n \rightarrow R$,
common in ML tasks) instead of "derivative" we say "gradient", but approach stays
more or less the same.


## Defining your own primitives

XGrad knows about most common primitive functions such as `*`, `+`, `exp`, etc., but
there's certenly many more of them. Thus the library provides a `@diffrule` macro that
lets you define your own differentiation rules. For example, provided a function for 2D
convolution `conv2d(x, w)` and derivatives `conv2d_grad_x(...)` and `conv2d_grad_w`,
you can add them like this

```
@diffrule conv2d(x, w) x conv2d_grad_x(x, w, ds)
@diffrule conv2d(x, w) w conv2d_grad_w(x, w, ds)
```

where:

 * `conv2d(x, w)` is a target function expression
 * `x` and `w` are variables to differentiate w.r.t.
 * `conv2d_grad_x(...)` and `conv2d_grad_w(...)` are derivative expression
 * `ds` is a previous gradient in the chain, e.g. if `y = conv2d(x, w)` and `z` is the
    last variable of original expression, `ds` stands for gradient $\frac{dz}{dy}$