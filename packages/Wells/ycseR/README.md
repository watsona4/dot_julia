Wells.jl (multi-well variable-rate pumping-test analysis tool)
=======================================

* Wells.jl is a Julia code for multi-well variable-rate pumping test analysis based on analytical methods.
* Wells.jl computes drawdown in confined, unconfined and leaky aquifers through a variety of analytical solutions.
* Wells.jl considers fully or partially penetrating pumping and observation wells. It also includes wellbore storage capacity of pumping wells.
* Wells.jl can simulate variable-rate pumping tests where the variable rate is approximated either as piecewise linear or as step changes. It can also handle standard exponential and sinusoidal changes in pumping rates.
* Wells.jl utilizes the principle of superposition to account for transients in the pumping regime and to include multiple sources/sinks (e.g. pumping wells).
* Wells.jl combines the use of the principle of superposition and method of images to represent constant head or no flow boundaries.

Wells.jl is a Mads module.

[MADS](http://madsjulia.github.io/Mads.jl) is an integrated open-source high-performance computational (HPC) framework in [Julia](http://julialang.org).
MADS can execute a wide range of data- and model-based analyses:

* Sensitivity Analysis
* Parameter Estimation
* Model Inversion and Calibration
* Uncertainty Quantification
* Model Selection and Model Averaging
* Model Reduction and Surrogate Modeling
* Machine Learning and Blind Source Separation
* Decision Analysis and Support
