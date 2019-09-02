
function create_partition(lengths::NTuple{N,Int}) where N
    num = 0
    partition = UnitRange{Int}[]
    len = [0; cumsum(collect(lengths))]
    partition = ntuple(i->(1:lengths[i]) .+ len[i], length(lengths))
    return partition
end

function create_partition(lengths::NTuple{N,Int}, names::NTuple{N,Symbol}) where {N,T}
    partition = Tuple(create_partition(lengths))
    named_part = NamedTuple{names}(partition)
    return named_part
    # return named_part::NamedTuple{M,NTuple{N,UnitRange{Int}}}
end

function create_partition2(len1::NTuple{N1,Int},len2::NTuple{N2,Int}) where {N1,N2}
    n1 = length(len1)
    n2 = length(len2)
    num1 = [0; cumsum(collect(len1))]
    num2 = [0; cumsum(collect(len2))]

    inds = [(i,j) for i = 1:n1 for j=1:n2]
    inds = Tuple(1:n1*n2)
    function get_inds(x)
        i = cart1(x,n1,n2)
        j = cart2(x,n1,n2)
        (1:len1[i]) .+ num1[i], (1:len2[j]) .+ num2[j]
    end
    partition = map(get_inds, ntuple(i->i,n1*n2))
    return partition
end
create_partition2(lengths::NTuple{N,Int}) where N = create_partition2(lengths,lengths)


function cart1(i,n,m)
    ((i-1) ÷ m)+1
end

function cart2(i,n,m)
    v = i % m
    v == 0 ? m : v
end

function create_partition2(len1::NTuple{N1,Int},len2::NTuple{N2,Int},
        names::Val{NAMES}) where {N1,N2,NAMES}
    n1 = length(len1)
    n2 = length(len2)
    partition = create_partition2(len1,len2)
    named_part = create_nt(names,partition)
end

function create_nt(::Val{names},part) where {names}
    NamedTuple{names}(part)
end

function combine_names(names1,names2)
    n1 = length(names1)
    n2 = length(names2)
    function get_inds(x)
        i = cart1(x,n1,n2)
        j = cart2(x,n1,n2)
        Symbol(string(names1[i])*string(names2[j]))
    end
    partition = map(get_inds, ntuple(i->i,n1*n2))
end
