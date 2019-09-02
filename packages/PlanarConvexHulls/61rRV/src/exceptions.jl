struct OrderedStronglyConvexError <: Exception
end

function Base.showerror(io::IO, e::OrderedStronglyConvexError)
    print(io, "Points are not ordered or do not represent a strongly convex set")
end
