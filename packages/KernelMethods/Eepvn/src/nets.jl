# Copyright 2017 Jose Ortiz-Bejar 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Nets
export Net, enet, kmnet, dnet, gen_features, KernelClassifier
import KernelMethods.Kernels: sigmoid, gaussian, linear, cauchy
import KernelMethods.Scores: accuracy, recall
import KernelMethods.Supervised: NearNeighborClassifier, NaiveBayesClassifier, optimize!, predict_one, predict_one_proba, LabelEncoder, transform, inverse_transform
using SimilaritySearch: KnnResult, L2Distance, L2SquaredDistance, CosineDistance, DenseCosine, JaccardDistance
using TextModel
using PyCall

@pyimport sklearn.naive_bayes as nb
@pyimport sklearn.model_selection as ms

#using JSON
#using DataStructures

mutable struct Net{ItemType,LabelType}
    data::Vector{ItemType}
    labels::Vector{Int}
    le::LabelEncoder{LabelType}
    references::Vector{Int32}
    partitions::Vector{Int32}
    centers::Vector{ItemType}
    centroids::Vector{ItemType}
    dists::Vector{Float64}
    csigmas::Vector{Float64}
    sigmas::Dict{Int,Float64}
    stats::Dict{LabelType,Float64}
    reftype::Symbol
    distance
    kernel
end

function Net(data::Vector{ItemType},labels::Vector{LabelType}) where {ItemType, LabelType}
    le = LabelEncoder(labels)
    y = transform.(le, labels)
  
    Net(data,y,le,
        Int32[],Int32[],ItemType[],
        ItemType[],Float64[],Float64[],
        Dict{Int,Float64}(), Dict{LabelType,Float64}(),:centroids,L2SquaredDistance(),gaussian)
end

function cosine(x1,x2)::Float64
    xc1=DenseCosine(x1)
    xc2=DenseCosine(x2)
    d=CosineDistance()
    return d(xc1,xc2)
end

function maxmin(data,centers,ind,index::KnnResult,distance,partitions)::Tuple{Int64,Float64}
    c=last(centers)
    if length(index)==0
        for i in ind
            if i!=c
                push!(index,i,Inf)
            end
        end
    end
    nindex=KnnResult(length(index))
    for fn in index
        dist=distance(data[fn.objID],data[c])
        #push!(lK[fn.objID],dist)
        dist = if (dist<fn.dist) dist else fn.dist end
        partitions[fn.objID] = if (dist<fn.dist) c else partitions[fn.objID] end
        if fn.objID!=c
            push!(nindex,fn.objID,dist)
        end
    end
    index.k=nindex.k
    index.pool=nindex.pool
    fn=pop!(index)
    return fn.objID,fn.dist
end

function get_centroids(data::Vector{T}, partitions::Vector{Int})::Vector{T} where T
    centers=[j for j in Set(partitions)]
    sort!(centers)
    centroids=Vector{T}(length(centers))
    for (ic,c) in enumerate(centers)
        ind=[i for (i,v) in enumerate(partitions) if v==c]
        centroids[ic]=mean(data[ind])
    end
    return centroids
end

# Epsilon Network using farthest first traversal Algorithm

function enet(N::Net,num_of_centers::Int; distance=L2SquaredDistance(), 
              per_class=false,reftype=:centroids, kernel=linear)
    N.distance=distance
    N.kernel=kernel
    n=length(N.data)
    partitions=[0 for i in 1:n]
    gcenters,dists,sigmas=Vector{Int}(0),Vector{Float64}(num_of_centers-1),Dict{Int,Float64}()
    indices=[[i for i in  1:n]]
    for ind in indices
        centers=Vector{Int}(0)
        s=rand(1:length(ind))
        push!(centers,ind[s])
        #ll=N.labels[ind[s]]
        index=KnnResult(length(ind))
        partitions[ind[s]]=ind[s]
        k=1
        while  k<=num_of_centers-1 && k<=length(ind)
            fnid,d=maxmin(N.data,centers,ind,index,distance,partitions)
            push!(centers,fnid)
            dists[k]=d
            partitions[fnid]=fnid
            k+=1
        end
        sigmas[0]=minimum(dists)
        gcenters=vcat(gcenters,centers)
    end
    N.references,N.partitions,N.dists,N.sigmas=gcenters,partitions,dists,sigmas
    N.centers,N.centroids=N.data[gcenters],get_centroids(N.data,partitions)
    N.csigmas,N.stats=get_csigmas(N.data,N.centroids,N.partitions,distance=N.distance)
    N.reftype=reftype
