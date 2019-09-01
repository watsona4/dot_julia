using StructC14N
using Test

template = (xrange=NTuple{2,Number},
            yrange=NTuple{2,Number},
            title="A string")

c = canonicalize(template,
              (xr=(1,2), tit="Foo"))

@test c.xrange == (1, 2)
@test ismissing(c.yrange)
@test c.title == "Foo"


c = canonicalize(template,
              ((1,2), (3.3, 4.4), "Foo"))

@test c.xrange == (1, 2)
@test c.yrange == (3.3, 4.4)
@test c.title == "Foo"


c = canonicalize(template,
              xr=(21,22), tit="Bar")
@test c.xrange == (21, 22)
@test ismissing(c.yrange)
@test c.title == "Bar"


mutable struct AStruct
    xrange::NTuple{2, Number}
    yrange::NTuple{2, Number}
    title::String
end

template = AStruct((0,0), (0., 0.), "A string")

c = canonicalize(template,
              (xr=(1,2), tit="Foo"))

@test c.xrange == (1, 2)
@test c.yrange == (0., 0.)
@test c.title == "Foo"

c = canonicalize(template,
              ((1,2), (3.3, 4.4), "Foo"))

@test c.xrange == (1, 2)
@test c.yrange == (3.3, 4.4)
@test c.title == "Foo"

c = canonicalize(template,
              ((11,12), (13.3, 14.4), "Foo"))
@test c.xrange == (11, 12)
@test c.yrange == (13.3, 14.4)
@test c.title == "Foo"


c = canonicalize(template,
              xr=(21,22), tit="Bar")
@test c.xrange == (21, 22)
@test c.yrange == (0., 0.)
@test c.title == "Bar"


function wrapper(template; kwargs...)
    return canonicalize(template; kwargs...)
end
c = wrapper(template; xr=(31,32), tit="BAZ")
@test c.xrange == (31, 32)
@test c.yrange == (0., 0.)
@test c.title == "BAZ"




configtemplate = (optStr=String,
                  optInt=Int,
                  optFloat=Float64)

configentry = "aa, 1, 2"
c = canonicalize(configtemplate, (split(configentry, ",")...,))
@test c.optStr == "aa"
@test c.optInt == 1
@test c.optFloat == 2.0

configentry = "optFloat=20, optStr=\"aaa\", optInt=10"
c = canonicalize(configtemplate, eval(Meta.parse("($configentry)")))
@test c.optStr == "aaa"
@test c.optInt == 10
@test c.optFloat == 20.0


