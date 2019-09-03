module SalesForceBulkApi

# pre requirements
## Other packages
using HTTP, LightXML, CSV, ProgressMeter, DataFrames, Distributed
import JSON

export login, sf_bulkapi_query, all_object_fields, fields_description, object_list, multiquery
 
# login
## login function and session token gathering
function login_post(username, password, version)
    xml = """<?xml version="1.0" encoding="utf-8" ?>                       
    <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">                     
        <env:Body>                     
            <n1:login xmlns:n1="urn:partner.soap.sforce.com">
                <username>$(username)</username>
                <password>$(password)</password>
            </n1:login>
        </env:Body>
    </env:Envelope>"""
    HTTP.request("POST", "https://login.salesforce.com/services/Soap/u/$(version)",
            ["Content-Type" => "text/xml",
            "SOAPAction" => "login"],
            xml)
end

function login_base(username::String, password::String, version::String = "35.0")
    session_info=login_post(username, password, version) 
    status = session_info.status;
    http_status_exception_hand(status)
    body = String(session_info.body)
    if status == 200 
        return child_elem(body)
    else
        return status
    end
end

function login(username::String, password::String, version::String = "35.0", tries::Int = 10)
    current = 1
    while current <= tries
        try 
            session = login_base(username, password, version);
            return  session
        catch
            current += 1
            @warn "Not successfull. Starting try $current of $tries"
        end
    end
end

# Bulk api functions
## create work
function jobcreater(session, object, queryall = false)
    apiVersion = match(r"/[0-9\.]{2,}/", session["serverUrl"]).match[2:end-1]
    url1 = match(r".{0,}\.com", session["serverUrl"]).match
    if queryall == true
        xml = """<?xml version="1.0" encoding="utf-8" ?>                       
        <jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
            <operation>queryAll</operation>
            <object>$(object)</object>
            <concurrencyMode>Parallel</concurrencyMode>
            <contentType>CSV</contentType>
        </jobInfo>"""
    else
        xml = """<?xml version="1.0" encoding="utf-8" ?>                       
        <jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
            <operation>query</operation>
            <object>$(object)</object>
            <concurrencyMode>Parallel</concurrencyMode>
            <contentType>CSV</contentType>
        </jobInfo>"""
    end
    job = HTTP.request("POST", url1 * "/services/async/" * apiVersion * "/job",
                ["Content-Type" => "text/plain",
                "X-SFDC-Session" => session["sessionId"]],
                xml)

    status = job.status;
    http_status_exception_hand(status)
    body = String(job.body)
    job = child_elem(body)
    println("Job: " * job["id"])
    println("Status: " * job["state"])
    return job
end

## create query
function queryposter(session, job, query)
    jobid = job["id"]
    apiVersion = match(r"/[0-9\.]{2,}/", session["serverUrl"]).match[2:end-1]
    url1 = match(r".{0,}\.com", session["serverUrl"]).match
    ret = HTTP.request("POST", url1 * "/services/async/" * apiVersion * "/job/" * jobid * "/batch",
                ["Content-Type" => "text/csv",
                "X-SFDC-Session" => session["sessionId"]],
                query)
    status = ret.status;
    http_status_exception_hand(status)
    body = String(ret.body)
    query = child_elem(body)
    println("Job: " * query["id"])
    println("Status: " * query["state"])
    return query
end

## check status
function batchstatus(session, query; printing = true, tries = 10)
    apiVersion = match(r"/[0-9\.]{2,}/", session["serverUrl"]).match[2:end-1]
    url1 = match(r".{0,}\.com", session["serverUrl"]).match
    jobid = query["jobId"]
    batchid = query["id"]
    ret = []
    while tries > 0
        try 
            ret = HTTP.request("GET", url1 * "/services/async/" * apiVersion * "/job/" * jobid * "/batch/" * batchid,
                ["Content-Type" => "text/plain",
                "X-SFDC-Session" => session["sessionId"]])
            tries = 0
        catch
            tries -= 1
            @warn "Batchstatus: Not successfull. Tries left $tries"
        end
    end
    status = ret.status;
    http_status_exception_hand(status)
    body = String(ret.body)
    batch = child_elem(body)
    if batch["state"] == "Failed"
        println("Batch: " * batch["id"])
        error("Status: " * batch["stateMessage"])
    elseif printing == true
        println("Batch: " * batch["id"])
        println("Status: " * batch["state"])
    end
    return batch
