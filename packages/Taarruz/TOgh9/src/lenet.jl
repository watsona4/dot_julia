# Define convolutional layer:
mutable struct Conv; w; b; f; end
(c::Conv)(x) = c.f.(pool(conv4(c.w, x) .+ c.b))
Conv(w1,w2,cx,cy,f=relu; atype=_atype) = Conv(
    param(w1,w2,cx,cy; atype=atype), param0(1,1,cy,1; atype=atype), f)


# Define dense layer:
mutable struct Dense; w; b; f; end
(d::Dense)(x) = d.f.(d.w * mat(x) .+ d.b)
Dense(i::Int,o::Int,f=relu; atype=_atype) = Dense(
    param(o,i; atype=atype), param0(o; atype=atype), f)


# Define a chain of layers and a loss function:
mutable struct Chain; layers; end
(c::Chain)(x) = (for l in c.layers; x = l(x); end; x)
(c::Chain)(x,y) = nll(c(x),y)


"""
    Lenet(; atype)

Returns a randomly initialized Lenet model. Used for demo and testing.
Take a look at for more detailed information. atype is KnetArray{Float32}
if GPU is detected, otherwise Array{Float64}.
"""
Lenet(; atype=_atype) = Chain(
    (Conv(5,5,1,20; atype=atype),
     Conv(5,5,20,50; atype=atype),
     Dense(800,500; atype=atype),
     Dense(500,10,identity; atype=atype)))
