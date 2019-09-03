# ScHoLP

### Simplicial closure and Higher-order Link Prediction

For information on using this library, refer to the tutorial repository [here](https://github.com/arbenson/ScHoLP-Tutorial).

##### Note on multi-threading

This library supports multithreading through Julia's Base.Threads. However, in some cases, it can conflict with the multithreading in BLAS routines. Essentially, these are cases where an iterative solver is used to solve a large number of linear systems and there is simple parallelism over the linear systems being solved. To avoid the conflicts with BLAS threading, here is an example of how one should start Julia.

```bash
export OPENBLAS_NUM_THREADS=1
export GOTO_NUM_THREADS=1
export OMP_NUM_THREADS=1
JULIA_NUM_THREADS=64 julia
```

