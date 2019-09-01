module Sys

export cleardir, memory

"""
clear a floder
"""
function cleardir(dir::AbstractString)
    for fname in readdir(dir)
        rm(joinpath(dir, fname), recursive=true)
    end
end

end # end of module
