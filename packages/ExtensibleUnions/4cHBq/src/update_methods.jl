function _update_all_methods_for_extensibleunion!(@nospecialize(u))
    global _registry_extensibleunion_to_genericfunctions
    for f in _registry_extensibleunion_to_genericfunctions[u]
        _update_all_methods_for_extensiblefunction!(f)
    end
    return u
end
function _update_all_methods_for_extensibleunion!(@nospecialize(u), p::Pair)
    global _registry_extensibleunion_to_genericfunctions
    for f in _registry_extensibleunion_to_genericfunctions[u]
        _update_all_methods_for_extensiblefunction!(f, p)
    end
    return u
end

function _update_all_methods_for_extensiblefunction!(@nospecialize(f))
    global _registry_genericfunctions_to_extensibleunions
    extensibleunions_for_this_genericfunction =
        _registry_genericfunctions_to_extensibleunions[f]
    for met in methods(f).ms
        _update_single_method!(f,
                               met.sig,
                               extensibleunions_for_this_genericfunction)
    end
    return f
end
function _update_all_methods_for_extensiblefunction!(@nospecialize(f), p::Pair)
    global _registry_genericfunctions_to_extensibleunions
    extensibleunions_for_this_genericfunction =
        _registry_genericfunctions_to_extensibleunions[f]
    for met in methods(f).ms
        _update_single_method!(f,
                               met.sig,
                               extensibleunions_for_this_genericfunction,
                               p)
    end
    return f
end

function _update_single_method!(@nospecialize(f::Function),
                                @nospecialize(oldsig::Type{<:Tuple}),
                                @nospecialize(unions::Set))
    global _registry_extensibleunion_to_members
    newsig = _replace_types(oldsig)
    for u in unions
        newsig = _replace_types(newsig, u =>
            _set_to_union(_registry_extensibleunion_to_members[u]))
    end
    if oldsig == newsig
    else
        oldsig_tuple = tuple(oldsig.types[2:end]...)
        newsig_tuple = tuple(newsig.types[2:end]...)
        @assert length(code_lowered(f, oldsig_tuple)) == 1
        codeinfo = code_lowered(f, oldsig_tuple)[1]
        @assert length(methods(f, oldsig_tuple).ms) == 1
        oldmet = methods(f, oldsig_tuple).ms[1]
        Base.delete_method(oldmet)
        addmethod!(f, newsig_tuple, codeinfo)
    end
    return f
end
function _update_single_method!(@nospecialize(f::Function),
                                @nospecialize(oldsig::Type{<:Tuple}),
                                @nospecialize(unions::Set),
                                p::Pair)
    global _registry_extensibleunion_to_members
    newsig = _replace_types(oldsig, p)
    for u in unions
        newsig = _replace_types(newsig, u =>
            _set_to_union(_registry_extensibleunion_to_members[u]))
    end
    if oldsig == newsig
    else
        oldsig_tuple = tuple(oldsig.types[2:end]...)
        newsig_tuple = tuple(newsig.types[2:end]...)
        @assert length(code_lowered(f, oldsig_tuple)) == 1
        codeinfo = code_lowered(f, oldsig_tuple)[1]
        @assert length(methods(f, oldsig_tuple).ms) == 1
        oldmet = methods(f, oldsig_tuple).ms[1]
        Base.delete_method(oldmet)
        addmethod!(f, newsig_tuple, codeinfo)
    end
    return f
end

function _update_single_method!(@nospecialize(f::Function),
                                @nospecialize(oldsig::Type{<:UnionAll}),
                                @nospecialize(unions::Set))
    throw(MethodError("Not yet implemented for when sig is a UnionAll"))
end
function _update_single_method!(@nospecialize(f::Function),
                                @nospecialize(oldsig::Type{<:UnionAll}),
                                @nospecialize(unions::Set),
                                p::Pair)
    throw(MethodError("Not yet implemented for when sig is a UnionAll"))
end

function _replace_types(sig::Type{<:UnionAll})
    throw(MethodError("Not yet implemented for when sig is a UnionAll"))
end
function _replace_types(sig::Type{<:UnionAll}, p::Pair)
    throw(MethodError("Not yet implemented for when sig is a UnionAll"))
end


# function _replace_types(sig::Core.SimpleVector)
#     v = Any[sig.types...]
#     for i = 2:length(v)
#         v[i] = _replace_types(v[i])
#     end
#     return Core.svec(v...)
# end
# function _replace_types(sig::Core.SimpleVector, p::Pair)
#     v = Any[sig.types...]
#     for i = 2:length(v)
#         v[i] = _replace_types(v[i], p)
#     end
#     return Core.svec(v...)
# end

function _replace_types(sig::Type{<:Tuple})
    v = Any[sig.types...]
    for i = 2:length(v)
        v[i] = _replace_types(v[i])
    end
    return Tuple{v...}
end
function _replace_types(sig::Type{<:Tuple}, p::Pair)
    v = Any[sig.types...]
    for i = 2:length(v)
        v[i] = _replace_types(v[i], p)
    end
    return Tuple{v...}
end

function _replace_types(::Type{Union{}})
    return Union{}
end
function _replace_types(sig::Type{Union{}}, p::Pair)
    if sig == p[1]
        return p[2]
    else
        return sig
    end
end

function _replace_types(sig::Union)
    union_length = Base.unionlen(sig)
    old_union_members = Base.uniontypes(sig)
    new_union_members = Vector{Any}(undef, union_length)
    for i = 1:union_length
        new_union_members[i] = _replace_types(old_union_members[i])
    end
    new_union = Union{new_union_members...}
    return new_union
end
function _replace_types(sig::Union, p::Pair)
    if sig == p[1]
        return p[2]
    else
        union_length = Base.unionlen(sig)
        old_union_members = Base.uniontypes(sig)
        new_union_members = Vector{Any}(undef, union_length)
        for i = 1:union_length
            new_union_members[i] = _replace_types(old_union_members[i], p)
        end
        new_union = Union{new_union_members...}
        return new_union
    end
end

function _replace_types(sig::Type)
    return sig
end
function _replace_types(sig::Type, p::Pair)
    if sig == p[1]
        return p[2]
    else
        return sig
    end
end

function _set_to_union(s::Set)
    result = Union{}
    for member in s
        result = Union{result, member}
    end
    return result
end
