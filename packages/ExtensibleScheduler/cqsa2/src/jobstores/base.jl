using UUIDs


"""
`AbstractJobStore` is an abstract type for jobstores

A jobstore is a data structure which is responsible of
storing jobs that should be executed later.
"""
abstract type AbstractJobStore end

"""
    get_job_id()

Returns a job identifier (a `job_id`).

It's preferable to use `get_job_id(jobstore)` to ensure
that a `job_id` is unique for a given `JobStore`.
"""
function get_job_id()
    string(UUIDs.uuid4())
end

include("memory.jl")