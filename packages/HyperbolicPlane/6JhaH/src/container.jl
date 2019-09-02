export HContainer, add_object!

import Base: collect, delete!


"""
`HContainer` is a device for holding a collection of hyperbolic objects.
It is like a set, but we have to do a lot of work before adding a new
element because equal hyperbolic objects might differ a tiny amount and
that would mess up hashing.

+ `C = HContainer()` creates a new container.
+ `C = HContainer(items...)` creates a new container with the items.
"""
struct HContainer
    objs::Set{HObject}
    function HContainer()
        A = Set{HObject}()
        new(A)
    end
end

function HContainer(args...)
    C = HContainer()
    add_object!(C,args...)
    return C
end

HContainer(HC::HContainer) = HContainer(collect(HC.objs)...)  # copy constructor

function in(X::HObject, C::HContainer)::Bool
    for Z in C.objs
        if Z==X
            return true
        end
    end
    return false
end


length(C::HContainer) = length(C.objs)

collect(C::HContainer) = collect(C.objs)

"""
`add_object!(C::HContainer, X::HObject)` adds `X` to the container `C`.
"""
function add_object!(C::HContainer, X::HObject)::Bool
    # see if we already have it
    if in(X,C)
        return false
    end

    # not here, so OK to add
    push!(C.objs, X)
    return true
end

function add_object!(C::HContainer, args...)
    for X in args
        add_object!(C,X)
    end
end

"""
`delete!(C::HContainer, X::HObject)` deletes `X` from the
container `C` returning `true` if successful (or `false` if
`X` was not in the container).
"""
function delete!(C::HContainer, X::HObject)::Bool
    # see if we already have it; if so, delete
    for Z in C.objs
        if Z==X
            delete!(C.objs, X)
            return true
        end
    end
    return false # never found
end

function show(io::IO, C::HContainer)
    print(io,"HContainer of size $(length(C))")
end
