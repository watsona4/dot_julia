# OOESAlgorithm.jl
### (Latest version: v0.1.2)

A flexible, open-source package to optimize a Linear Function Over the Set of Efficient Solutions for BOMILP

Follow this link for the [Documentation](http://eng.usf.edu/~amsierra/documents/Documentation_OOESAlg.pdf).

This is a criterion space search for optimizing a linear function over the set of efficient solutions of bi-objective mixed integer linear programs. This project is a julia v1.0.2 project which is written in Linux (Ubuntu).

### The following problem classes are supported:
i. Objectives:    2 linear objectives.
ii. Constraints:  0 or more linear (both inequality and equality) constraints.
iii. Variables:
    a. Binary
    b. Integer variables
    c. Continous variables
    d. Any combination between previous types of variables.

### A multiobjective mixed integer linear instance can be provided as a input in 3 ways:
    a. JuMP Model
    b. LP file format
    c. MPS file format

### Any mixe integer programming solver supported by MathProgBase.jl can be used.
OOES.jl automatically installs GLPK by default. If the user desires to use any other MIP solver, it must be separately installed. 

    a. OOES.jl has been successfully tested with:
        i.      GLPK - v4.61
        ii.     SCIP - v5.0.1 (Supports only SCIP.jl v0.6.1 and olders)
        iii.    Gurobi - v7.5
        iv.     CPLEX - v12.7.
    b. All parameters are already tuned.
    c. Supports parallelization

## Supporting and Citing: ##

The software in this ecosystem was developed as part of academic research by [Alvaro Sierra-Altamiranda](http://eng.usf.edu/~amsierra) and [Hadi Charkhgard](http://eng.usf.edu/~hcharkhgard), members of the Multi--Objective Optimization laboratory at the [University of South florida](http://www.usf.edu). If you would like to help support it, please star the repository as such metrics may help us secure funding in the future. If you use [OOESAlgorithm](https://github.com/alvsierra286/OOESAlgorithm) software as part of your research, teaching, or other activities, we would be grateful if you could cite:

1. [Sierra-Altamiranda, A. and Charkhgard, H., A New Exact Algorithm to Optimize a Linear Function Over the Set of Efficient Solutions for Bi-objective Mixed Integer Linear Programming.](http://www.optimization-online.org/DB_FILE/2017/10/6262.pdf) To appear at [INFORMS Journal On Computing](https://pubsonline.informs.org/journal/ijoc).
2. [Sierra-Altamiranda, A. and Charkhgard, H. (2018). OOES.jl: A julia package for optimizing a linear function over the set of efficient solutions for bi-objective mixed integer linear programming.](http://www.optimization-online.org/DB_FILE/2018/04/6596.pdf).

## Contributions ##

This package is written and maintained by [Alvaro Sierra-Altamiranda](https://github.com/alvsierra286). Please fork and send a pull request or create a [GitHub issue](https://github.com/alvsierra286/OOESAlg/issues) for bug reports or feature requests.
