using ExtensibleUnions
using Test
using Traceur

abstract type AbstractCar end
abstract type AbstractFireEngine end

struct RedCar <: AbstractCar
end
struct BlueCar <: AbstractCar
    x
end

struct LadderTruck{T} <: AbstractFireEngine
    x::T
end
mutable struct WaterTender{T} <: AbstractFireEngine
    x::T
    y::T
end

struct RedColorTrait end
struct BlueColorTrait end

extensibleunion!(RedColorTrait)
extensibleunion!(BlueColorTrait)

describe(x) = "I don't know anything about this object"

methods(describe)
@test length(methods(describe)) == 1
@test @inferred describe(RedCar()) == "I don't know anything about this object"
@test @inferred describe(BlueCar(1)) == "I don't know anything about this object"
@test @inferred describe(LadderTruck{Int}(2)) == "I don't know anything about this object"
@test @inferred describe(WaterTender{Int}(3,4)) == "I don't know anything about this object"
@check describe(RedCar()) nowarn=[describe] maxdepth=typemax(Int)
@check describe(BlueCar(1)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(LadderTruck{Int}(2)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(WaterTender{Int}(3,4)) nowarn=[describe] maxdepth=typemax(Int)

describe(x::RedColorTrait) = "The color of this object is red"
extensiblefunction!(describe, RedColorTrait)
@test length(methods(describe)) == 2

describe(x::BlueColorTrait) = "The color of this object is blue"
extensiblefunction!(describe, BlueColorTrait)
@test length(methods(describe)) == 3

methods(describe)
@test length(methods(describe)) == 3
@test @inferred describe(RedCar()) == "I don't know anything about this object"
@test @inferred describe(BlueCar(1)) == "I don't know anything about this object"
@test @inferred describe(LadderTruck{Int}(2)) == "I don't know anything about this object"
@test @inferred describe(WaterTender{Int}(3,4)) == "I don't know anything about this object"
@check describe(RedCar()) nowarn=[describe] maxdepth=typemax(Int)
@check describe(BlueCar(1)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(LadderTruck{Int}(2)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(WaterTender{Int}(3,4)) nowarn=[describe] maxdepth=typemax(Int)

addtounion!(RedColorTrait, RedCar)

methods(describe)
@test length(methods(describe)) == 3
@test @inferred describe(RedCar()) == "The color of this object is red"
@test @inferred describe(BlueCar(1)) == "I don't know anything about this object"
@test @inferred describe(LadderTruck{Int}(2)) == "I don't know anything about this object"
@test @inferred describe(WaterTender{Int}(3,4)) == "I don't know anything about this object"
@check describe(RedCar()) nowarn=[describe] maxdepth=typemax(Int)
@check describe(BlueCar(1)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(LadderTruck{Int}(2)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(WaterTender{Int}(3,4)) nowarn=[describe] maxdepth=typemax(Int)

addtounion!(BlueColorTrait, BlueCar)

methods(describe)
@test length(methods(describe)) == 3
@test @inferred describe(RedCar()) == "The color of this object is red"
@test @inferred describe(BlueCar(1)) == "The color of this object is blue"
@test @inferred describe(LadderTruck{Int}(2)) == "I don't know anything about this object"
@test @inferred describe(WaterTender{Int}(3,4)) == "I don't know anything about this object"
@check describe(RedCar()) nowarn=[describe] maxdepth=typemax(Int)
@check describe(BlueCar(1)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(LadderTruck{Int}(2)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(WaterTender{Int}(3,4)) nowarn=[describe] maxdepth=typemax(Int)

addtounion!(RedColorTrait, AbstractFireEngine)

methods(describe)
@test length(methods(describe)) == 3
@test @inferred describe(RedCar()) == "The color of this object is red"
@test @inferred describe(BlueCar(1)) == "The color of this object is blue"
@test @inferred describe(LadderTruck{Int}(2)) == "The color of this object is red"
@test @inferred describe(WaterTender{Int}(3,4)) == "The color of this object is red"
@check describe(RedCar()) nowarn=[describe] maxdepth=typemax(Int)
@check describe(BlueCar(1)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(LadderTruck{Int}(2)) nowarn=[describe] maxdepth=typemax(Int)
@check describe(WaterTender{Int}(3,4)) nowarn=[describe] maxdepth=typemax(Int)
