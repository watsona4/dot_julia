function FMMtruncation(accuracy, boxSize, k)
    #TODO: use different truncation for different boxes???
    kd = sqrt(2)*boxSize*k
    P2 = ceil(Int, kd + 1.8*accuracy^(2/3)*(kd)^(1/3))
    Q = 2*P2 + 2
    return P2, Q
end

function divideSpace(centers::Array{Float64,2}, options; drawGroups = false)
    size(centers,1) < 2 && error("divideSpace: need at least 2 points")
    # using findfirst everywhere is slower but more robust to floating errors
    (x_min,y_min) = minimum(centers, dims=1)
    (x_max,y_max) = maximum(centers, dims=1)
    epss = eps(maximum(abs.([x_min;x_max;y_min;y_max])))
    x_max += epss
    y_max += epss
    x_min -= epss
    y_min -= epss
    a = options.dx
    nx = options.nx
    if a == 0
        (nx == 0) && error("divideSpace: no parameters given")
        #number of square boxes along x specified
        a = (x_max-x_min)/nx
    else
        #size of square boxes specified
        #recenter x to fit boxes
        nx = findfirst(n -> (a*n)>=(x_max-x_min),
                        1:Int(ceil((x_max-x_min)/a))+1)
        leftover_x = a*nx - (x_max-x_min)
        x_max += 0.5*leftover_x
        x_min -= 0.5*leftover_x
    end
    #recenter y to fit boxes
    ny = findfirst(n-> (a*n)>=(y_max-y_min),
                    1:Int(ceil((y_max-y_min)/a))+1)
    leftover_y = max(a*ny - (y_max-y_min),0.0)
    y_max += 0.5*leftover_y
    y_min -= 0.5*leftover_y
    FMMgroups = Array{FMMgroup}(undef,nx,ny)
    for ix = 1:nx, iy = 1:ny
        center_x = x_min + (ix-0.5)*a
        center_y = y_min + (iy-0.5)*a
        FMMgroups[ix,iy] = FMMgroup([], [center_x center_y])
    end
    for ic = 1:size(centers,1)
        ix = findfirst(n -> ((centers[ic,1] - x_min) <= a*n), 1:nx)
        iy = findfirst(n -> ((centers[ic,2] - y_min) <= a*n), 1:ny)
        push!(FMMgroups[ix,iy], ic)
    end
    #remove empty groups
    flags = Bool[length(FMMgroups[ii].point_ids) > 0 for ii=1:length(FMMgroups)]
    FMMgroups = FMMgroups[flags]

    if drawGroups
        figure()
        for ix = 0:nx
            plot([x_min + ix*a;x_min + ix*a],[y_min;y_max],"k",linewidth=2)
        end
        for iy = 0:ny
            plot([x_min;x_max],[y_min + iy*a;y_min + iy*a],"k",linewidth=2)
        end
        plot(centers[:,1],centers[:,2],"*")
        for ig = 1:length(FMMgroups)
            plot(FMMgroups[ig].center[1],FMMgroups[ig].center[2],"rx")
        end
        xlabel("\$x\$")
        ylabel("\$y\$")
        xlim([x_min - a;x_max + a])
        ylim([y_min - a;y_max + a])
        tight_layout()
        ax = gca()
        ax.set_aspect("equal", adjustable = "box")
    end
    return FMMgroups,a
end

# function FMMaggregationMatrix!(A, k, centers, box_center, t, P)
#     #P is length of first multipole expansion, *not* FMM
#     Q = length(t)
#     d = Array(Float64,2) #silly but faster
#     for i = 1:size(centers,1)
#         d[1] = centers[i,1] - box_center[1]
#         d[2] = centers[i,2] - box_center[2]
#         A[:,(i-1)*(2*P+1) .+ (1:2*P+1)] = [exp(-1.0im*(k*(cos(t[q])*d[1] + sin(t[q])*d[2])
#             + n*(pi/2-t[q]))) for q=1:Q, n=-P:P]
#     end
# end

function FMMaggregationMatrix(k, centers, box_center, t, P)
    #P is length of first multipole expansion, *not* FMM
    Q = length(t)
    Ns = size(centers,1)
    A = Array{Complex{Float64}}(undef, Q, Ns*(2*P+1))
    d = Array{Float64}(undef, 2) #silly but faster
    for i = 1:Ns
        d[1] = centers[i,1] - box_center[1]
        d[2] = centers[i,2] - box_center[2]
        A[:,(i-1)*(2*P+1) .+ (1:2*P+1)] = [exp(-1.0im*(k*(cos(t[q])*d[1] + sin(t[q])*d[2])
            + n*(pi/2-t[q]))) for q=1:Q, n=-P:P]
    end
    return A
end

# function FMMtranslationMatrix!(T, k, x, t, P2)
#     #x = c1-c2, where c2 is the source and c1 the destination
#     Q = length(t)
#     nx = sqrt(sum(abs2,x))
#     tx = Float64[atan2(x[2],x[1]) + pi/2 - t[q] for q=1:Q]
#     bess = besselh.(-P2:P2, 1, k*nx)
#     T[:] = 0
#     for i = -P2:P2
#         T[:] += bess[i+P2+1]*exp(1.0im*i*tx)/Q
#     end
# end