end


# KMeans ++ seeding Algorithm 

function kmpp(N::Net,num_of_centers::Int)::Vector{Int}
    n=length(N.data)
    s=rand(1:n)
    centers, d = Vector{Int}(num_of_centers), L2SquaredDistance()
    centers[1]=s
    D=[d(N.data[j],N.data[s]) for j in 1:n]
    for i in 1:num_of_centers-1
        cp=cumsum(D/sum(D))
        r=rand()
        sl=[j for j in 1:length(cp) if cp[j]>=r]
        s=sl[1]
        centers[i+1]=s
        for j in 1:n
            dist=d(N.data[j],N.data[s])
            if dist<D[j]
                D[j]=dist
            end
        end
    end
    centers
end

#Assign Elementes to thier nearest centroid

function assign(data,centroids,partitions;distance=L2SquaredDistance())
    d=distance
    for i in 1:length(data)
        partitions[i]=sortperm([d(data[i],c) for c in centroids])[1]
    end
end

#Distances for each element to its nearest cluster centroid

function get_distances(data,centroids,partitions;distance=L2SquaredDistance())::Vector{Float64}
    dists=Vector{Float64}(length(centroids))
    for i in 1:length(centroids)
        ind=[j for (j,l) in enumerate(partitions) if l==i]
        if length(ind)>0
            X=data[ind]
            dd=[distance(centroids[i],x) for x in X]
            dists[i]=maximum(dd)
        end
    end
    sort!(dists)
    return dists
end

#Calculated the sigma for each ball

function get_csigmas(data,centroids,partitions;distance=L2SquaredDistance())::Tuple{Vector{Float64},Dict{String,Float64}}
    stats=Dict("SSE"=>0.0,"BSS"=>0.0)
    refs=[j for j in Set(partitions)]
    sort!(refs)
    csigmas=Vector{Float64}(length(refs))
    df=distance
    m=mean(data)
    for (ii,i) in enumerate(refs)
        ind=[j for (j,l) in enumerate(partitions) if l==i]
        #if length(ind)>0
        X=data[ind]
        dd=[df(data[i],x) for x in X]
        csigmas[ii]=max(0,maximum(dd))
        stats["SSE"]+=sum(dd)
        stats["BSS"]+=length(X)*(sum(mean(X)-m))^2
        #end
    end
    return csigmas,stats
end

#Feature generator using kmeans centroids

function kmnet(N::Net,num_of_centers::Int; max_iter=1000,kernel=linear,distance=L2SquaredDistance(),reftype=:centroids)
    n=length(N.data)
    #lK,partitions=[[] for i in 1:n],[0 for i in 1:n],[0 for i in 1:n]
    partitions=[0 for i in 1:n]
    dists=Vector{Float64}
    init=kmpp(N,num_of_centers)
    centroids=N.data[init]
    i,aux=1,Vector{Float64}(length(centroids))
    while centroids != aux && i < max_iter
        i=i+1
        aux = centroids
        assign(N.data,centroids,partitions)
        centroids=get_centroids(N.data,partitions)
    end
    N.distance=distance
    dists=get_distances(N.data,centroids,partitions,distance=N.distance)
    N.partitions,N.dists=partitions,dists
    N.centroids,N.sigmas[0]=centroids,maximum(N.dists)
    N.csigmas,N.stats=get_csigmas(N.data,N.centroids,N.partitions,distance=N.distance)
    N.sigmas[0]=maximum(N.csigmas)
    N.reftype=:centroids
    N.kernel=kernel
end

#Feature generator using naive algorithm for density net

