Author | [Mohamed E. Krar](https://www.researchgate.net/profile/Mohamed_Krar3) (DrKrar@gmail.com)
:----|:----: 
Repository | [GitHub.com](https://github.com/DrKrar/GeoEfficiency.jl/)
Documentation |  [GitHub.io](https://GeoEfficiency.GitHub.io/index.html)
Current version | [v"0.9.3"](https://github.com/DrKrar/GeoEfficiency.jl/releases/tag/v0.9.3)
First Created | Fri Aug 14 20:12:01 2015


## Latest Release 
[![GeoEfficiency](http://pkg.julialang.org/badges/GeoEfficiency_0.4.svg)](http://pkg.julialang.org/?pkg=GeoEfficiency)  | [![GeoEfficiency](http://pkg.julialang.org/badges/GeoEfficiency_0.5.svg)](http://pkg.julialang.org/?pkg=GeoEfficiency)  | [![GeoEfficiency](http://pkg.julialang.org/badges/GeoEfficiency_0.6.svg)](http://pkg.julialang.org/?pkg=GeoEfficiency) 
----|----|----

## Nightly Builds

Project Status | Linux, OSX | Windows | Code Coverage | codecov.io
----|----|----|----|----
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active) | [![Build Status](https://travis-ci.org/DrKrar/GeoEfficiency.jl.svg)](https://travis-ci.org/DrKrar/GeoEfficiency.jl) | [![Build Status](https://ci.appveyor.com/api/projects/status/ew595nn4njmm4dbl?svg=true)](https://ci.appveyor.com/project/DrKrar/GeoEfficiency-jl) | [![Coverage Status](https://coveralls.io/repos/github/DrKrar/GeoEfficiency.jl/badge.svg?branch=master)](https://coveralls.io/github/DrKrar/GeoEfficiency.jl?branch=master) | [![codecov.io](http://codecov.io/github/DrKrar/GeoEfficiency.jl/coverage.svg?branch=master)](http://codecov.io/github/DrKrar/GeoEfficiency.jl?branch=master)

---

# GeoEfficiency: Accurate Geometrical Efficiency Calculator

An officially registered Julia program, provides a set of tools to calculate the geometrical efficiency in a fast and accurate way. 
The Package models a radiation detector irradiated by a radioactive source. 
The Package relay directly on numerical evaluation of a closed form analytical formula describing the geometrical efficiency.

## Current and Planned Features
The following list describe the state of current feature and planed feature. 
The checked items represent already present feature.

 - [x] support of widely used detector geometries.
      - [x] `cylinder` detectors.
      - [x] `bore-hole` detectors.
      - [x] `well-type` detectors.
     
 - [ ] support of specialized detector geometries.
 
 - [x] support of isotropic radioactive sources.
      - [x] `point` sources.
      - [x] `disc` sources.
      - [x] `cylinder` sources.

 - [ ] support of anisotropic radioactive sources.
      - [ ] `point` sources.
     
 - [ ] consider more details of the measurement setup.
      - [ ] the detector effect.
      - [ ] the end cap effect.
      - [ ] the medium and absorber effect.
      
 - [ ] combine the effect of the source geometry and composition. 

## Requirements
 *  Julia 0.6 or above.
 *  QuadGK 0.3.0 or above, installed automatically during the package installation.
 *  Compat 0.63.0 or above, installed automatically during the package installation.
 
## Download and Installation
the package is registered officially and so it can be installed through the Julia package management  system by typing the following into the REPL.

```julia
julia> import Pkg
julia> Pkg.add("GeoEfficiency") 
```

## Quick Usage
```julia
julia> using GeoEfficiency
julia> calc()
```
**see also: `geoEff()`, `calcN()`, `batch()`**

## Unit Test
In scientific calculation, calculation accuracy and being error free is a highly demanded objective.
Thus, the package is extensively tested method-wise in each supported operating system.
Operating system fully supported include Windows, Linus, Apple OSx.

After installing the package can be tested in your own system by typing the following into the REPL prompt.
```julia
julia> using Test, Pkg
julia> Pkg.test("GeoEfficiency") 
```

## Package Overview
The following constructor can be used to construct a specific type of detector 
 *  `CylDetector` for cylindrical detector, 
 *  `BoreDetector` for bore hole, 
 *  `WellDetector` for well type detector.

 While the function `Detector` can be used to construct any of the above types. You may try also `getDetectors`.

`Point` constructor is used to construct an anchoring point of a source. relative to source anchoring point the source position is specified.
For a point source, the anchoring point is the source itself. 
The `source()` method take input from the `console` and return a tuple describing the source.

The efficiency calculation can be done by one of the functions: 
*  `geoEff` used with or without argument(s), 
*  `calc` ask for the required information from the `console`, 
*  `calcN` just a repeat of the `calc` function 
*  `batch()` which try to take required information from csv files located in 
   the home directory inside a folder called `GeoEfficiency`.
 
For more on the function and its methods prefix the name of the function by `?`.

## note
**Input from the `console` can be numerical expression not just a number.**
   
   > **``5/2`` ; ``5//2`` ; ``pi`` ; ``π/2`` ; ``exp(2)`` ; ``1E-2 `` ; ``5.2/3`` ; ``sin(1)`` ;  ``sin(1)^2``**
   > **All are valid expressions.**
     
## Batch Calculation
The package can be used to perform batch calculations by calling one of the 
methods of the function `batch`. The output results of batch calculations is 
found by default in `GeoEfficiency\results` folder inside the user home directory.

**For example  `c:\users\yourusername\GeoEfficiency\results\`**.

The function `batch()` can be called with or without arrangement(s). 
The without argument version relay on previously prepared Comma Saved  Values 
[CSV] files, that can be easily edit by Microsoft Excel, located by default 
in the ``GeoEfficiency`` folder.

Those Comma Saved  Values [CSV] files are:-
    
*  `Detectors.csv` contains the detectors description (`a detector per line`); The line format is: 
     
    Crystal_Radius | Crystal_Length | Hole_Radius | Hole_Depth |
    ---------------| ---------------|-------------|----------- |

*  `srcHeights.csv` contains the source heights; 
     
    Source_Heights | 
    ---------------|

*  `srcRhos.csv` contains the source off-axis distances;                        
     
    Source_Rhos | 
    ------------|

*  `srcRadii.csv` contains the source radii for disc and cylindrical sources;             
     
    Source_Radii| 
    ------------|

*  `srcLengths.csv` contains the source length for cylindrical sources;    
     
    Source_Lengths| 
    --------------|

## note
**For Comma Saved Values [CSV] files each line represent an entry, the first line is always treated as the header.**
      
## warning
**The program expect each line to contain one number for all CSV files except for ``Detectors.csv`` each line should contain at least one number or at most four separated numbers.**
