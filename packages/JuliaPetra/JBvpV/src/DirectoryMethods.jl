export createDirectory

# has to be split from the declaration of Directory due to dependancy on files that require Directory

function getDirectoryEntries(directory::Directory{GID, PID, LID}, map::BlockMap{GID, PID, LID},
        globalEntries::AbstractArray{Number}, high_rank_sharing_procs::Bool=false)::Tuple{AbstractArray{PID}, AbstractArray{LID}} where GID <: Integer where PID <: Integer where LID <: Integer
    getDirectoryEntries(directory, map, Array{GID, 1}(undef, globalEntries), high_rank_sharing_procs)
end

function getDirectoryEntries(directory::Directory{GID, PID, LID}, map::BlockMap{GID, PID, LID},
        globalEntries::AbstractArray{GID})::Tuple{AbstractArray{PID}, AbstractArray{LID}} where GID <: Integer where PID <: Integer where LID <: Integer
    getDirectoryEntries(directory, map, globalEntries, false)
end


"""
    createDirectory(comm::Comm, map::BlockMap)
Create a directory object for the given Map
"""
function createDirectory(comm::Comm{GID, PID, LID}, map::BlockMap{GID, PID, LID})::BasicDirectory{GID, PID, LID} where GID <: Integer where PID <: Integer where LID <: Integer
    BasicDirectory{GID, PID, LID}(map)
end
