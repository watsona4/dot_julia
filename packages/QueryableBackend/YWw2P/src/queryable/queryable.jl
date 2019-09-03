abstract type Queryable end

QueryOperators.query(x::Queryable) = x

IteratorInterfaceExtensions.isiterable(x::Queryable) = true
TableTraits.isiterabletable(x::Queryable) = true

function IteratorInterfaceExtensions.getiterator(x::Queryable)
    return x.getiterator(x)
end
