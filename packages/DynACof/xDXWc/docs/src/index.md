# DynACof.jl: The Dynamic Agroforestry Coffee Crop Model

```@raw html
<img src="https://raw.githubusercontent.com/VEZY/DynACof/master/man/figures/logo.png" alt="logo" width="300" align="right" />
```

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://VEZY.github.io/DynACof.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://VEZY.github.io/DynACof.jl/dev)
[![Build Status](https://travis-ci.com/VEZY/DynACof.jl.svg?branch=master)](https://travis-ci.com/VEZY/DynACof.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/VEZY/DynACof.jl?svg=true)](https://ci.appveyor.com/project/VEZY/DynACof-jl)
[![Codecov](https://codecov.io/gh/VEZY/DynACof.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/VEZY/DynACof.jl)

## Overview

This is a Julia version of the DynACof model. To get to the R version, please follow this [link](https://vezy.github.io/DynACof).
DynACof is a process-based model that computes plot-scale Net Primary Productivity, carbon allocation, growth,
yield, energy, and water balance of coffee plantations according to management, while accounting for spatial effects using metamodels from the 3D process-based [MAESPA](https://maespa.github.io). The model also uses coffee bud and fruit cohorts for reproductive development to better represent fruit carbon demand distribution along the year.

## Installation

To download DynACof, simply execute these lines of code in the REPL:

```julia
Pkg.add(DynACof)
```

The package is tested routinely to pass all tests using Travis-CI (linux) and AppVeyor (Windows).

## Example

This is a basic example using the parameters and meteorology from Vezy et al. (2019). The default values of the parameters in DynACof are already the ones from Vezy et al. (2019). To use those default values, you have to put `"package"` for each parameter in `file_name`. The meteorology data can be downloaded from a [Github repository](https://github.com/VEZY/DynACof.jl_inputs) using the `download` command.

Execute this line of code to run a simulation over the whole period using both parameters values and meteorology from Vezy et al. (2019): 

```julia
using DynACof
file= download("https://raw.githubusercontent.com/VEZY/DynACof.jl_inputs/master/meteorology.txt")

Sim, Meteo, Parameters= dynacof(input_path= dirname(file), file_name= (constants= "package",site="package",meteo=basename(file),soil="package",coffee="package",tree="package"))

rm(file)
```

To use your own data, you have to tell DynACof where to find it using the `input_path` argument, and what are the file names with the `file_name` argument. A separate [Github repository](https://github.com/VEZY/DynACof.jl_inputs) is available for input files templates with values from Vezy et al. (2019), and some help on how to proceed.

Example of a simulation without shade trees:

```julia
Sim, Meteo, Parameters= dynacof(input_path= "the_path_where_you_downloaded_the_data/DynACof.jl_inputs",
                                file_name= (constants= "constants.jl",site="site.jl",meteo="meteorology.txt",
                                            soil="soil.jl",coffee="coffee.jl",tree=""));
```

## Code of conduct

Please note that this project is released with a [Contributor Code of Conduct](https://github.com/VEZY/DynACof.jl/blob/master/CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## Acknowledgments

The DynACof model was mainly developed thanks to the MACCAC
project\[1\], which was funded by the french ANR (Agence Nationale de la
Recherche). The authors were funded by CIRAD\[2\] and INRA\[3\]. The
authors are grateful for the support of the [Aquiares
farm](https://aquiares.com/) and the CATIE\[4\] for the long-term coffee
agroforestry trial, the SOERE F-ORE-T which is supported annually by
Ecofor, Allenvi and the French national research infrastructure
[ANAEE-F](http://www.anaee-france.fr/fr/); the CIRAD-IRD-SAFSE project
(France) and the PCP platform of CATIE. CoffeeFlux observatory was
supported and managed by CIRAD researchers. We are grateful to the staff
from Costa-Rica, in particular Alvaro Barquero, Alejandra Barquero,
Jenny Barquero, Alexis Perez, Guillermo Ramirez, Rafael Acuna, Manuel
Jara, Alonso Barquero for their technical and field support.

-----

<sub>The DynACof logo was made using
<a href="http://logomakr.com" title="Logo Makr">LogoMakr.com</a> </sub>

1.  **MACACC project ANR-13-AGRO-0005**, Viabilité et Adaptation des
    Ecosystèmes Productifs, Territoires et Ressources face aux
    Changements Globaux AGROBIOSPHERE 2013 program

2.  Centre de Coopération Internationale en Recherche Agronomique pour
    le Développement

3.  Institut National de la Recherche Agronomique

4.  Centro Agronómico Tropical de Investigación y Enseñanza


```@contents
```

## Index

```@index
```

```@autodocs
Modules = [DynACof]
```
