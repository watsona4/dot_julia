# SpatialJackknife.jl

This package can be used to perform jackknife resampling on spatial data in an arbitrary number of dimensions
with arbitrary geometry. It exports two function `get_subvols`, for assigning jackknife subvolumes to the data
points, and `jackknife` for performing jackknife estimation of the mean and variance of a given estimator function.
An example of how to use this code with SDSS data can be found in the `notebooks` directory. To run this, however,
you will have to download the data separately.

`get_subvols` has two methods which can be used for data that is either distributed in a regular cubic volume or
distributed in a more complex geometry for which you must provide a set of randomly distributed points that define
the geometry:

1. Regular cubic geometry

```
get_subvols(data::Array{Float64, 2};
            side_divs::Int = 3,
            edges::Array{Array{Float64, 1}, 1} = Array{Array{Float64, 1}, 1}(undef, 0))
```


  * `data` is a 2-dimensional array of shape (N, ndims)
  * 'side_divs' is the number of volumes per dimension to divide the data into
  * 'edges' can be given either as the extrema in each dimension or just once and taken as the extrema for all dimensions

2. Arbitrary geometry defined by random points

```
get_subvols(data::Array{Float64, 2},
            randmask::Array{Float64, 2},
            side_divs::Int,
            metric::Metric = Euclidean())::Array{Int, 1}
```

  * `data` is a 2-D array as above
  * `randmask` is a 2-D array with the same number of dimensions defining the geometry of your dataset
  * `side_divs` is the number of volumes per dimension to subdivide the sample into 
  * `metric` is an optional parameter to define the distance between points, assumed to be Euclidean

### Jackknifing

Once the subvolumes have been determined, the 'jackknife' function can be used to find the mean and covariance
of your desired estimator:

    jackknife(obsfunc::Function,
              data::Array{Float64, 2},
              subvolinds::Array{Int, 1},
              args::Tuple = ();
              covar::Bool = true)
              
- 'obsfunc' is a function that computes your estimator and takes the form

    obsfunc(data, args...)
    
* 'subvolinds' is an integer array of subvolume indices that has the same length as the number of data points
and is returned by 'get_subvols'
* 'args' is an optional tuple of other arguments to pass to your estimator function
* 'covar' is a boolean that determines whether a full covariance matrix is computed (for 'true') for multidimensional
estimators, or just the diagonals ('false')
