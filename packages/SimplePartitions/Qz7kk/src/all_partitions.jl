export all_partitions
"""
`all_partitions(A::Set)` creates a `Set` containing all possible
partitions of the set `A`.

`all_partitions(n::Int)` creates the `Set` of all partitions of
the set `{1,2,...,n}`.

Both of these take an optional second argument `k` to specify that
only partitions with exactly `k` parts should be returned.
"""
function all_partitions(A::Set{T}) where T
    if length(A) < 2
        P = Partition(A)
        return Set([P])
    end
    # Set aside one element of A and recurse
    x = first(A)
    B = deepcopy(A)
    delete!(B,x)

    PB = all_partitions(B)
    PA = Set{Partition{T}}()  # place to hold partitions we create

    for P in PB
        # case 1: include x as a singleton
        P_parts = parts(P)
        push!(P_parts, Set([x]))
        Q = PartitionBuilder(P_parts)
        push!(PA,Q)

        # case 2: insert x into existing parts
        parts_list = collect(parts(P))
        np = length(parts_list)
        for k=1:np
            push!(parts_list[k],x)  # insert x into k'th part
            Q = PartitionBuilder(Set(parts_list)) # build the partition
            push!(PA,Q)
            delete!(parts_list[k],x) # take it back out
        end

    end
    return PA
end

function all_partitions(n::Int)
    if n < 0
        error("argument must be a nonnegative integer")
    end
    A = Set{Int}(collect(1:n))
    return all_partitions(A)
end


function all_partitions(A::Set{T},k::Int) where T
    if k<0
        error("Number of partitions (k) must be nonnegative")
    end
    n = length(A)
    PA = Set{Partition{T}}()
    if k>n  # no partitions possible
        return PA
    end
    if n==0 # special case when A is empty
        push!(PA, Partition(A))
        return PA
    end
    if k==0 # special case, no partitions
        return PA
    end

    x = first(A)
    B = deepcopy(A)
    delete!(B,x)

    # Step 1: partitions in which x is a singleton
    PB = all_partitions(B,k-1)
    for P in PB
        parts_set = parts(P)
        push!(parts_set, Set([x]))  # {x} as a single part
        Q = PartitionBuilder(parts_set)
        push!(PA,Q)
    end

    # Step 2: partitions in which x is with others
    PB = all_partitions(B,k)
    for P in PB
        for j=1:k  # each P has exactly k parts
            parts_list = collect(parts(P))
            push!(parts_list[j], x)  # add x to part j
            Q = PartitionBuilder(Set(parts_list))
            push!(PA,Q)
        end
    end

    return PA
end


function all_partitions(n::Int,k::Int)
    if n < 0
        error("argument must be a nonnegative integer")
    end
    A = Set{Int}(collect(1:n))
    return all_partitions(A,k)
end
