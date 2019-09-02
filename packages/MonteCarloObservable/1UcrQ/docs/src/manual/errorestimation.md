# Error estimation

Automatic estimation of the [standard error of the mean](https://en.wikipedia.org/wiki/Standard_error) (one-sigma error bars) is based on a binning analysis.

!!! warning "Standard error versus standard deviation"

    Be careful not to confuse the terms "standard error (of the mean)" and "standard deviation". Quoting [Wikipedia](https://en.wikipedia.org/w/index.php?title=Standard_error&section=8#Standard_error_of_mean_versus_standard_deviation) on this:
    > Put simply, the **standard error** of the sample mean is an estimate of how far the sample mean is likely to be from the population mean, whereas the **standard deviation** of the sample is the degree to which individuals within the sample differ from the sample mean. If the population **standard deviation** is finite, the **standard error** of the mean of the sample will tend to zero with increasing sample size, because the estimate of the population mean will improve, while the **standard deviation** of the sample will tend to approximate the population **standard deviation** as the sample size increases.

    The standard error of an observable can be obtained by `error(obs)` and the standard deviation by `std(obs)`.

## Binning analysis

For $N$ uncorrelated measurements of an observable $O$ the statistical standard error $\sigma$, the root-mean-square deviation of the time series mean from the true mean, falls off with the number of measurements $N$ according to

$\sigma = \frac{\sigma_{O}}{\sqrt{N}},$

where $\sigma_{O}$ is the standard deviation of the observable $O$.

In a Markov chain Monte Carlo sampling, however, measurements are usually correlated due to the fact that the next step of the Markov walker depends on his current position in configuration space. One way to estimate the statistical error in this case is by binning analysis. The idea is to partition the time series into bins of a fixed size large enough such that neighboring bins are uncorrelated, that is there means are uncorrelated. For this procedure to be reliable we need both a large bin size (larger than the Markov time scale of correlations, typically called autocorrelation time) and many bins (to suppress statistical fluctuations).

The typical procedure is to look at the estimate for the statistical error as a function of bin size and expect a plateau (convergence of the estimate). You can do this manually using `errorplot(obs)`. Automatically, the package uses a plateau-finder algorithm to check wether convergence has been reached. Note, however, that finding a plateau (with expected fluctuations) numerically in an automated manner isn't trivial. Hence, the algorithm is somewhat heuristic as it is in other software like [ALPS](http://alps.comp-phys.org/mediawiki/index.php/Main_Page) and shouldn't be trusted without further manual checking. It is conservative though in the sense that it tends to be rather false-negative than false-positive.

From this we conclude that estimates for the error really only become reliable in the limit of many measurements.

### References

J. Gubernatis, N. Kawashima, and P. Werner, [Quantum Monte Carlo Methods: Algorithms for Lattice Models](https://www.cambridge.org/core/books/quantum-monte-carlo-methods/AEA92390DA497360EEDA153CF1CEC7AC), Book (2016)

V. Ambegaokar, and M. Troyer, [Estimating errors reliably in Monte Carlo simulations of the Ehrenfest model](http://aapt.scitation.org/doi/10.1119/1.3247985), American Journal of Physics **78**, 150 (2010)

## Jackknife analysis

See for example the corresponding [Wikipedia article](https://en.wikipedia.org/wiki/Jackknife_resampling).