function dnet(N::Net,num_of_elements::Int64; distance=L2SquaredDistance(),kernel=linear,reftype=:centroids)
    n,d,k=length(N.data),distance,num_of_elements
    partitions,references=[0 for i in 1:n],Vector{Int}(0)
    pk=1
    dists,sigmas=Vector{Float64},Dict{Int,Float64}()
    while 0 in partitions
        pending=[j for (j,v) in enumerate(partitions) if partitions[j]==0]
        s=rand(pending)
        partitions[s]=s
        pending=[j for (j,v) in enumerate(partitions) if partitions[j]==0]
        push!(references,s)
        pc=sortperm([d(N.data[j],N.data[s]) for j in pending])
        if length(pc)>=k
            partitions[pending[pc[1:k]]]=s
        else
            partitions[pending[pc]]=s
        end
    end
    N.references,N.partitions=references,partitions
    N.centers,N.centroids=N.data[references],get_centroids(N.data,partitions)
    N.csigmas,N.stats=get_csigmas(N.data,N.centroids,N.partitions,distance=N.distance)
    N.sigmas[0]=maximum(N.csigmas)
    N.reftype=:centroids
    N.distance=distance
    N.kernel=kernel
end

#Generates feature espace using cluster centroids or centers

function gen_features(Xo::Vector{T},N::Net)::Vector{Vector{Float64}} where T
    n=length(Xo)
    sigmas,Xr=N.csigmas,Vector{T}(n)
    Xm = N.reftype==:centroids || length(N.centers)==0 ? N.centroids : N.centers 
    nf=length(Xm[1])
    kernel=N.kernel
    for i in 1:n
        xd=Vector{Float64}(nf)
        for j in 1:nf
            xd[j]=kernel(Xo[i],Xm[j],sigma=sigmas[j],distance=N.distance)
        end
        Xr[i]=xd
    end
    Xr
end


function traintest(N; op_function=recall, runs=3, folds=0, trainratio=0.7, testratio=0.3)
    clf, avg = nb.GaussianNB(), Vector{Float64}(runs)
    skf = ms.ShuffleSplit(n_splits=runs, train_size=trainratio, test_size=testratio)
    X=gen_features(N.data,N)
    y=N.labels
    skf[:get_n_splits](X,y)
    for (ei,vi) in skf[:split](X,y)
        ei,vi=ei+1,vi+1
        xt,xv=X[ei],X[vi]
        yt,yv=y[ei],y[vi]
        clf[:fit](xt,yt)
        y_pred=clf[:predict](xv)
        push!(avg,op_function(yv,y_pred))
    end
    #println("========== ",length(N.centroids) ,"  ",avg/folds)
    #@show typeof(clf)
    clf[:fit](X,y)
    return clf,mean(avg)
end

#function transductive(){
#    continue    
#}



function predict_test(xt,y,xv,desc,cl)::Vector{Int64}
    y_pred=[]          
    if contains(desc,"KNN")
        #@show typeof(xt), typeof(y), typeof(cl.X.dist), Symbol(cl.X.dist)
        cln=NearNeighborClassifier(xt,y,cl.X.dist,cl.k,cl.weight)  
        y_pred=[predict_one(cln,x)[1] for x in xv]
    else
        cln=nb.GaussianNB()
        cln[:fit](xt,y)
        y_pred=cln[:predict](xv) 
    end 
    y_pred
end

HammingDistance(x1,x2)::Float64 = length(x1)-sum(x1.==x2)

L2Squared = L2SquaredDistance()

