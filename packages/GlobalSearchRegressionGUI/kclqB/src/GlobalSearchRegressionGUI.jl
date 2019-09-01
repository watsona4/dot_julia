module GlobalSearchRegressionGUI
using GlobalSearchRegression, HTTP, WebSockets, DataStructures, Mux, JSON, CSV, Pkg, Distributed, UUIDs, Base64

const SERVER_BASE_DIR = "../front/dist"
const INSTALLED_PACKAGES = Pkg.installed()
const GSREG_VERSION = ( haskey(INSTALLED_PACKAGES, "GlobalSearchRegression") ) ? INSTALLED_PACKAGES["GlobalSearchRegression"] : v"1.0.3"


mutable struct GSRegJob
    file # tempfile of data
    hash # hash id of user
    options # options for calculation
    id # unique identifier for this job
    time_enqueued # time enqueued
    time_started
    time_finished
    res::GlobalSearchRegression.GSRegResult # results array
    GSRegJob(file, hash, options) = new(file, hash, options, string(uuid4()), time())
end

"""
    Enqueue the job and notify worker
"""
function enqueue_job(job::GSRegJob)
    global job_queue
    global job_queue_cond
    enqueue!(job_queue, job)
    notify(job_queue_cond)
    job
end

function sendMessage(id, data)
    global connections
    if haskey(connections, string(id))
        ws = connections[id]
        sendMessage(ws, data)
    end
end

function sendMessage(ws::WebSocket, data)
    write(ws, JSON.json(data))
end

function gsreg(job::GSRegJob)
    global jobs_finished
    try
        sendMessage(job.hash, Dict("operation_id" => job.id, "message" => "Reading data"))
        data = CSV.read(job.file)
        sendMessage(job.hash, Dict("operation_id" => job.id, "message" => "Executing GSReg"))

        opt = job.options["options"]
        opt[:parallel] = job.options["paraprocs"]

        job.time_started = time()
        job.res = GlobalSearchRegression.gsreg(job.options["depvar"] * " " * join(job.options["expvars"], " "), data; opt...,
                    onmessage = message -> sendMessage(job.hash, Dict("operation_id" => job.id, "message" => message)) )
        job.time_finished = time()
        push!(jobs_finished, Pair(job.id, job))

        sendMessage(job.hash, Dict("operation_id" => job.id, "done" => true, "message" => "Successful operation", "result" => GlobalSearchRegression.to_dict(job.res)))
    catch e
        io = IOBuffer()
        showerror(io, e)
        sendMessage(job.hash, Dict("operation_id" => job.id, "done" => false, "message" => String(take!(io))))
    end
end

"""
    Log request for analytics and debugging
"""
function logRequest(app, req)
#     log = string(
#         get(req[:headers], "Host", ""), " ",
#         get(req[:headers], "Origin", ""), " ",
#         Libc.strftime("%d/%b/%Y:%H:%M:%S %z", time()), " ",
#         "\"", req[:method], " ", req[:resource], "\"", " ",
#         size(req[:data],1), "B",
#         "\n")
#
#     open(joinpath(dirname(@__FILE__), "..", "access.log"), "a") do fp
#         write(fp, log)
#     end
    app(req)
end

"""
    Try to execute controller and if there is any exception, show exception message
"""
function errorCatch(app, req)
    try
        app(req)
    catch e
        io = IOBuffer()
        showerror(io, e)
        err_text = String(take!(io))
        toJsonWithCors(Dict("message" => err_text, "error" => true), req)
    end
end

"""
    Setting CORS headers and parsing it to JSON
"""
function toJsonWithCors(res, req)
    headers = []

    push!(headers, "Server" => "Julia/$VERSION")
    push!(headers, "Content-Type" => "text/html; charset=utf-8")

    if( req[:method] != "OPTIONS" )
        push!(headers, "Content-Type" => "application/json; charset=utf-8")
    end
    push!(headers, "Access-Control-Allow-Headers" => "X-User-Token, Content-Type")
    push!(headers, "Access-Control-Allow-Origin" => "*")

    Dict(
        :headers => headers,
        :body => codeunits((req[:method] == "OPTIONS") ? "" : JSON.json(res))
    )
