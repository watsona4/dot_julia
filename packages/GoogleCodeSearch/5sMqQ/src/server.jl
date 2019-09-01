function handle_index(ctx::Ctx, req::Dict{String,Any})
    if "path" in keys(req)
        path = req["path"]
        index(ctx, isa(path, Vector) ? index(ctx, convert(Vector{String}, path)) : path)
    end
    true
end

function handle_search(ctx::Ctx, req::Dict{String,Any})
    ("pattern" in keys(req)) ? search(ctx, req["pattern"]; ignorecase=get(req, "ignorecase", false), pathfilter=get(req, "pathfilter", nothing)) : []
end

function read_req(req::HTTP.Request)
    body = HTTP.payload(req)
    isempty(body) ? nothing : JSON.parse(String(body))
end

function prep_router(ctx::Ctx, ops)
    router = HTTP.Router()
    (:index in ops) && HTTP.@register(router, "POST", "/index", (req)->handle_index(ctx,read_req(req)))
    (:search in ops) && HTTP.@register(router, "POST", "/search", (req)->handle_search(ctx,read_req(req)))
    router
end

function run_http(ctx::Ctx; host=ip"0.0.0.0", port=5555, ops=(:index, :search), kwargs...)
    resp_headers = ["Content-Type" => "application/json; charset=utf-8", "Cache-Control" => "no-cache"]
    router = prep_router(ctx, ops)
    HTTP.serve(host, port; kwargs...) do req::HTTP.Request
        resp = try
            (success=true, data=HTTP.handle(router, req))
        catch ex
            @warn("exception processing req", req, ex)
            (success=false, data="unknown error")
        end
        HTTP.Response(200, resp_headers; body=JSON.json(resp), request=req)
    end
end