function KlusterClassifier(Xe, Ye; op_function=recall, 
                        K=[4, 8, 16, 32],
                        kernels=[:gaussian, :sigmoid, :linear, :cauchy],
                        runs=3,
                        trainratio=0.6,
                        testratio=0.4,
                        folds=0,
                        top_k=32,
                        threshold=0.03,
                        distances=[:cosine, :L2Squared],
                        nets=[:enet, :kmnet, :dnet], nsplits=3)::Vector{Tuple{Tuple{Any,Net},Float64,String}}
    top=Vector{Tuple{Float64,String}}(0)
    DNNC=Dict()

    for (k, nettype, reftype, kernel, distancek) in zip(K, nets, [:centers, :centroids], kernels, distances)
        if (distancek==:L2Squared || reftype==:centers) && nettype=="kmeans"
            continue
        else
            N=Net(Xe,Ye)
            eval(nettype)(N, k, kernel=eval(kernel), distance = eval(distancek), reftype=reftype)
            X=gen_features(N.data, N)
        end
        for distance in distances
            nnc = NearNeighborClassifier(X,Ye, eval(distance))
            opval,_tmp=optimize!(nnc, op_function,runs=runs, trainratio=trainratio, 
                                    testratio=testratio,folds=folds)[1]
            kknn,w = _tmp
            key="$nettype/$kernel/$k/KNN$kknn/$reftype/$distance/$w"
            push!(top,(opval,key))
            DNNC[key]=(nnc,N)
        end
        key="$nettype/$kernel/$k/NaiveBayes/$reftype/NA"
        nbc,opval=traintest(N,op_function=op_function,folds=folds,
                            trainratio=trainratio,testratio=testratio)
        push!(top,(opval,key))
        DNNC[key]=(nbc,N)   
    end

    sort!(top, rev=true)
    top=top[1:min(12, length(top))]
    # if top_k>0
    #     top=ctop[1:k]
    # else
    #     top=[t for t in top if (ctop[1][1]-t[1])<threshold]
    # end
    # @show length(top)
    LN=[(DNNC[t[2]],t[1],t[2]) for t in top ]
    #@show typeof(LN)
end


function ensemble_cfft(knc,k::Int64=7;testratio=0.4,distance=HammingDistance)::Vector{Tuple{Tuple{Any,Net},Float64,String}}
    (cl,n),opv,desc=knc[1] 
    data=Vector{Vector{String}}(length(knc))
    for i in 1:length(knc)
        kc,opv,desc=knc[i]
        v=split(desc,"/")[1:6]
        data[i]=v
    end
    ind=[i for (i,x) in enumerate(data)]
    partitions,centers,index=[0 for x in ind],[1],KnnResult(k)
    while length(centers)<k && length(centers)<=length(ind) 
        oid,dist=maxmin(data,centers,ind,index,distance,partitions)
        push!(centers,oid)  
    end
    knc[centers]
end


function ensemble_pfft(knc,k::Int64=7;trainratio=0.6,distance=HammingDistance)::Vector{Tuple{Tuple{Any,Net},Float64,String}}
    (cl,N),opv,desc=knc[1] 
    n=length(N.data)
    tn=Int(trunc(n*trainratio));
    data=Vector{Vector{Int}}(length(knc))
    perm=randperm(n)
    ti,vi=perm[1:tn],perm[tn+1:n] 
    for i in 1:length(knc)
        (cl,N),opv,desc=knc[i]
        xv=gen_features(N.data[vi],N)
        xt=gen_features(N.data[ti],N)
        y=N.labels[ti]
        data[i]=predict_test(xt,y,xv,desc,cl)
    end
    ind=[i for (i,x) in enumerate(data)]
    partitions,centers,index=[0 for x in ind],[1],KnnResult(k)
    while length(centers)<k && length(centers)<=length(ind) 
        oid,dist=maxmin(data,centers,ind,index,distance,partitions)
        push!(centers,oid)  
    end
    knc[centers]
end

function predict(knc,X;ensemble_k=1)::Vector{Int64}
    y_t=Vector{Int}(0)
    for i in 1:ensemble_k
        kc,opv,desc=knc[i]
        cl,N=kc
        xv=gen_features(X,N)       
        if contains(desc,"KNN")  
            y_i=[predict_one(cl,x)[1] for x in xv]
        else
            y_i=cl[:predict](xv) 
        end 
        y_t = length(y_t)>0 ? hcat(y_t,y_i) : hcat(y_i)
    end
    y_pred=Vector{Int}(length(X))
    for i in 1:length(y_t[:,1])
        y_r=y_t[i,:]
        y_pred[i]=last(sort([(count(x->x==k,y_r),k) for k in unique(y_r)]))[2]
    end
    y_pred
end

function predict_proba(knc,X;ensemble_k=1):Vector{Vector{Float64}}
    kc,opv,desc=knc[1]
    cl,N=kc
    xv=gen_features(X,N)
    if contains(desc,"KNN")  
        y_pred=[predict_one_proba(cl,x) for x in xv]
    else
        y_pred=cl[:predict_proba](xv) 
    end
    y_pred
end

end