end

"""
    Get Auth from header, and reply an error when it's not present
"""
function authHeader(app, req)
    headers = Dict(req[:headers])
    if(haskey(headers, "X-User-Token"))
        req[:token] = get(headers, "X-User-Token", "")
    end
    app(req)
end

function constructCommand(options)
    command = """Pkg.add("GlobalSearchRegression")
using GlobalSearchRegression, CSV
data = CSV.read("yourcsvfile.csv")
res = GlobalSearchRegression.gsreg("", data; opts...)"""
end

"""
    TODO: doc and d better validation, more secure for cloud environments
"""
function validateInput!(opt)
    options = Dict{Symbol,Any}()
    opt_types = Dict(
        "intercept" => Bool,
        "time" => String,
        "residualtest" => Bool,
        "ttest" => Bool,
        "orderresults" => Bool,
        "modelavg" => Bool,
        "outsample" => Int,
        "method" => String,
        "criteria" => Array{Symbol}
    )
    for (name, value) in opt["options"]
        if value != nothing && name == "criteria"
            push!(options, Pair(:criteria, map(Symbol, value)))
        elseif value != nothing && name == "time"
            push!(options, Pair(:time, Symbol(value)))
        elseif value != nothing && name != "csv" && name != "resultscsv"
            push!(options, Pair(Symbol(name), value))
        end
    end
    opt["options"] = options
    opt
end

"""
    Receives base64 encoded data in path with regression
    options and a content body with CSV file for processing

    req[:data] -> Array{UInt8,1}
    req[:params][:b64] -> String
"""
function upload(req)
    """
    Save the file to tmp folder, if there is any exception, it should be returned to the user for
    reuse. It must be available until the user explicit deletes it, or its deleted from
    operating system. If it is deleted, the file must be uploaded again.
    """
    tempfile = try
        temp = tempname()
        write(temp, IOBuffer(req[:data]))
        temp
    catch
        error("We can't save that file, try again later.")
    end

    """
    Check csv parsing & get data
    """
    data = try
        CSV.read(IOBuffer(req[:data]))
    catch
        error("The file must be a valid CSV")
    end

    global files_dict
    id = string(uuid4())
    push!(files_dict, Pair(id, tempfile))

    Dict(
        "filename" => id,
        "datanames" => names(data),
        "nobs" => size(data, 1)
    )
end

function server_info(req)
    global job_queue
    Dict(
        "ncores" => Sys.CPU_THREADS,
        "nworkers" => nworkers(),
        "gsreg_version" => string(GSREG_VERSION),
        "julia_version" => string(VERSION),
        "job_queue" => Dict(
            "length" => length(job_queue)
        )
    )
end

"""
    Enqueue the execution of regressions, expecting a confirmation. If any there is any error, should be a detailed report.
"""
function solve(req)
    """
    Try to get the filename from params
    """
    global files_dict

    if haskey(files_dict, req[:params][:hash])
        tempfile = files_dict[req[:params][:hash]]
        if (!isfile(tempfile))
            error("File was deleted")
        end
    else
        error("Filekey inexistent")
    end

    """
    Input options should be a valid base64:json encoded String.
    """
    options = try
        b64 = convert(String, req[:params][:options])
        JSON.parse(String(base64decode(b64)))
    catch
        error("Bad format in options")
    end

    # validate correct use of options
    validateInput!(options)

    # Enqueue the job
    job = GSRegJob(tempfile, req[:token], options)
    enqueue_job(job)

    Dict(
        "ok" => true,
        "operation_id" => job.id,
        "in_queue" => length(job_queue)
    )
end

function validpath(path; dirs = true)
    return true # fallback index.html will manage this
    (isfile(path) || (dirs && isdir(path))) || isfile(joinpath(path,"index.html"))
end

ormatch(r::RegexMatch, x) = r.match
ormatch(nothing, x) = x

extension(f) = ormatch(match(r"(?<=\.)[^\.\\/]*$", f), "")

