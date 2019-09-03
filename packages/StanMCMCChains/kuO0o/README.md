# StanMCMCChains

[![Build Status](https://travis-ci.org/StanJulia/StanMCMCChains.jl.svg?branch=master)](https://travis-ci.org/StanJulia/StanMCMCChains.jl)

[![Coverage Status](https://coveralls.io/repos/StanJulia/StanMCMCChains.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/StanJulia/StanMCMCChains.jl?branch=master)

[![codecov.io](http://codecov.io/github/StanJulia/StanMCMCChains.jl/coverage.svg?branch=master)](http://codecov.io/github/StanJulia/StanMCMCChains.jl?branch=master)


## Introduction

This package converts the output produced by CmdStan.jl to a TuringLang/Chains object suitable for further processing by the [MCMCChains](https://github.com/TuringLang/MCMCChains.jl) package.

## Usage

In the definition of the Stanmodel, request the output_format=:mcmcchains:

```
  stanmodel = Stanmodel(num_samples=1200, thin=2, name="bernoulli", 
    model=bernoullimodel, output_format=:mcmcchains);
```

The subsequent call to stan() will now return a MCMCChains.Chains object in chains as in the included Bernoulli example:

```
... (snipped)

  rc, chains, cnames = stan(stanmodel, observeddata, ProjDir, diagnostics=false,
    CmdStanDir=CMDSTAN_HOME);
    
... (snipped)

```

It is also possible to do this conversion after the call to stan():

```
  stanmodel = Stanmodel(num_samples=1200, thin=2, name="bernoulli", 
    model=bernoullimodel);

  rc, sims, cnames = stan(stanmodel, observeddata, ProjDir, diagnostics=false,
    CmdStanDir=CMDSTAN_HOME);
  
  chains = convert_a3d(sims, cnames, Val(:mcmcchains))

```

The bernoulli example also demonstrated how a Chains object can be saved and restored.

## Further examples

Several more examples will be contained in [StanMCMCChainsExamples.jl](https://github.com/StanJulia/StanMCMCChainsExamples.jl).