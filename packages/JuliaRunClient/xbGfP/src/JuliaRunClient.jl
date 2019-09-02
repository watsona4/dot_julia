module JuliaRunClient

using HTTP
using JSON
using ClusterManagers
using Base64
using Sockets
using Distributed

import Base: show
export Context, JuliaParBatch, JuliaParBatchWorkers, Notebook, JuliaBatch, PkgBuilder, Webserver, MessageQ, Generic
export getSystemStatus, listJobs, getAllJobInfo, getJobStatus, getJobScale, setJobScale, getJobEndpoint, deleteJob, tailJob, submitJob, updateJob, initParallel, self, waitForWorkers, @result, initializeCluster, releaseCluster, getEncodedURL

"""
Types of Jobs:
- JuliaParBatch
- JuliaParBatchWorkers
- Notebook
- JuliaBatch
- PkgBuilder
- Webserver
- MessageQ
- Generic
"""
abstract type JRunClientJob end

const JOBTYPE_LABELS = Vector{String}()
const JOBTYPE = Vector{Any}()
_JuliaClusterManager = nothing

as_label(::Type{T}) where {T<:JRunClientJob} = String(rsplit(string(T), '.'; limit=2)[end])

"""
Returns a reference to the current job.
"""
function self()
    jtype = ENV["JRUN_TYPE"]
    jname = ENV["JRUN_NAME"]
    jultype = JOBTYPE[something(findfirst(isequal(jtype), JOBTYPE_LABELS), 0)]
    jultype(jname)
end

for T in (:JuliaParBatch, :JuliaParBatchWorkers, :Notebook, :JuliaBatch, :PkgBuilder, :Webserver, :MessageQ, :Generic)
    @eval begin
        struct $T <: JRunClientJob
            name::String
        end
        push!(JOBTYPE, $T)
        push!(JOBTYPE_LABELS, as_label($T))
    end
end

struct ApiException <: Exception
    status::Int
    reason::String
    resp::HTTP.Response

    function ApiException(resp::HTTP.Response; reason::String="")
        isempty(reason) && (reason = get(HTTP.Messages.STATUS_MESSAGES, resp.status, reason))
        new(resp.status, reason, resp)
    end
end


"""
A JuliaRun client context.

Consists of:
- URL of the JuliaRun remote server
- an authentication token
- namespace to operate in

Default values of all parameters are set to match those inside a JuliaRun cluster.
- connects to a service endpoint at "juliarunremote-svc.juliarun"
- reads the namespace from the default secret
- presents the namespace service token (also read from the default secret) for authentication
"""
struct Context
    root::String
    token::String
    namespace::String
    readtimeout::Int
    connecttimeout::Int

    function Context(root::String="http://juliarunremote-svc.juliarun:80",
            token::String="/var/run/secrets/kubernetes.io/serviceaccount/token",
            namespace::String="/var/run/secrets/kubernetes.io/serviceaccount/namespace";
            readtimeout::Int=60, connecttimeout=60)
        _isfile(token) && (token = base64encode(read(token, String)))
        _isfile(namespace) && (namespace = read(namespace, String))
        new(root, token, namespace)
    end
end

show(io::IO, ctx::Context) = print(io, "JuliaRunClient for ", ctx.namespace, " @ ", ctx.root)

"""
Verifies if JuliaRun is running and is connected to a compute cluster.

Returns:
- boolean: true/false indicating success/failure
"""
getSystemStatus(ctx::Context) = _simple_query(ctx, "/getSystemStatus/")

"""
List all submitted jobs.

Returns:
- dictionary: of the form `{"jobname": { "type": "JuliaBatch" }...}`
"""
listJobs(ctx::Context) = _simple_query(ctx, "/listJobs/")

"""
List all submitted jobs.

Returns:
- dictionary: of the form `{"jobname": { "type": "JuliaBatch", "status": [], "scale": [], "endpoint": [] }...}`
"""
getAllJobInfo(ctx::Context) = _simple_query(ctx, "/getAllJobInfo/")

