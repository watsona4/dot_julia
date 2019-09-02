export iaea_download

import JSON
const IAEA_PHSP_URLS = JSON.parsefile(
    joinpath(@__DIR__, "phsplinks.json"))

function iaea_download_path(dir,name)
    IAEAPath(joinpath(dir, name))
end

function _download(url, path, reload)
    if !ispath(path) || reload
        @info "Downloading $path"
        download(url, path)
    else
        @info "Skip download of existing file $path"
    end
end

function iaea_download(name;
                       dir = nothing,
                       path = nothing,
                      reload=false)
    @argcheck dir == nothing || path == nothing
    @argcheck dir != nothing || path != nothing
    if path == nothing
        path = iaea_download_path(dir, name);
    end
    urls = IAEA_PHSP_URLS[name]
    mkpath(splitdir(path.header)[1])
    mkpath(splitdir(path.phsp)[1])
    _download(urls["header"], path.header, reload)
    _download(urls["phsp"], path.phsp, reload)
    path
end
