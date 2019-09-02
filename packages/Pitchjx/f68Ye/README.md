![pitchjx](./pitchjx.png)

Tools for extracting MLBAM PITCHf/x data.

## Install

```bash
julia -e 'using Pkg; Pkg.add("Pitchjx")'
```

## How to use

### Extract specific date's PITCHf/x data

```julia
using Pitchjx

data = pitchjx("2018-10-20")
```

### Extract Multiple dates' PITCHf/x data

```julia
using Pitchjx

data = pitchjx("2018-10-20", "2018-10-22")
```

## Reference

- [The Anatomy of a Pitch:Doing Physics with PITCHf/x Data](http://baseball.physics.illinois.edu/KaganPitchfx.pdf)
