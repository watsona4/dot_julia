CornerPlot
==========

CornerPlot.jl is a plotting package in julia built on top of Gadfly.jl.
Inspired by [corner.py[](occco[)](https://github.com/dfm/corner.py), it plots samples in multiple dimensions as a triangular
matrix of subplots showing the samples in pairs of dimensions. To use make
such a plot, simply call `corner` with an array of shape (nsamples, ndims)
or a DataFrame containing your samples:

```
corner(df)
```

Further optional arguments can be seen in the example IJulia notebook or in
the docstrings of the code.
