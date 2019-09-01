# GeoEfficiency: Accurate Geometrical Efficiency Calculator

An officially registered Julia program that provides a set of tools to calculate the geometrical efficiency in a fast and accurate way. 
The Package models a radiation detector irradiated by a radioactive source. 
The Package relay directly on numerical evaluation of closed form analytical formula describing the geometrical efficiency.

Author | [Mohamed E. Krar](https://www.researchgate.net/profile/Mohamed_Krar3) (DrKrar@gmail.com)
:----|:----: 
Repository | [GitHub.com](https://github.com/DrKrar/GeoEfficiency.jl/)
Documentation |  [GitHub.io](https://GeoEfficiency.GitHub.io/index.html)
Current version | [v"0.9.3"](https://github.com/DrKrar/GeoEfficiency.jl/releases/tag/v0.9.3)
First Created | Fri Aug 14 20:12:01 2015

This documentation is also available in [pfd](https://GeoEfficiency.GitHub.io/pdf/GeoEfficiency.pdf) format.

## Current and Planed Features
The following list show the state of current feature and planed feature.
the checked items represent already present feature.

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
 *  QuadGK 0.3.0 or above, will be installed automatically during the package Installation.
 *  Compat 0.63.0 or above, will be installed automatically during the package Installation.
 
## Download and Installation
the package is registered officially and so it can be installed through the Julia package management  system by typing the following into the REPL prompt.

```julia
julia> import Pkg
julia> Pkg.add("GeoEfficiency") 
```

## Quick Usage
```julia
julia> using GeoEfficiency
julia> calc()
```
**see also: [`geoEff()`](@ref), [`calcN()`](@ref), [`batch()`](@ref)**

## Unit Test
For scientific calculation accuracy in calculation and being error free is a highly demanded objective.
Thus, the package is extensively tested method-wise in each supported operating system.
Operating system fully supported include Windows, Linus, Apple OSx.

After installing the package can be tested in your own system by typing the following into the REPL prompt.
```julia
julia> using Test, Pkg
julia> Pkg.test("GeoEfficiency") 
```  

## Package Overview
The following constructor can be used to construct a specific type of detector 
 *  [`CylDetector`](@ref) for cylindrical detector, 
 *  [`BoreDetector`](@ref) for bore hole, 
 *  [`WellDetector`](@ref) for well type detector.

 While the function [`Detector`](@ref) can be used to construct any of the above types. You may try also [`getDetectors`](@ref).

[`Point`](@ref) constructor is used to construct an anchoring point of a source. relative to source anchoring point the source position is specified.
For a point source, the anchoring point is the source itself. 
The [`source()`](@ref) method take input from the 'console' and return a tuple describing the source.

The efficiency calculation can be done by one of the functions: 
*  [`geoEff`](@ref) used with or without argument(s), 
*  [`calc`](@ref) ask for the required information from the 'console', 
*  [`calcN`](@ref) just a repeat of the [`calc`](@ref) function 
*  [`batch()`](@ref) which try to take required information from csv files located in 
   the home directory inside a folder called `GeoEfficiency`.
 
For more on the function and its methods prefix the name of the function by `?`.

!!! note
    Input from the 'console' can be numerical expression not just a number.
    `5/2` ; `5//2` ; `pi` ; `π/2` ; `exp(2)` ; `1E-2 ` ; `5.2/3` ; `sin(1)` ;  `sin(1)^2` are all valid expressions.
     
## Batch Calculation
The package can be used to perform batch calculations by calling one of the 
methods of the function `batch`. The output results of batch calculations is 
found by default in `GeoEfficiency\results` folder inside the user home directory.

**For example  `c:\users\yourusername\GeoEfficiency\results\`**.

The function [`batch()`](@ref) can be called with or without arrangement(s). 
The without argument version relay on previously prepared Comma Saved  Values 
[CSV] files, that can be easily edit by Microsoft Excel, located by default 
in the `GeoEfficiency` folder.

Those Comma Saved Values [CSV] files are:-
     
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


!!! note
    For Comma Saved Values [CSV] files each line represent an entry, the first line is always treated as the header.
      
!!! warning
    The program expect each line to contain one number for all CSV files except for `Detectors.csv` each line should contain at least one number or at most four separated numbers

