struct ReverseCompoundPeriod <: AbstractTime
   cperiod::CompoundPeriod
end

reverse(x::CompoundPeriod) = ReverseCompoundPeriod(x)
reverse(x::ReverseCompoundPeriod) = x.cperiod
reverse(x::Period) = reverse(CompoundPeriod(x))

function string(rperiod::ReverseCompoundPeriod)
    join(([string(aperiod) for aperiod in rperiod]...,),", ")
end

function show(io::IO, x::ReverseCompoundPeriod)
   print(io, string(x))
end

const StdOut = isdefined(Base, :stdout) ? Base.stdout : Base.STDOUT

function show(x::ReverseCompoundPeriod)
    print(StdOut, string(x))
end      