end

## fetch results
function resultsid(session, batch)
    apiVersion = match(r"/[0-9\.]{2,}/", session["serverUrl"]).match[2:end-1]
    url1 = match(r".{0,}\.com", session["serverUrl"]).match
    jobid = batch["jobId"]
    batchid = batch["id"]
    
    ret = HTTP.request("GET", url1 * "/services/async/" * apiVersion * "/job/" * jobid * "/batch/" * batchid * "/result",
                ["Content-Type" => "text/plain",
                "X-SFDC-Session" => session["sessionId"]])
    status = ret.status;
    http_status_exception_hand(status)
    body = String(ret.body)
    results = Dict{String,String}()
    for (i,x) in enumerate(child_elements(LightXML.root(parse_string(body))))
        name_v, value = split(string(x), r"<|>")[2:3]
        merge!(results, Dict([name_v*string(i) => value]))
    end
    return results
end

function results(session, batch)
    apiVersion = match(r"/[0-9\.]{2,}/", session["serverUrl"]).match[2:end-1]
    url1 = match(r".{0,}\.com", session["serverUrl"]).match
    jobid = batch["jobId"]
    batchid = batch["id"]
    resultids = collect(values(resultsid(session,batch)))
    body = DataFrame()
    for resultid in resultids
        ret = HTTP.request("GET", url1 * "/services/async/" * apiVersion * "/job/" * jobid * "/batch/" * batchid * "/result/" * resultid,
                ["Content-Type" => "text/plain",
                "X-SFDC-Session" => session["sessionId"]])
        status = ret.status;
        http_status_exception_hand(status)
        if size(body) == (0, 0)
            body = mapcols(x -> replace(x, "" => missing), CSV.read(IOBuffer(String(ret.body)), missingstring = ""))
        else 
            body = vcat(body, mapcols(x -> replace(x, "" => missing), CSV.read(IOBuffer(String(ret.body)), missingstring = "")))
        end
    end
    return body
end

## close worker
function jobcloser(session, job)
    apiVersion = match(r"/[0-9\.]{2,}/", session["serverUrl"]).match[2:end-1]
    url1 = match(r".{0,}\.com", session["serverUrl"]).match
    jobid = job["id"]

    xml = """<?xml version="1.0" encoding="utf-8" ?>                       
    <jobInfo xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <state>Closed</state>
    </jobInfo>"""
    ret = HTTP.request("POST", url1 * "/services/async/" * apiVersion * "/job/" * jobid,
                ["Content-Type" => "text/plain",
                "X-SFDC-Session" => session["sessionId"]],
                xml)
    
    status = ret.status;
    http_status_exception_hand(status)
    body = String(ret.body)
    job = child_elem(body)
    println("Job: " * job["id"])
    println("Status: " * job["state"])
    return job
end

# Wrapper
# wrapper function for single task

function sf_bulkapi_query(session, query::String, queryall = false)
    query = lowercase(query)
    objects = [x.match for x in eachmatch(r"(?<=from\s)(\w+)",query)]
    length(objects) > 1 ? error("Query string include multiple objects. Should only have 1 FROM * statement") : nothing
    objects = objects[1]
    job = jobcreater(session, objects, queryall);
    try
        query = queryposter(session, job, query);
        batch = batchstatus(session, query, printing=true);
        if batch["state"] == "Failed"
            error("Status: " * batch["stateMessage"])
        else
            while batch["state"] != "Completed"
                sleep(3)
                batch = batchstatus(session, query, printing=false);
            end
            if batch["state"] == "Completed"
                res = results(session, batch)
            end
            return res
        end
    catch
        return DataFrame()
    finally
        jobcloser(session, job)
    end
end

# Functions for multiple queries
function startworker(session, joblist::RemoteChannel{Channel{String}}, res::RemoteChannel{Channel{Dict}}, queries, queryall = false)
    function do_worker(session, joblist::RemoteChannel{Channel{String}}, res::RemoteChannel{Channel{Dict}}, queryall = false)
        running = true
        while running
            try
                query = take!(joblist)
                result = sf_bulkapi_query(session, query, queryall)
                put!(res, Dict([(query,result)]))
            catch berror
                if isa(berror, InvalidStateException)
                    running = false
                elseif isa(berror, RemoteException)
                    running = false
                else
                    running = false
                    println(berror)
                end
            end
        end
    end
    for p in workers()
        remote_do(do_worker, p, session, joblist, res, queryall)
    end
