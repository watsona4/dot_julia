                
function zip7(file)
        to = dirname(file)
        dest = joinpath(to, string(basename(file), ".7z"))
        try
                cmd = "7z a -y -t7z -- $(dest) $(file)"
                run(pipeline(ifelse(Sys.iswindows(), `cmd /c $cmd`, `sh -c $cmd`); stdout=joinpath(to, "7zip.log")))
        catch e
                rm(dest; force=true)
                throw(e)
        end
        return dest
end

function unzip7(file)
        to = dirname(file)
        source = joinpath(dirname(file), basename(file)[1:end-3])
        try
                cmd = "7z e -y -o$(to) $(file)"
                run(pipeline(ifelse(Sys.iswindows(), `cmd /c $cmd`, `sh -c $cmd`); stdout=joinpath(to, "7zip.log")))
        catch e
                rm(source; force=true)
                throw(e)
        end
        return source
end
