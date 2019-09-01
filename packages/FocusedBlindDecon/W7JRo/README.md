# Focused Blind Deconvolution (FBD)
```latex
@article{bharadwaj2018focused,
  title={Focused blind deconvolution},
  author={Bharadwaj, Pawan and Demanet, Laurent and Fournier, Aim{\'e}},
  journal={arXiv preprint arXiv:1808.00166},
  year={2018}
}
```

A multi-channel blind deconvolution (BD) example is here. Choose the length of the Green's functions, source signal and data vectors:
```julia
ntg=20 # length of Green's functions
nr=40 # number of receivers
tfact=80 # 
nt = ntg*tfact # length of data
```
Then, we create some toy Green's functions:
```julia
gobs=randn(ntg, nr)
sobs=randn(nt)
```
Allocation of memory necessary to perform BD
```julia
bdpa=FocusedBlindDecon.BD(ntg, nt, nr, gobs=gobs, sobs=sobs);
```

```julia
plotobsmodel(pa.om)
```

```julia
FocusedBlindDecon.bd!(pa)
```