"""
Get encoded URL to job port when using router.

Returns:
- The encoded URL as a String
"""
getEncodedURL(ctx::Context, job, port) = _type_name_query(ctx, "/getEncodedURL/", job, Dict("port"=>port))

"""
Fetch current status of a Job.

Parameters:
- job: A JRunClientJob of appropriate type

Returns tuple/array with:
- boolean: whether the job completed
- integer: for a parallel job, number of workers that completed successfully
- integer: for a parallel job, number of workers started
- boolean: whether the job has been created (vs. scheduled)
- boolean: whether this is a notebook (legacy, likely to be removed in future)
"""
getJobStatus(ctx::Context, job::JRunClientJob) = _type_name_query(ctx, "/getJobStatus/", job)

"""
Get the current scale of a job.

Parameters:
- job: A JRunClientJob of appropriate type

Returns tuple/array with:
- integer: number of workers running
- integer: number of workers requested
"""
getJobScale(ctx::Context, job::JRunClientJob) = _type_name_query(ctx, "/getJobScale/", job)

"""
Request to scale the job up or down to the level of parallelism requested.

Parameters:
- job: A JRunClientJob of appropriate type
- parallelism: number of workers to scale to

Returns:
- boolean: true/false indicating success/failure
"""
setJobScale(ctx::Context, job::JRunClientJob, parallelism::Int) = _type_name_query(ctx, "/setJobScale/", job, Dict("parallelism" => string(parallelism)))

"""
Get the endpoint exposed by the job/service.

Parameters:
- job: A JRunClientJob of appropriate type

Returns tuple/array of endpoints as URLs or IP and ports
"""
getJobEndpoint(ctx::Context, job::JRunClientJob) = _type_name_query(ctx, "/getJobEndpoint/", job)

"""
Removes the job entry from the queue.

Parameters:
- job: A JRunClientJob of appropriate type
- force: whether to remove an incomplete job (optional, default: false)

Returns:
- boolean: true/false indicating success/failure
"""
deleteJob(ctx::Context, job::JRunClientJob; force=false) = _type_name_query(ctx, "/deleteJob/", job, Dict("force"=>string(force)))

"""
Tail logs from the job.

Parameters:
- job: A JRunClientJob of appropriate type
- stream: the stream to read from ("stdout"/"stdin"), all streams are read if not specified.
- count: number of log entries to return (50 by default)

Returns a string of log entries separated by new line.
"""
function tailJob(ctx::Context, job::JRunClientJob; stream=nothing, count=50)
    query = Dict("count"=>string(count))
    (stream === nothing) || (query["stream"] = string(stream))
    _type_name_query(ctx, "/tailJob/", job, query)
end

"""
Submit a job definition to execute on the cluster.

Parameters:
- job: A JRunClientJob of appropriate type
- job specific parameters, with names as documented for the JobType constructor

Returns nothing.
"""
function submitJob(ctx::Context, job::JRunClientJob; kwargs...)
    query = Dict{String,String}()
    for (k,v) in kwargs
        query[string(k)] = string(v)
    end
    _type_name_query(ctx, "/submitJob/", job, query)
end

"""
Update a job definition to execute on the cluster.

Parameters:
- job: A JRunClientJob of appropriate type
- job specific parameters, with names as documented for the JobType constructor

Returns nothing.
"""
function updateJob(ctx::Context, job::JRunClientJob; kwargs...)
    query = Dict{String,String}()
    for (k,v) in kwargs
        query[string(k)] = string(v)
    end
    _type_name_query(ctx, "/updateJob/", job, query)
end

