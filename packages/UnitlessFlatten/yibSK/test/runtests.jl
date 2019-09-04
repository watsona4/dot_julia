using UnitlessFlatten, Unitful, Test
import UnitlessFlatten: flattenable

@flattenable struct Partial{T}
    a::T | true
    b::T | true
    c::T | false
end

@flattenable struct NestedPartial{P,T}
    np::P | true
    nb::T | true
    nc::T | false
end

# With units
partialunits = Partial(1.0u"s", 2.0u"s", 3.0u"s")
nestedunits = NestedPartial(Partial(1.0u"km", 2.0u"km", 3.0u"km"), 4.0u"g", 5.0u"g") 
@test flatten(Vector, partialunits) == [1.0, 2.0]
@test flatten(Vector, reconstruct(partialunits, flatten(Vector, partialunits))) == flatten(Vector, partialunits)
@test flatten(Tuple, reconstruct(partialunits, flatten(Tuple, partialunits))) == flatten(Tuple, partialunits)
@test flatten(Vector, reconstruct(nestedunits, flatten(Vector, nestedunits))) == flatten(Vector, nestedunits)
@test flatten(Tuple, reconstruct(nestedunits, flatten(Tuple, nestedunits))) == flatten(Tuple, nestedunits)
@inferred flatten(Tuple, reconstruct(nestedunits, flatten(Tuple, nestedunits))) == flatten(Tuple, nestedunits)