mimetypes = Dict{AbstractString,AbstractString}([
    ("jpg", "image/jpeg"),
    ("png", "image/png"),
    ("html", "text/html"),
    ("csv", "text/csv"),
    ("css", "text/css"),
    ("js", "application/javascript"),
    ("ttf", "application/x-font-ttf"),
    ("svg", "image/svg+xml"),
    ("mp4", "video/mp4"),
    ("ico", "image/x-icon"),
    ("map", "text/plain")
])

fileheaders(f) = Dict("Content-Type" => get(mimetypes, extension(f), "application/octet-stream"))

fileresponse(f) = Dict(
                    :body => read(f),
                    :headers => fileheaders(f)
                    )

fresp(f) = isfile(f) ? fileresponse(f) : fileresponse(joinpath(dirname(@__FILE__), SERVER_BASE_DIR,"index.html"))

"""
    operation_id -> csv
"""
function result_file(req)
    global jobs_finished
    id = req[:params][:id]
    if haskey(jobs_finished, id)
        csv = IOBuffer()
        job = jobs_finished[id]
        export_csv(csv, job.res)
        delete!(jobs_finished, id)
        if job.options["csv"] != nothing
            filename = endswith(job.options["csv"], ".csv") ? job.options["csv"] : job.options["csv"] * ".csv"
        else
            filename = "gsreg" * Libc.strftime("%d/%b/%Y%H%M%S", time()) * ".csv"
        end
        Dict(
            :body => String(take!(csv)),
            :headers => Dict("Content-Type" => "application/octet-stream", "Content-Disposition" => "attachment; filename=$filename")
        )
    else
        Dict( :status => 404, :body => "Not found" )
    end
end

files_dict = Dict{String,String}()
jobs_finished = Dict{String,GSRegJob}()

job_queue = Queue{GSRegJob}()

job_queue_cond = Condition()

# Array of connections based in user token
connections = Dict{String,WebSocket}()

noop(app, req) = app(req)

function gui(;openbrowser=true, port=45872, cloud=false, log=false)
    global job_queue_cond
    global job_queue

    #Consume job_queue after notification
    function consume_job_queue()
        while true
            wait(job_queue_cond)
            while !(isempty(job_queue))
#                 try
                    gsreg(dequeue!(job_queue))
#                 catch
#                     println("Error executing gsreg job")
#                 end
            end
        end
    end

    schedule(Task(consume_job_queue))

    @app app = (
        stack(Mux.todict, logRequest, Mux.splitquery, errorCatch, authHeader, Mux.toresponse),
        page("/info", respond("<h1>info</h1>")),
        page("/upload", req -> toJsonWithCors(upload(req), req)),
        page("/server-info", req -> toJsonWithCors(server_info(req), req)),
        page("/result/:id", req -> result_file(req)),
        page("/solve/:hash/:options", req -> toJsonWithCors(solve(req), req)),
        branch( req -> validpath(joinpath(SERVER_BASE_DIR, req[:path]...)), req -> fresp(joinpath(dirname(@__FILE__), SERVER_BASE_DIR, req[:path]...))),
        Mux.notfound
    )

    """
     This WebSocket handler mantain a collection of ws opened with the user id.
    """
    function wshandler(ws)
        global connections
        while isopen(ws)
            msg, = readguarded(ws)
            try
                msg = JSON.parse(String(copy(msg)))
                id = msg["user-token"]
                connections[id] = ws
                sendMessage(ws, Dict("ok" => true, "message" => "Waiting in queue"))
            catch
                sendMessage(ws, Dict("ok" => false, "message" => "The next message must be in JSON format"))
            end
        end
        # TODO: find some way for delete connection with any reference
        # delete!(connections, id)
        # close(ws)
    end

    wsapp = Mux.App(Mux.mux(
        Mux.wdefaults,
        Mux.route("/ws", req -> wshandler(req[:socket])),
        Mux.wclose,
        Mux.notfound(),
    ))

    @async Mux.serve(app, wsapp, port)

    if(openbrowser)
        url = "http://127.0.0.1:" * string(port)
        sleep(3)
        if Sys.iswindows()
            run(`cmd /c start $url`)
        else
            start = ( Sys.isapple() ? "open" : "xdg-open" )
            run(Cmd([start,url]))
        end
    end
end

export gui

end # module GlobalSearchRegressionGUI
