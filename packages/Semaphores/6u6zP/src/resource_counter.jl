struct ResourceCounter
    path::String
    id::Cint
    nresources::Cint
    undo::Bool
    tok::Cftok
    handle::Cint
    counts::Vector{Cushort}

    function ResourceCounter(path::Union{String,Tuple{String,Integer}}, nresources::Integer=1; create::Bool=true, create_exclusive::Bool=false, permission::Integer=0o660, undo::Bool=false)
        id = 0
        if isa(path, Tuple)
            path,id = path
        end
        tok = ftok(path, id)
        handle = semcreate(tok, nresources; create=create, create_exclusive=create_exclusive, permission=permission)
        new(path, id, nresources, undo, tok, handle, Vector{Cushort}(undef, nresources))
    end
end

close(sem::ResourceCounter) = nothing
delete!(sem::ResourceCounter) = semrm(sem.handle)

function count(sem::ResourceCounter)
    semget(sem.handle, sem.counts)
    sem.counts
end
count(sem::ResourceCounter, which) = semget(sem.handle, which)

reset(sem::ResourceCounter, val::T, which=0) where {T<:Integer} = semset(sem.handle, Cint(val), which)
reset(sem::ResourceCounter, vals::Vector{T}) where {T<:Integer} = semset(sem.handle, convert(Vector{Cushort},vals))

change(sem::ResourceCounter, by::T, which=0; wait::Bool=true, undo::Bool=sem.undo) where {T<:Integer} = change(sem, [SemBuf(which,by;wait=wait, undo=undo)])
change(sem::ResourceCounter, operations::Vector{SemBuf}) = semop(sem.handle, operations)
