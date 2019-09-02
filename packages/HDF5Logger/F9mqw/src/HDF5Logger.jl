"""
    HDF5Logger

Creates an object for logging frames of data to an HDF5 file. The frames are
expected to have the same size, and the total number of frames to log is
expected to be known in advance. It currently works with scalars, vectors, and
matrices of basic types that the HDF5 package supports.

# Example 1: Logging a Vector over Time

```julia
log = Log("my_file.h5") # Create a logger.
num_frames = 100        # Set the total number of frames to log.
example_data = [1., 2., 3.] # Create an example of a frame of data.
add!(log, "/a_vector", example_data, num_frames) # Create the stream.
log!(log, "/a_vector", [4., 5., 6.]) # Log a single frame of data.
log!(log, "/a_vector", [7., 8., 9.]) # Log the next frame.
close!(log) # Always clean up when done. Use try-catch to make sure.

# Read it back out using the regular HDF5 library.
using HDF5
x = HDF5.h5open("my_file.h5", "r") do logs
    read(logs, "/a_vector")
end
```

# Example 2: Logging a Scalar over Time

The underlying HDF5 library (HDF5.jl) logs things as arrays, so passing in
scalars will result in 1-by-n arrays in the HDF5 file, instead of an n-length
Vector. One can retrieve the n-length Vector by using `squeeze`. E.g.:

```julia
log = Log("my_file.h5") # Create a logger.
add!(log, "/a_scalar", 0., 1000) # Create stream with space for 1000 samples.
log!(log, "/a_scalar", 0.1) # Log a single frame of data.
log!(log, "/a_scalar", 0.2) # Log the next frame.
close!(log) # Always clean up when done. Use try-catch to make sure.

# Read it back out using the regular HDF5 library.
using HDF5
t = HDF5.h5open("my_file.h5", "r") do logs
    read(logs, "/a_scalar")
end # t is now a 1-by-1000 Array.
t = squeeze(t, 1) # Make an n-element Vector.
```

# Notes

One often needs to `log!` immediately after an `add!`, so the `add!` function
can also log its example data as the first frame for convenience. Just use:

```julia
add!(log, "/group/name", data, num_frames, true) # Add stream; log data.
```

"""
module HDF5Logger

using HDF5

export Log, add!, log!, close!

mutable struct Stream
    count::Int64
    length::Int64
    rank::Int64
    dataset::HDF5Dataset
end

struct Log
    streams::Dict{String,Stream}
    file_id::HDF5File
    function Log(file_name::String)
        new(Dict{String,Stream}(), h5open(file_name, "w"))
    end
end

function prepare_group!(log::Log, slug::String)
    groups = filter(x->!isempty(x), split(slug, '/')) # Explode to group names
    group_id = g_open(log.file_id, "/") # Start at top group
    for k = 1:length(groups)-1 # For each group up to dataset
        if exists(group_id, String(groups[k]))
            group_id = g_open(group_id, String(groups[k]))
        else
            group_id = g_create(group_id, String(groups[k]))
        end
    end
    return (group_id, String(groups[end])) # Group ID and name of dataset
end

function add!(log::Log, slug::String, data, num_samples::Int64, keep::Bool = false)
    dims                    = isbits(data) ? 1 : size(data)
    group_id, group_name    = prepare_group!(log, slug)
    dataset_id              = d_create(group_id, group_name,
                                       datatype(eltype(data)),
                                       dataspace(dims..., num_samples))
    log.streams[slug]       = Stream(0, num_samples, length(dims), dataset_id)
    if keep
        log!(log, slug, data)
    end
end

function log!(log::Log, slug::String, data)
    @assert(haskey(log.streams, slug),
            "The logger doesn't have that key. Perhaps you need to `add` it?")
    @assert(log.streams[slug].count < log.streams[slug].length,
            "We've already used up all of the allocated space for this stream!")
    log.streams[slug].count += 1
    colons = (Colon() for i in 1:log.streams[slug].rank)
    log.streams[slug].dataset[colons..., log.streams[slug].count] = data
end

function close!(log::Log)
    close(log.file_id)
end

end # module
