# MPIFiles.jl

*Magnetic Particle Imaging Files*

## Introduction

MPIFiles.jl is a Julia package for handling files that are related to the tomographic imaging method magnetic particle imaging. It supports different file formats:
* Brukerfiles, i.e. files stored using the preclinical MPI scanner from Bruker
* [Magnetic Particle Imaging Data Format (MDF) files](https://github.com/MagneticParticleImaging/MDF)
* IMT files, i.e. files created at the Institute of Medical Engineering in Lübeck

For all of these formats there is full support for reading the files. Write support is currently
only available for MDF files. All files can be converted to MDF files using this capability.

MPIFiles.jl provides a generic interface for different MPI files. In turn it is possible
to write generic algorithms that work for all supported file formats.

MPI files can be divided into three different categories
* [Measurements](@ref)
* [System Matrices](@ref)
* [Reconstruction Results](@ref)
Each of these file types is supported and discussed in the referenced pages.

## Installation

Start julia and open the package mode by entering `]`. Then enter
```julia
add MPIFiles
```
This will install the packages `MPIFiles.jl` and all its dependencies.

## License / Terms of Usage

The source code of this project is licensed under the MIT license. This implies that
you are free to use, share, and adapt it. However, please give appropriate credit by citing the project.

## Community Guidelines

If you have problems using the software, find bugs, or have feature requests please use the [issue tracker](https://github.com/MagneticParticleImaging/MPIFiles.jl/issues) to contact us. For general questions we prefer that you contact the current maintainer directly by email.

We welcome community contributions to `MPIFiles.jl`. Simply create a [pull request](https://github.com/MagneticParticleImaging/MPIFiles.jl/pulls) with your proposed changes.

## Contributors

* [Tobias Knopp](https://www.tuhh.de/ibi/people/tobias-knopp-head-of-institute.html) (maintainer)
* [Martin Möddel](https://www.tuhh.de/ibi/people/martin-moeddel.html)
* [Patryk Szwargulski](https://www.tuhh.de/ibi/people/patryk-szwargulski.html)
* [Florian Griese](https://www.tuhh.de/ibi/people/florian-griese.html)
* [Franziska Werner](https://www.tuhh.de/ibi/people/franziska-werner.html)
* [Nadine Gdaniec](https://www.tuhh.de/ibi/people/nadine-gdaniec.html)
* [Marija Boberg](https://www.tuhh.de/ibi/people/marija-boberg.html)
