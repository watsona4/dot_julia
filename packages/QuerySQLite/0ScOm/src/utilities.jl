
function map_unrolled(call, variables::Tuple{})
    ()
end
function map_unrolled(call, variables)
    (call(first(variables)), map_unrolled(call, tail(variables))...)
end

function map_unrolled(call, variables1::Tuple{}, variables2::Tuple{})
    ()
end
function map_unrolled(call, variables1, variables2)
    (
        call(first(variables1), first(variables2)),
        map_unrolled(call, tail(variables1), tail(variables2))...
    )
end

function partial_map(call, fixed, variables::Tuple{})
    ()
end
function partial_map(call, fixed, variables)
    (
        call(fixed, first(variables)),
        partial_map(call, fixed, tail(variables))...
    )
end
function partial_map(call, fixed, variables1::Tuple{}, variables2::Tuple{})
    ()
end
function partial_map(call, fixed, variables1, variables2)
    (
        call(fixed, first(variables1), first(variables2)),
        partial_map(call, fixed, tail(variables1), tail(variables2))...
    )
end

function as_symbols(them)
    map_unrolled(Symbol, (them...,))
end
