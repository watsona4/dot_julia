# QNaNs.jl
Simplifies the use of quiet NaNs to propagate information from within numerical computations.&nbsp;&nbsp; [![Build Status](https://travis-ci.org/JeffreySarnoff/QNaNs.jl.svg?branch=master)](https://travis-ci.org/JeffreySarnoff/QNaNs.jl)
```ruby
                                                       Jeffrey Sarnoff © 2016-Mar-26 at New York
```

#### Quick Look

```julia
> Pkg.add("QNaNs")
```
```julia
> using QNaNs
> a_qnan = qnan(36)
NaN
> payload = qnan(a_qnan)
36

> typeof(a_qnan)
Float64
> isnan(a_qnan), isnan(NaN)   # quiet NaNs areNaNs
true, true

# works with Float64, Float32 and Float16

> a_qnan32 = qnan(Int32(-77))
NaN32
> payload = qnan(a_qnan32); payload, typeof(payload)
-77, Int32

> qnan16 = qnan(Int16(-77)); payload16 = qnan(qnan16);
> qnan16, typeof(qnan16), payload16, typeof(payload16)
NaN16, Float16, -77, Int16

```


#####William Kahan on QNaNs

NaNs propagate through most computations. Consequently they do get used. ... they are needed only for computation, with temporal sequencing that can be hard to revise, harder to reverse. NaNs must conform to mathematically consistent rules that were deduced, not invented arbitrarily ...

NaNs [ give software the opportunity, especially when searching ] to follow an unexceptional path ( no need for exotic control structures ) to a point where an exceptional event can be appraised ... when additional evidence may have accrued ...  NaNs [have] a field of bits into which software can record, say, how and/or where the NaN came into existence. That [can be] extremely helpful [in] “Retrospective Diagnosis.”

-- IEEE754 Lecture Notes (highly redacted)


##### Quiet NaNs were designed to propagate information from within numerical computations

The payload for a Float64 qnan is an integer [-(2^51-1),(2^51-1)]  
The payload for a Float32 qnan is an integer [-(2^22-1),(2^22-1)]  
The payload for a Float16 qnan is an integer [-(2^9-1),(2^9-1)]  

Julia uses a payload of zero for NaN, NaN32, NaN16.

#### About QNaN Propogation

A QNaN introduced into a numerical processing sequence usually will propogate along the computational path without loss of identity unless another QNaN is substituted or an second QNaN occurs in an arithmetic expression.

When two qnans are arguments to the same binary op, Julia propagates the qnan on the left hand side. 
```julia
> using QNaNs
> function test()
    lhs = qnan(-64)
    rhs = qnan(100)
    (qnan(lhs-rhs)==qnan(lhs), qnan(rhs/lhs)==qnan(rhs))
  end;
> test()
(true, true)
```


References:

[William Kahan's IEEE754 Lecture Notes](http://www.eecs.berkeley.edu/~wkahan/ieee754status/IEEE754.PDF)
