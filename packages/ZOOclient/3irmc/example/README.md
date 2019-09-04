# Optimization Examples

Two examples are included in this directory.

`client.jl` contains the client code to optimize Ackley function using Asynchronous Sequential Racos method, which is the default algorithm using in ZOOclient.

`subsetsel_client.jl`  contains the client code to solve a subset selection problem using Parallel Pareto Optimization for Subset Selection (PPOSS) method.

After running the corresponding servers, type the following command to get the results.

```
$ ./julia -p 4 /path/to/your/directory/ZOOclient/examples/client.jl
```

Detailed description can be found in [Quick Start](https://github.com/eyounx/ZOOpt/wiki/Tutorial-of-Distributed-ZOOpt).