function FMMtranslationMatrix(k, x, t, P2)
    #x = c1-c2, where c2 is the source and c1 the destination
    Q = length(t)
    T = zeros(Complex{Float64},Q)
    nx = sqrt(sum(abs2,x))
    tx = Float64[-atan(-x[2],-x[1]) - pi/2 + t[q] for q=1:Q]
    bess = besselh.(-P2:P2, 1, k*nx)
    T[:] .= 0
    for i = -P2:P2, j = 1:Q
        T[j] += bess[i+P2+1]*exp(1.0im*i*tx[j])/Q
    end
    return T
end

function FMMnearMatrix(k, P, groups, centers, boxSize, num)
    #for now, does not include self interactions - but does include minus sign
    Ns = size(centers,1)
    G = length(groups)
    W = 2*P+1
    Is = Array{Int}(undef, num*W^2)
    Js = Array{Int}(undef, num*W^2)
    Zs = Array{Complex{Float64}}(undef, num*W^2)
    bess = Array{Complex{Float64}}(undef, 2*P+1)
    mindist2 = 3*boxSize^2 #anywhere between 2 and 4
    ind = 0
    for ig1 = 1:G
        for ig2 = 1:G
            x = groups[ig1].center - groups[ig2].center
            sum(abs2,x) > mindist2 && continue
            #for each enclosed scatterer, build translation matrix
            for ic1 = 1:length(groups[ig1].point_ids)
                for ic2 = 1:length(groups[ig2].point_ids)
                    ig1 == ig2 && (ic1 == ic2 && continue) #no  self-interactions
                    d = centers[groups[ig1].point_ids[ic1],:] - centers[groups[ig2].point_ids[ic2],:]
                    nd = sqrt(sum(abs2,d))
                	td = atan(d[2],d[1])
                    bess[:] = besselh.(0:2*P,1,k*nd)
                	for ix = 1:2*P #lower diagonals
                		rng = ix+1:1+W:W^2-W*ix
                		Zs[ind .+ rng] .= -exp(-1im*td*ix)*(-1)^(ix)*bess[ix+1]
                	end
                	for ix = 0:2*P #central and upper diagonals
                		rng = ix*W+1:1+W:W^2-ix
                		Zs[ind .+ rng] .= -exp(1im*td*ix)*bess[ix+1]
                	end
                    for ij = 1:W
                        Is[ind .+ (1:W)] = collect((groups[ig1].point_ids[ic1]-1)*W .+ (1:W))
                        Js[ind .+ (1:W)] .= (groups[ig2].point_ids[ic2]-1)*W + ij
                        ind += W
                    end
                end
            end
        end
    end
    return sparse(Is,Js,Zs,Ns*W,Ns*W)
end

