# StanDataFrames

[![Build Status](https://travis-ci.org/StanJulia/StanDataFrames.jl.svg?branch=master)](https://travis-ci.org/StanJulia/StanDataFrames.jl)

[![Coverage Status](https://coveralls.io/repos/StanJulia/StanDataFrames.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/StanJulia/StanDataFrames.jl?branch=master)

[![codecov.io](http://codecov.io/github/StanJulia/StanDataFrames.jl/coverage.svg?branch=master)](http://codecov.io/github/StanJulia/StanDataFrames.jl?branch=master)


# Introduction

StanDataFrames generates a nchains DataFrames from the cmdstan generated sample files.

As in [above example](https://github.com/StanJulia/StanDataFrames.jl/blob/master/examples/Bernoulli/bernoulli.jl):

```
... (snipped)

  stanmodel = Stanmodel(num_samples=1200, thin=2, name="bernoulli", 
    model=bernoullimodel, output_format=:dataframe);

  rc, dfa, cnames = stan(stanmodel, observeddata, ProjDir, diagnostics=false,
    CmdStanDir=CMDSTAN_HOME);

... (snipped)

```


It is also possible to convert after the fact:

```
... (snipped)

  stanmodel = Stanmodel(num_samples=1200, thin=2, name="bernoulli", 
    model=bernoullimodel);

  rc, sim, cnames = stan(stanmodel, observeddata, ProjDir, diagnostics=false,
    CmdStanDir=CMDSTAN_HOME);
    
  @test 0.1 <  mean(sim[:, 8, :]) < 0.5
  
  dfa = convert_a3d(sim, cnames, Val(:dataframe))

... (snipped)

```