"""
Initialize the cluster manager for parallel mode.
"""
function initParallel(; topology=:master_worker)
    if haskey(ENV, "JULIABOX")
        v = "$(VERSION.major).$(VERSION.minor)"
        open(joinpath(ENV["HOME"], ".julia_master_version"), "w") do f
            write(f, v)
        end
    end

    global _JuliaClusterManager
    COOKIE = ENV["JRUN_CLUSTER_COOKIE"]
    if _JuliaClusterManager === nothing
        try
            _JuliaClusterManager = ElasticManager(;addr=IPv4("0.0.0.0"), port=9009, cookie=COOKIE, topology=topology)
        catch ex
            (isa(ex, Base.IOError) && (ex.code == -98)) || rethrow(ex)
            error("Parallel mode is already being used in a different Julia instance")  # "listen: address already in use (EADDRINUSE)"
        end
    else
        @info("Parallel mode was already initialized for this Julia instance")
    end
    _JuliaClusterManager
end


"""
Wait for a certain number of workers to join.
"""
function waitForWorkers(min_workers)
    @info("waiting for $min_workers...")
    t1 = time()
    if min_workers > 0
        while (1 in workers()) || (nworkers() < min_workers)
            sleep(1)
        end
    end
    @info("workers started in $(time()-t1) seconds")
end

macro result(req)
    quote
        _server_exception = nothing
        try
            res = $(esc(req))
            (res["code"] == 0) ? res["data"] : throw(ApiException(res["code"], res["data"], res))
        catch x
            if isa(x, ApiException)
                println(stderr, "Error: ", x.reason)
                isempty(x.resp.data) || println(stderr, "Caused by: ", String(x.resp.data))
            elseif isa(x, Base.IOError)
                println(stderr, "Error: ", x.msg, "(", x.code, ")")
            end
            rethrow(x)
        end
    end
end

# ---------------------------------------------------
# Utility methods
# ---------------------------------------------------
_jobtype(j::T) where {T<:JRunClientJob} = _jobtype(T)
_jobtype(::Type{T}) where {T} = rsplit(string(T), '.'; limit=2)[end]

# assuming PATH_MAX is 256
_isfile(val) = (length(val) < 256) && isfile(val)

function make_query(ctx::Context)
    Dict{String,String}(
        "jruntok" => ctx.token,
        "jrunns" => ctx.namespace
    )
end

function parse_resp(resp)
    (200 <= resp.status <= 206) || throw(ApiException(resp))
    #@info("response " * String(resp.body))
    JSON.parse(String(resp.body))
end

function _http_opts(ctx::Context)
    Dict(
            :retries            => 0,
            :readtimeout        => ctx.readtimeout,
            :connecttimeout     => ctx.connecttimeout,
            :status_exception   => false
        )
end

function _simple_query(ctx, path; q::Dict{String,String}=Dict{String,String}())
    query = merge(make_query(ctx), q)
    url = merge(HTTP.URIs.URI(ctx.root * path); query=query)
    #@info("requesting", ctx.root, path, query, url)
    resp = HTTP.request("GET", url; _http_opts(ctx)...)
    parse_resp(resp)
end

function _type_name_query(ctx::Context, path::String, job::JRunClientJob, query::Dict{String,String}=Dict{String,String}())
    query = merge(make_query(ctx), query)
    query["name"] = job.name
    jt = _jobtype(job)
    url = merge(HTTP.URIs.URI(ctx.root * path * jt * "/"); query=query)
    #@info("requesting", ctx.root, path, jt, query, url)
    resp = HTTP.request("GET", url; _http_opts(ctx)...)
    parse_resp(resp)
end

function initializeCluster(num_workers, ctx=Context())
    initParallel()
    job = self()
    res = setJobScale(ctx, job, num_workers)
    if (res["code"] == 0) && res["data"]
        waitForWorkers(num_workers)
        res = Dict{String,Any}("code"=>0, "data"=>ctx)
    end
    res
end

function releaseCluster(ctx=Context())
    job = self()
    ret = setJobScale(ctx, job, 0)
    while !(1 in workers())
        sleep(1)
    end
    ret
end

include("docs.jl")

end # module