end;

function startworker(session, joblist::Channel{String}, res::Channel{Dict}, queries, queryall = false)
    function create_worker(session, res::Channel{Dict}, queryall = false)
        query = take!(joblist)
        println("Job taken")
        put!(res, Dict([(query,sf_bulkapi_query(session, query, queryall))]))
    end
    for i in queries
        @async create_worker(session, res, queryall)
    end
end;

function create_joblist(queries::Array{String}, joblist)
    for i in queries
        put!(joblist, i)
    end
    close(joblist)
end;

function result_collector(queries, res)
    totalres=Dict()
    while isopen(res)
        resa = take!(res)
        merge!(totalres, resa)
        if length(totalres) >= size(queries, 1)
            close(res)
        end
    end
    return totalres
end;

function multiquery(session, queries, queryall = false)
    if length(workers()) > 1
        res = RemoteChannel(()->Channel{Dict}(size(queries,1)));
        joblist = RemoteChannel(()->Channel{String}(size(queries,1)));
    else
        res = Channel{Dict}(size(queries,1));
        joblist = Channel{String}(size(queries,1));
    end
    println("Setup done")
    println("Create Jobs")
    create_joblist(queries, joblist)
    println("Start worker")
    @async startworker(session, joblist, res, queries, queryall)
    ret = result_collector(queries, res)
    println("Results collected")
    return ret
end

# Helper functions
## All Tables
function object_list(session)
    apiVersion = match(r"/[0-9\.]{2,}/", session["serverUrl"]).match[2:end-1]
    url1 = match(r".{0,}\.com", session["serverUrl"]).match
    ret = HTTP.request("GET", url1 * "/services/data/v" * apiVersion * "/sobjects",
                ["Content-Type" => "text/plain",
                "Authorization" => "Bearer " * session["sessionId"],
                "Accept" => "application/json"])
    body = JSON.parse(String(ret.body));
    objects = [x["name"] for x in body["sobjects"]]
    return objects
end
## Field per Table
function fields_description(session, object::String)
    apiVersion = match(r"/[0-9\.]{2,}/", session["serverUrl"]).match[2:end-1]
    url1 = match(r".{0,}\.com", session["serverUrl"]).match
    ret = HTTP.request("GET", url1 * "/services/data/v" * apiVersion * "/sobjects/" * object * "/describe",
                ["Content-Type" => "text/plain",
                "Authorization" => "Bearer " * session["sessionId"],
                "Accept" => "application/json"])

    body = JSON.parse(String(ret.body));
    ret = field_extractor(body["fields"], object)
    return ret
end

## All Field in a Table
function fields_description(session, object::Array)
    p = Progress(size(object,1), dt=1, barglyphs=BarGlyphs("[=> ]"), barlen=10, color=:green)
    ret = fields_description(session, object[1])
    next!(p)    
    for x in object[2:end]
        append!(ret, fields_description(session,x))
        next!(p)
    end
    return ret
end

## All fields + all tables
function all_object_fields(session)
    objects = object_list(session)
    ret = fields_description(session, objects)
    return ret
end


## XML functions
function child_elem(x)
    x = LightXML.root(parse_string(x))
    res = Dict{String,String}()    
    child_elem(x, res)
end

function child_elem(x, res)    
    if size(collect(child_elements(x)),1) > 0
        for x in child_elements(x)
            name_v, value = split(string(x), r"<|>")[2:3]
            merge!(res, Dict([name_v => value]))
            child_elem(x, res)
        end
    end
    return(res)
end

## Return stat behaviour
function http_status_exception_hand(x)
    if x >= 300 | x < 200
        @error "HTTP code $x"
    end
end

#Extracts all fields from a dict into columns of a DataFrame and appends the object name for reference
function field_extractor(x, object::String)
    ret = []
    for (i, x) in enumerate(x)
        if i == 1
            ret = DataFrame(reshape([x for x in values(x)],1,:), Symbol.(keys(x)))
        else
            append!(ret,DataFrame(reshape([x for x in values(x)],1,:), Symbol.(keys(x))))
        end
    end
    ret[!,:object] .= object
    return ret
end

end