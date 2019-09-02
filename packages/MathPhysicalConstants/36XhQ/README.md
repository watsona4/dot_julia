[![Build Status](https://travis-ci.org/LaGuer/mathphysicalconstants.jl.svg?branch=master)](https://travis-ci.org/LaGuer/mathphysicalconstants.jl)

[![Build status](https://ci.appveyor.com/api/projects/status/h2223a8hus4hxam3/branch/master?svg=true)](https://ci.appveyor.com/project/LaGuer/mathphysicalconstants-jl/branch/master)

# MathPhysicalConstants

MathPhysicalConstants is a Julia package which has the values of a range of mathematical and physical constants updated with most recent available dataset from BIPM in 2018. Currently [MKS](https://en.wikipedia.org/wiki/MKS_system_of_units) and [CGS](https://en.wikipedia.org/wiki/Centimetre%E2%80%93gram%E2%80%93second_system_of_units) units and International System of Units [SI](https://www1.bipm.org/utils/common/pdf/CGPM-2018/26th-CGPM-Resolutions.pdf) are supported.

## Installation

The package can be installed directly from its [github repository](https://github.com/LaGuer/MathPhysicalConstants.jl):

    Pkg.clone("https://github.com/LaGuer/MathPhysicalConstants.jl")

## Usage

Usage is pretty straightforward. Start off by loading the package.

    julia> using MathPhysicalConstants
    
Query and retrieve the Planck Constant using the most updated International System of Units (SI)    
    
    julia> MathPhysicalConstants.SI.PlanckConstantH
    6.62607015e-34
    
    julia> big(MathPhysicalConstants.SI.PlanckConstantH)
    6.62606895999999960651234296395253273824527450725424150396117674176417443843193e-34
    
Now let's have a look at ƛe ≡ ħ/m_e.c the reduced electron radius formula. Try it with BigFloat and Measurement
    
    julia> big(MathPhysicalConstants.SI.PlanckConstantH)/(big(MathPhysicalConstants.SI.MassElectron)*big(MathPhysicalConstants.SI.SpeedOfLight))
    2.42631027637202010003687587191357482878156204816578736228540160944126721996979e-12

Let's switch to Earth's gravitational acceleration in MKS units.

    julia> PhysicalConstants.MKS.GravAccel
    9.80665

Or in CGS units.

    julia> MathPhysicalConstants.CGS.GravAccel
    980.665
    
last but not least in International System of Units (SI)
    
    julia> MathPhysicalConstants.SI.GravAccel
    9.80665
    
