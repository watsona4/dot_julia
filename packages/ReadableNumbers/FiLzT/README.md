# ReadableNumbers.jl

### Extended precision floating point values made more easily readable.
     
##### Copyright © 2016-2019 by Jeffrey Sarnoff.   Released under the MIT License.

#####   [![Build Status](https://travis-ci.org/JuliaLang/METADATA.jl.svg?branch=metadata-v2)](https://travis-ci.org/JuliaLang/METADATA.jl)

### installation
`pkg> add ReadableNumbers`
 
### use
```julia
> using ReadableNumbers

> setprecision(BigFloat, 192)
> goldenratio = BigFloat(golden)
1.6180339887498948482045868343656381177203091798057628621355

> readable(goldenratio)
"1.61803_39887_49894_84820_45868_34365_63811_77203_09179_80576_28621_355"

> ReadableNumStyle(3,'⋅')
> readable(goldenratio)
"1.618⋅033⋅988⋅749⋅894⋅848⋅204⋅586⋅834⋅365⋅638⋅117⋅720⋅309⋅179⋅805⋅762⋅862⋅135⋅5"

# ReadableNumStyle( integer_group, fractional_group, integer_sep, fractional_sep, decimal_point )
> ReadableNumStyle(3, 5, ',', '◦', '⬩' )

> show_readable(goldenratio)
1⬩61803◦39887◦49894◦84820◦45868◦34365◦63811◦77203◦09179◦80576◦28621◦355

> show_readable( factorial( 32%Int128 ) )
263,130,836,933,693,530,167,218,012,160,000,000


```

