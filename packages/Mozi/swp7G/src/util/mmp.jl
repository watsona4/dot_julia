import Mmap

function write_vector(path,filename,head,data)
    open(joinpath(path,filename), "w+") do s
        write(s, head)
        write(s, length(data))
        write(s, data)
    end
end

function read_vector(path,filename)
    A=Nothing
    open(joinpath(path,filename)) do s  # default is read-only
        head=read(s,Int)
        m = read(s, Int)
        A = Mmap.mmap(s, Vector{Float64}, m)
    end
    return A
end

function write_matrix(path,filename,head,data)
    open(joinpath(path,filename), "w+") do s
        write(s, head)
        write(s, size(data,1))
        write(s, size(data,2))
        write(s, data)
    end
end

function read_matrix(path,filename)
    A=Nothing
    open(joinpath(path,filename)) do s  # default is read-only
        head=read(s,Int)
        m = read(s, Int)
        n = read(s, Int)
        A = Mmap.mmap(s, Matrix{Float64}, (m,n))
    end
    return A
end
