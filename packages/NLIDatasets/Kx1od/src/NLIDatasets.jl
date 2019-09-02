module NLIDatasets

using DataDeps, HTTP

function downloadzip(url, file)
    headers = ["User-Agent" => "NLIDatasets.jl",
               "Accept" => "*/*",
               "Accept-Encoding" => "gzip, deflate, br"]
    HTTP.download(url, file, headers)
end

register_data(name, description, url, sha; fetch_method = downloadzip, post_fetch_method = unpack) =
    DataDeps.register(DataDep(name, description, url, sha; fetch_method = fetch_method, post_fetch_method = post_fetch_method))

include("snli.jl")
include("multinli.jl")
include("xnli.jl")
include("scitail.jl")
include("hans.jl")
include("breaking_nli.jl")

using .SNLI, .MultiNLI, .XNLI, .SciTail, .HANS, .BreakingNLI

end # module
