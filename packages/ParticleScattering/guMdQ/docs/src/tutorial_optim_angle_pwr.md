#  Tutorial 5: Angle Optimization for Power Flow

In the [first angle optimization tutorial](@ref tutorial3), we optimized the rotation angles `φs` such that the field intensity was minimized or maximized around the center of the structure. In some cases, however, we wish to optimize electromagnetic power flow ``P`` through an arc ``\ell``:

```math
P = \frac{1}{2} \Re \int (\mathbf{E} \times \mathbf{H}^*) \cdot \hat{\mathbf{n}} \, \mathrm{d} \ell
```
