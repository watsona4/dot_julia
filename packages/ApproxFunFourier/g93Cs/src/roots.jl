
function companion_matrix(c::Vector{T}) where T
    n=length(c)-1

    if n==0
        zeros(T,0,0)
    else
        A=zeros(T,n,n)
        for k=1:n
            A[k,end]=-c[k]/c[end]
        end
        for k=2:n
            A[k,k-1]=one(T)
        end
        A
    end
end


# if isdir(Pkg.dir("AMVW"))
#     using AMVW
#     function complexroots(cfs::Vector)
#         c=chop(cfs,10eps())
#
#         # Only use special routine for large roots
#         if length(c)≥70
#             Main.AMVW.rootsAMVW(c)
#         else
#             hesseneigvals(companion_matrix(c))
#         end
#     end
# else
complexroots(cfs::Vector{T}) where {T<:Union{Float64,ComplexF64}} =
    hesseneigvals(companion_matrix(chop(cfs,10eps())))
# end

function complexroots(cfs::Vector{T}) where T<:Union{BigFloat,Complex{BigFloat}}
    a = Fun(Taylor(Circle(BigFloat)),cfs)
    ap = a'
    rts = Array{Complex{BigFloat}}(complexroots(Vector{ComplexF64}(cfs)))
    # Do 3 Newton steps
    for _ = 1:3
        rts .-= a.(rts)./ap.(rts)
    end
    rts
end

complexroots(neg::Vector, pos::Vector) =
    complexroots([reverse(chop(neg,10eps()), dims=1);pos])
complexroots(f::Fun{Laurent{DD,RR}}) where {DD,RR} =
    mappoint.(Ref(Circle()), Ref(domain(f)),
        complexroots(f.coefficients[2:2:end],f.coefficients[1:2:end]))
complexroots(f::Fun{Taylor{DD,RR}}) where {DD,RR} =
    mappoint.(Ref(Circle()), Ref(domain(f)), complexroots(f.coefficients))



function roots(f::Fun{Laurent{DD,RR}}) where {DD,RR}
    irts=filter!(z->in(z,Circle()),complexroots(Fun(Laurent(Circle()),f.coefficients)))
    if length(irts)==0
        Complex{Float64}[]
    else
        rts=fromcanonical.(f, tocanonical.(Ref(Circle()), irts))
        if isa(domain(f),PeriodicSegment)
            sort!(real(rts))  # Make type safe?
        else
            rts
        end
    end
end


roots(f::Fun{Fourier{D,R}}) where {D,R} = roots(Fun(f,Laurent))