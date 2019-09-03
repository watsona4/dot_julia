# RainFARM Julia module Documentation

RainFARM.jl is a Julia library and a collection of command-line interface tools implementing the RainFARM (Rainfall Filtered Autoregressive Model) stochastic precipitation downscaling method adapted for climate models.
Adapted for climate downscaling according to (D'Onofrio et al. 2018) and with fine-scale orographic weights (Terzago et al. 2018).

RainFARM (Rebora et al. 2006) is a metagaussian stochastic downscaling procedure based on the extrapolation of the coarse-scale Fourier power spectrum  of a spatio-temporal precipitation field to small scales.  

```@contents
```

## Functions

```@docs
rainfarm
rfweights
fft3d
fitslopex
lon_lat_fine
read_netcdf2d
write_netcdf2d
agg
interpola
initmetagauss
metagauss
gaussianize
smoothconv
mergespec_spaceonly
downscale_spaceonly
```
## Index

```@index
```

## Scientific references

- Terzago, S., Palazzi, E., and von Hardenberg, J. (2018). Stochastic downscaling of precipitation in complex orography: a simple method to reproduce a realistic fine-scale climatology, Nat. Hazards Earth Syst. Sci., 18, 2825-2840, doi: <https://doi.org/10.5194/nhess-18-2825-2018>

- D’Onofrio, D., Palazzi, E., von Hardenberg, J., Provenzale, a., & Calmanti, S. (2014). Stochastic Rainfall Downscaling of Climate Models. Journal of Hydrometeorology, 15(2), 830–843. doi: <https://doi.org/10.1175/JHM-D-13-096.1> 

- Rebora, N., Ferraris, L., von Hardenberg, J., & Provenzale, A. (2006). RainFARM: Rainfall Downscaling by a Filtered Autoregressive Model. Journal of Hydrometeorology, 7(4), 724–738. doi: <https://doi.org/10.1175/JHM517.1> 
 
## Authors

*Julia module* - J. von Hardenberg (2016-2018). Based on a Matlab version for climate downscaling by D. D'Onofrio and J. von Hardenberg (2014).  Original Matlab code following Rebora et al. 2006, developed jointly by ISAC-CNR and CIMA Foundation in 2004-2006.

