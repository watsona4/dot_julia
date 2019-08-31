CORBITS
=======

CORBITS is the Computed Occurrence of Revolving Bodies for the Investigation of Transiting Systems by Joshua Brakensiek and Darin Ragozzine.

Introduction
------------

To start using CORBITS, clone the repository.

    git clone https://github.com/jbrakensiek/CORBITS.git

You can build the CORBITS library and usage examples by typing `make`.  To only build the CORBITS library, type `make lib`.

Requirements
------------

To use the base of CORBITS (the library and CLI), only a reasonably modern version of g++ is necessary. To fully utilize some of the examples, there are additional requirements.

- Python 2.x with the packages NumPy, SciPy, and matplotlib.
- R with the packages ADGofTest and psych.

Examples
--------

The following usage examples are available for CORBITS. 

* `kepler-11`: Reproduces the data making the golden curve in Figure 4 of Lissauer, et. al., 2011.  See [here](http://arxiv.org/abs/1102.0291).
* `kepler-90`: Same as `kepler-11`, except run on the Kepler 90 dataset.
* `period-dist`: Produces a period-ratio distribution of the Kepler Candidates (KOIs) which is geometrically debiased.  It utilizes the most recent data from the NASA Exoplanet Archive.  Summary histograms using matplotlib can be made with `make period-hist`.
* `mhs-dist`: Same as `period-dist` except computing the mutual hill spheres instead of period-ratios.
* `case-trans': Computes the mutual inclinations of the "phase transitions" of the transiting geometry (see the Brakensiek & Ragozzine for more details).
* `solar-system`: Calculates the transit probabilities of the Solar System from the perspective of a distant external observer.
* `koi-table': Generates the LaTeX table in Brakensiek & Ragozzine of observation probabilities of various KOI systems.

To build an example, type `make name-of-example`.  To run it, type `make run-name-of-example` (or run the binary file).

-------

If you find CORBITS useful, please cite (Brakensiek & Ragozzine, in prep.).
