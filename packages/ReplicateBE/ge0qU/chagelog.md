
- v0.1.2

    * change optimization algorithm
    * reml2(::RBE, Array{::Float64,1}) function for -REML2 calculation
    * contrast, lsm, emm, lmean utils
    * DF2
    * Optimizations
    * Changes in struct RBE
    * Additional options
    * Code redesign


- v0.1.1
    * change keyword var -> dvar
    * Step 0 variance calculation
    * Split REML β dependent and REML2 β independent
    * Hessian matrix now come from ForwardDiff
    *  g_tol, x_tol, f_tol keywords for Optim
    * Optimization
    * Confidence intervals: confint(::RBE, ::Float64)
    * Show result
    * Bugfix



- v0.1.0
  * Initial alpha version
