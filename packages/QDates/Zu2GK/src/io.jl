# io.jl

function Base.string(qdt::QDate)
    y, m, l, d = yearmonthleapday(qdt)
    yy = lpad(y, 4, "0")
    mm = lpad(m, 2, "0")
    dd = lpad(d, 2, "0")
    return l ? "旧$(yy)年閏$(mm)月$(dd)日" : "旧$(yy)年$(mm)月$(dd)日"
end
Base.show(io::IO, qdt::QDate) = print(io, string(qdt))
