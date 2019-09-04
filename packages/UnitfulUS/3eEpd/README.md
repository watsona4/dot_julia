# UnitfulUS

[![Build Status](https://travis-ci.org/ajkeller34/UnitfulUS.jl.svg?branch=master)](https://travis-ci.org/ajkeller34/UnitfulUS.jl)
[![Coverage Status](https://coveralls.io/repos/github/ajkeller34/UnitfulUS.jl/badge.svg?branch=master)](https://coveralls.io/github/ajkeller34/UnitfulUS.jl?branch=master)
[![codecov.io](http://codecov.io/github/ajkeller34/UnitfulUS.jl/coverage.svg?branch=master)](http://codecov.io/github/ajkeller34/UnitfulUS.jl?branch=master)

A supplemental units package for [Unitful 0.1.0](https://github.com/ajkeller34/Unitful.jl.git)
or later.

## Defined units

All units defined are suffixed with `_us`.

- U.S. survey units (length) are also prefixed by `s`:
  `sinch_us` (inch), `sft_us` (foot), `sli_us` (link), `syd_us`
  (yard), `srd_us` (rod), `sch_us` (chain), `sfur_us` (furlong), `smi_us`
  (statute mile), `slea_us` (league).

- U.S. survey units (area) are prefixed by `s` where ambiguous:
  `sac_us` (acre), `town_us` (township).  

- U.S. dry volumes: `drypt_us` (dry pint), `dryqt_us` (dry quart), `pk_us` (dry
  peck), `bushel_us` (bushel).

- U.S. liquid volumes: `gal_us` (gallon), `qt_us` (quart), `pt_us` (pint),
  `cup_us` (cup), `gill_us` (gill / half cup), `floz_us` (fluid ounce),
  `tbsp_us` (culinary tablespoon), `tsp_us` (culinary teaspoon),
  `fldr_us` (fluid dram), `minim_us` (minim)

- U.S. mass units: `cwt_us` (hundredweight), `ton_us` (ton)

## Special features

This package defines a string macro `@us_str` that only searches for units from
this package. `@u_str` is the only exported symbol from the package. When using
the string macro, omit the `_us` suffix from units, as the macro will append it
for you.

Usage examples:

```jl
julia> using Unitful.DefaultSymbols, UnitfulUS

julia> us"gal" == UnitfulUS.gal_us
true

julia> 1us"gal" |> m^3
473176473//125000000000 m^3
```

As can be seen, the `us` string macro aids in the distinction of U.S. gallons from
other possible definitions of the gallon (Imperial gallon). Note that because
this package registers with the `@u_str` macro, you can mix units from this
package and the Unitful defaults so long as you include the `_us` suffix on units
from this package:

```jl
julia> using Unitful, UnitfulUS

julia> 1.0u"kg/gal_us"
1.0 kg galᵘˢ
```
