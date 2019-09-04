# sparseQFCA
[![Build Status](https://travis-ci.com/mtefagh/sparseQFCA.svg?branch=master)](https://travis-ci.com/mtefagh/sparseQFCA)
[![Coverage Status](https://coveralls.io/repos/github/mtefagh/sparseQFCA/badge.svg?branch=master)](https://coveralls.io/github/mtefagh/sparseQFCA?branch=master)
[![codecov](https://codecov.io/gh/mtefagh/sparseQFCA.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mtefagh/sparseQFCA.jl)

*sparseQFCA* is a [<img src="https://julialang.org/v2/img/logo.svg" height="20" />](https://julialang.org/) package for the sparse [Quantitative Flux Coupling Analysis](https://mtefagh.github.io/qfca/).

## Usage
### `certificates, blocked, fctable = QFCA(S, rev)`

### Inputs
* `S`: the associated sparse **stoichiometric matrix**
* `rev`: the boolean vector with trues corresponding to the **reversible reactions**

### Outputs
* `certificates`: the fictitious metabolites for the **sparse positive certificates**
* `blocked`: the boolean vector with trues corresponding to the **blocked reactions**
* `fctable`: the resulting **flux coupling matrix**

## Quick Start
To get started, see [this Jupyter notebook](https://nbviewer.jupyter.org/github/mtefagh/demos/blob/master/sparseQFCA.ipynb) for a demonstration on how to use the sparseQFCA package.
The example data files `S.csv` and `rev.csv` are extracted from the [core *E. coli* model](http://systemsbiology.ucsd.edu/Downloads/EcoliCore).

## License
sparseQFCA is distributed under the [GNU General Public License v3.0](http://www.gnu.org/copyleft/gpl.html).
