# ZOOclient

[![license](https://img.shields.io/github/license/mashape/apistatus.svg?maxAge=2592000)](https://github.com/eyounx/ZOOjl/blob/master/LICENSE)

ZOOclient is the client part of Distributed [ZOOpt](https://github.com/eyounx/ZOOpt). In order to improve the efficiency of handling distributed computing, we use Julia language to code the client end for its high efficiency and Python-like features. Meanwhile, the servers are still coded in Python. Therefore, users programs their objective function in Python as usual, and only need to change a few lines of the client Julia codes (just as easy to understand as Python). 

Two  zeroth-order optimization methods are implemented in ZOOclient release 0.1, respectively are Asynchronous Sequential RACOS  (ASRacos) method and parallel pareto optimization for subset selection method (PPOSS, IJCAI'16)

**Documents:** [Wiki of Distributed ZOOpt](https://github.com/eyounx/ZOOpt/wiki/Tutorial-of-Distributed-ZOOpt)

**Single-thread version:** [ZOOpt](https://github.com/eyounx/ZOOpt)

**Server part of Distributed ZOOpt**: [ZOOsrv](https://github.com/eyounx/ZOOsrv)

## Installation

If you have not done so already, [download and install Julia](http://julialang.org/downloads/) (Any version starting with 0.6 should be fine.  ZOOclient is not compatible with julia 1.0 temporarily. )

To install ZOOclient, start Julia and run:

```julia
Pkg.add("ZOOclient")
```

This will download ZOOclient and all of its dependencies.

## Release 0.1

* Include the asynchronous version of the general optimization method Sequential RACOS (AAAI'17)
* Include the Parallel Pareto Optimization for Subset Selection  method (PPOSS, IJCAI'16)

  ​			
  ​		
  ​	
