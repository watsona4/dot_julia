"""
Generates the integrand for use in the Sauter-Schwab quadrature formulas.

        generate_integrand(kernel, test_local_space, trial_local_space,
                test_chart, trial_chart)

`kernel` is a function that takes two neighborhoods `x` and `y` and returns a
scalar or dyadic value. `kernel` is the part of the integrand that is most
easily described in term of cartesian coordinates, that is non-separable in the
two arguments, and that does not depend on which of the local shape functions
is considered. In boundary element methods it is the Green function (fundamental
solution) of the underlying partial differential equations.
"""
function generate_integrand_uv(kernel, testref, trialref, testel, trialel)

    function k3(u,v)
        out = @SMatrix zeros(3,3)

        x = neighborhood(testel,u)
        y = neighborhood(trialel,v)

        kernelval = kernel(x,y)
        f = testref(x)
        g = trialref(y)

        jx = jacobian(x)
        jy = jacobian(y)
        ds = jx*jy

        return  SMatrix{3,3}([dot(f[i][1], kernelval*g[j][1])*ds for i=1:3, j=1:3])
    end

    return k3
end
