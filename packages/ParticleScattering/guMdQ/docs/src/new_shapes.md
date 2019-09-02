# Adding New Shapes

ParticleScattering includes functions for drawing squircles, rounded stars, and ellipses.
New shape functions can  be added, provided they have the following structure:
```julia
function my_shape(args, N)
    t = Float64[π*j/N for j = 0:(2*N-1)] # or t = 0:π/N:π*(2-1/N)
    ft =  [x    y]
    dft = [dx/dt    dy/dt]
    ShapeParams(t, ft, dft)
end
```

Where `t` is the parametrization variable, `ft[i,:] = [x(t[i]) y(t[i])]` contains the coordinates, and dft contains the derivative of `ft` with respect to `t`.
In particular, the quadrature used by ParticleScattering assumes `t`
are equidistantly distributed in ``[0, 2\pi)``, and that none of the points `ft`
lie on the origin.