function FMMnearMatrix_upperTri(k, P, groups, centers, boxSize, num)
    #half the bessels here are re-used, since hankel part is symmetric between a->b and b->a
    #for now, does not include self interactions - but does minus sign
    Ns = size(centers,1)
    G = length(groups)
    W = 2*P+1
    Is = Array{Int}(undef, num*W^2)
    Js = Array{Int}(undef, num*W^2)
    Zs = Array{Complex{Float64}}(undef, num*W^2)
    mindist2 = 3*boxSize^2 #anywhere between 2 and 4
    ind = 0
    d = Array{Float64}(undef, 2)
    bess = Array{Complex{Float64}}(undef, 2*P+1)
    #first, between group and itself
    for ig1 = 1:G
        for ic1 = 1:length(groups[ig1].point_ids)
            for ic2 = ic1+1:length(groups[ig1].point_ids)
                d[1] = centers[groups[ig1].point_ids[ic1],1] - centers[groups[ig1].point_ids[ic2],1]
                d[2] = centers[groups[ig1].point_ids[ic1],2] - centers[groups[ig1].point_ids[ic2],2]
                nd = sqrt(sum(abs2,d))
                #first for ic2->ic1, then ic1->ic2
                td1 = atan(d[2],d[1])
                td2 = atan(-d[2],-d[1]) #adding pi instead leads to error
                bess[:] = besselh.(0:2*P,1,k*nd)
                ind2 = ind + W^2

                for ix = 1:2*P #lower diagonals
                    rng = ix+1:1+W:W^2-W*ix
                    Zs[ind .+ rng] .= -exp(-1.0im*td1*ix)*(-1)^(ix)*bess[ix+1]
                    Zs[ind2 .+ rng] .= -exp(-1.0im*td2*ix)*(-1)^(ix)*bess[ix+1]
                end
                for ix = 0:2*P #central and upper diagonals
                    rng = ix*W+1:1+W:W^2-ix
                    Zs[ind .+ rng] .= -exp(1.0im*td1*ix)*bess[ix+1]
                    Zs[ind2 .+ rng] .= -exp(1.0im*td2*ix)*bess[ix+1]
                end
                #this way we avoid allocating vectors
                for ij = 1:W
                    rng = (1:W) .+ (ij-1)*W
                    Js[ind .+ rng] .= (groups[ig1].point_ids[ic2]-1)*W + ij
                    Js[ind2 .+ rng] .= (groups[ig1].point_ids[ic1]-1)*W + ij
                end
                for ij = 1:W
                    rng = (1:W:W^2-W+1) .+ (ij-1)
                    Is[ind .+ rng] .= (groups[ig1].point_ids[ic1]-1)*W + ij
                    Is[ind2 .+ rng] .= (groups[ig1].point_ids[ic2]-1)*W + ij
                end
                ind += 2*W^2 #skip over ind2 data
            end
        end
    end
    #now, between groups
    for ig1 = 1:G
        for ig2 = ig1+1:G
            x = groups[ig1].center - groups[ig2].center
            sum(abs2,x) > mindist2 && continue
            #for each enclosed scatterer, build translation matrix
            for ic1 = 1:length(groups[ig1].point_ids)
                for ic2 = 1:length(groups[ig2].point_ids)
                    d[1] = centers[groups[ig1].point_ids[ic1],1] - centers[groups[ig2].point_ids[ic2],1]
                    d[2] = centers[groups[ig1].point_ids[ic1],2] - centers[groups[ig2].point_ids[ic2],2]
                    nd = sqrt(sum(abs2,d))
                	#first for ig2->ig1, then ig1->ig2
                    td1 = atan(d[2],d[1])
                    td2 = atan(-d[2],-d[1]) #adding pi instead leads to error
                    bess[:] = besselh.(0:2*P,1,k*nd)
                    ind2 = ind + W^2

                    for ix = 1:2*P #lower diagonals
                		rng = ix+1:1+W:W^2-W*ix
                		Zs[ind .+ rng] .= -exp(-1.0im*td1*ix)*(-1)^(ix)*bess[ix+1]
                        Zs[ind2 .+ rng] .= -exp(-1.0im*td2*ix)*(-1)^(ix)*bess[ix+1]
                	end
                	for ix = 0:2*P #central and upper diagonals
                		rng = ix*W+1:1+W:W^2-ix
                		Zs[ind .+ rng] .= -exp(1.0im*td1*ix)*bess[ix+1]
                        Zs[ind2 .+ rng] .= -exp(1.0im*td2*ix)*bess[ix+1]
                	end
                    #this way we avoid allocating vectors
                    for ij = 1:W
                        rng = (1:W) .+ (ij-1)*W
                        Js[ind .+ rng] .= (groups[ig2].point_ids[ic2]-1)*W + ij
                        Js[ind2 .+ rng] .= (groups[ig1].point_ids[ic1]-1)*W + ij
                    end
                    for ij = 1:W
                        rng = (1:W:W^2-W+1) .+ (ij-1)
                        Is[ind .+ rng] .= (groups[ig1].point_ids[ic1]-1)*W + ij
                        Is[ind2 .+ rng] .= (groups[ig2].point_ids[ic2]-1)*W + ij
                    end
                    ind += 2*W^2 #skip over ind2 data
                end
            end
        end
    end
    return sparse(Is,Js,Zs,Ns*W,Ns*W)
end

#TODO: distinguish between symmetric and non-symmetric.
function FMMbuildMatrices(k, P, P2, Q, groups, centers, boxSize; tri = true)
    G = length(groups)
    t = Float64[2*pi*j/Q for j=0:(Q-1)]
    Agg = Array{Complex{Float64},2}[]
    for ig = 1:G #preallocate here? not sure what is faster in practice
        A = FMMaggregationMatrix(k, centers[groups[ig].point_ids,:], groups[ig].center, t, P)
        push!(Agg, A)
    end
    Disagg = [Agg[ii]' for ii=1:G]
    #Array of arrays for Trans, or dict, or something else???
    Trans = Vector{Complex{Float64}}[]
    #For now, the translation from j to i is at Trans[(i-1)*G + j]
    mindist2 = 3*boxSize^2 #anywhere between 2 and 4
    d = Array{Float64}(undef, 2)
    num = 0
    for ig1 = 1:G
        for ig2 = 1:G
            if ig1 == ig2
                push!(Trans,[])
                #number of near interactions inside a group is their product minus self-interactions
                num += length(groups[ig1].point_ids)*(length(groups[ig1].point_ids)-1)
                continue
            end
            d[1] = groups[ig1].center[1] - groups[ig2].center[1]
            d[2] = groups[ig1].center[2] - groups[ig2].center[2]
            if sum(abs2,d) <= mindist2
                push!(Trans,[])
                #number of near interactions between two close (but not identical) groups is their product
                num += length(groups[ig1].point_ids)*length(groups[ig2].point_ids)
            else
                #preallocate here???
                Trans1_2 = FMMtranslationMatrix(k, d, t, P2)
                push!(Trans,Trans1_2)
            end
        end
    end
    if tri
        Znear = FMMnearMatrix_upperTri(k, P, groups, centers, boxSize, num)
    else
        Znear = FMMnearMatrix(k, P, groups, centers, boxSize, num)
    end

    FMMmatrices(Agg, Trans, Disagg, Znear, groups, P2, Q)
end
