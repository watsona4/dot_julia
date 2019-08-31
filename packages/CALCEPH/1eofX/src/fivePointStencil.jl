
"""
    fivePointStencil(f,x,n::Integer,h)

Evaluates function f and its derivatives up to order n ∈ [0,4] at x:
``f(x),f'(x),...,f^{(n)}(x)``
The result is an array of length n+1.
Derivatives are numerically computed using the 5-point stencil method
with h≠0 being the grid spacing:
[https://en.wikipedia.org/wiki/Five-point_stencil](https://en.wikipedia.org/wiki/Five-point_stencil)

"""
function fivePointStencil(f,x,n::Integer,h)
    if ((n<0) || (n>4))
        error("In fivePointStencil: Invalid order $n")
    end
    if (h==0.0)
        error("In fivePointStencil: Invalid grid spacing $h")
    end
    fm2 = f(x-2h)
    fm1 = f(x-h)
    fn0 = f(x)
    fp1 = f(x+h)
    fp2 = f(x+2h)

    res = Vector{typeof(fn0)}(undef,n+1)

    res[1] = fn0

    (n==0) && return res

    res[2] = (-fp2+8fp1-8fm1+fm2)/(12*h)

    (n==1) && return res

    h2 = h * h
    res[3] = (-fp2+16fp1-30fn0+16fm1-fm2)/(12*h2)

    (n==2) && return res

    h3 = h2 * h
    res[4] = (fp2-2fp1+2fm1-fm2)/(2*h3)

    (n==3) && return res

    h4 = h3 * h
    res[5] = (fp2-4fp1+6fn0-4fm1+fm2)/h4

    return res
end
