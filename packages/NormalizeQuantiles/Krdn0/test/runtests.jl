
#using Distributed

using NormalizeQuantiles

using Test
using SharedArrays
using Statistics


# write your own tests here
@test 1 == 1

testfloat = [ 3.0 2.0 8.0 1.0 ; 4.0 5.0 6.0 2.0 ; 9.0 7.0 8.0 3.0 ; 5.0 2.0 8.0 4.0 ]
r=normalizeQuantiles(testfloat)
@test mean(r[:,1]) >= 4.8124 && mean(r[:,1]) <= 4.8126
@test mean(r[:,2]) >= 4.8124 && mean(r[:,2]) <= 4.8126
@test mean(r[:,3]) >= 4.8124 && mean(r[:,3]) <= 4.8126
@test mean(r[:,4]) >= 4.8124 && mean(r[:,4]) <= 4.8126

sa=SharedArray{Float64}((size(testfloat,1),size(testfloat,2)));
sa[:]=testfloat[:]
r=normalizeQuantiles(sa)
@test mean(r[:,1]) >= 4.8124 && mean(r[:,1]) <= 4.8126
@test mean(r[:,2]) >= 4.8124 && mean(r[:,2]) <= 4.8126
@test mean(r[:,3]) >= 4.8124 && mean(r[:,3]) <= 4.8126
@test mean(r[:,4]) >= 4.8124 && mean(r[:,4]) <= 4.8126

testfloat[2,2]=NaN
testfloat[3,4]=NaN
r=normalizeQuantiles(testfloat)
@test mean(r[:,1]) >= 4.91 && mean(r[:,1]) <= 4.92
@test isnan(r[2,2])
@test isnan(r[3,4])
@test mean(r[:,3]) >= 4.91 && mean(r[:,3]) <= 4.92

testfloat = [ 3.5 2.0 8.1 1.0 ; 4.5 5.0 6.0 2.0 ; 9.0 7.6 8.2 3.0 ; 5.0 2.0 8.0 4.0 ]
r=normalizeQuantiles(testfloat)
@test mean(r[:,1]) >= 4.93124 && mean(r[:,1]) <= 4.93125
@test mean(r[:,2]) >= 4.93124 && mean(r[:,2]) <= 4.93125
@test mean(r[:,3]) >= 4.93124 && mean(r[:,3]) <= 4.93125
@test mean(r[:,4]) >= 4.93124 && mean(r[:,4]) <= 4.93125

sa=SharedArray{Float64}((size(testfloat,1),size(testfloat,2)));
sa[:]=testfloat[:]
r=normalizeQuantiles(sa)
@test mean(r[:,1]) >= 4.93124 && mean(r[:,1]) <= 4.93125
@test mean(r[:,2]) >= 4.93124 && mean(r[:,2]) <= 4.93125
@test mean(r[:,3]) >= 4.93124 && mean(r[:,3]) <= 4.93125
@test mean(r[:,4]) >= 4.93124 && mean(r[:,4]) <= 4.93125

testfloat=[ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
check=[ 2.0 3.0 2.0 ; 4.0 6.0 4.0 ; 8.0 8.0 7.0 ; 6.0 3.0 7.0 ]
qn=normalizeQuantiles(testfloat)
@test qn == check

sa=SharedArray{Float64}((size(testfloat,1),size(testfloat,2)));
sa[:]=testfloat[:]
qn=normalizeQuantiles(sa)
@test qn == check

testint = [ 1 1 1 ; 1 1 1 ; 1 1 1 ]
qn=normalizeQuantiles(testint)
@test qn == testint

sa=SharedArray{Int}((size(testint,1),size(testint,2)));
sa[:]=testint[:]
qn=normalizeQuantiles(sa)
@test qn == testint

dafloat=Array{Union{Missing, Float64}}(testfloat)
dafloat[2,2]=missing
qn=normalizeQuantiles(dafloat)
@test isnan(qn[2,2])
@test qn[1,2]==3.5
@test qn[2,1]==5.0

dafloat[2,2]=NaN
sa=SharedArray{Float64}((size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
qn=normalizeQuantiles(sa)
@test isnan(qn[2,2])
@test qn[1,2]==3.5
@test qn[2,1]==5.0

dafloat[2,:].=missing
qn=normalizeQuantiles(dafloat)
@test isnan(qn[2,1])
@test isnan(qn[2,2])
@test isnan(qn[2,3])

dafloat[2,:].=NaN
sa=SharedArray{Float64}((size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
qn=normalizeQuantiles(sa)
@test isnan(qn[2,1])
@test isnan(qn[2,2])
@test isnan(qn[2,3])

dafloat[3,1:2].=missing
qn=normalizeQuantiles(dafloat)
@test isnan(qn[3,1])
@test isnan(qn[3,2])

dafloat[3,1:2].=NaN
sa=SharedArray{Float64}((size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
qn=normalizeQuantiles(sa)
@test isnan(qn[3,1])
@test isnan(qn[3,2])

dafloat[1,:].=missing
dafloat[2,:].=missing
dafloat[3,:].=missing
dafloat[4,:].=missing
qn = normalizeQuantiles(dafloat)
@test isnan(qn[1,1])
@test isnan(qn[1,2])
@test isnan(qn[1,3])
@test isnan(qn[2,1])
@test isnan(qn[2,2])
@test isnan(qn[2,3])
@test isnan(qn[3,1])
@test isnan(qn[3,2])
@test isnan(qn[3,3])
@test isnan(qn[4,1])
@test isnan(qn[4,2])
@test isnan(qn[4,3])

dafloat[1,:].=NaN
dafloat[2,:].=NaN
dafloat[3,:].=NaN
dafloat[4,:].=NaN
a=SharedArray{Float64}((size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
qn=normalizeQuantiles(sa)
@test isnan(qn[1,1])
@test isnan(qn[1,2])
@test isnan(qn[1,3])
@test isnan(qn[2,1])
@test isnan(qn[2,2])
@test isnan(qn[2,3])
@test isnan(qn[3,1])
@test isnan(qn[3,2])
@test isnan(qn[3,3])
@test isnan(qn[4,1])
@test isnan(qn[4,2])
@test isnan(qn[4,3])


testfloat = [ 2.0 2.0 8.0 0.0 7.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[4]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[4]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,1,4,0,2])

testfloat = [ 2.0 2.0 8.0 7.0 0.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[5]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[5]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,1,3,2,0])

testfloat = [ 2.0 2.0 8.0 0.0 7.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[4]=missing
(r,m)=sampleRanks(a,tiesMethod=tmOrder,naIncreasesRank=true,resultMatrix=true)
r[4]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,2,5,0,3])

testfloat = [ 2.0 2.0 8.0 0.0 7.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[4]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMax,naIncreasesRank=false,resultMatrix=true)
r[4]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([2,2,4,0,3])

testfloat = [ 2.0 2.0 8.0 0.0 7.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[4]=missing
(r,m)=sampleRanks(a,tiesMethod=tmRandom,naIncreasesRank=false,resultMatrix=true)
r[4]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,2,4,0,3]) || r==Array{Int}([2,1,4,0,3])

testfloat = [ 2.0 2.0 8.0 0.0 7.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[4]=missing
(r,m)=sampleRanks(a,tiesMethod=tmAverage,naIncreasesRank=false,resultMatrix=true)
r[4]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([2,2,4,0,3])

testfloat = [ 2.0 2.0 8.0 0.0 7.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[4]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
r[4]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,1,3,0,2])

testfloat = [ 5.0 2.0 4.0 3.0 1.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r=[ Int(x) for x in r ]
@test r==Array{Int}([5,2,4,3,1])

testfloat = [ 2.0 2.0 0.0 2.0 2.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[3]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,1,0,1,1])

testfloat = [ 2.0 2.0 0.0 2.0 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[3]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,1,0,1,3])

testfloat = [ 2.0 2.0 0.0 2.0 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
r[3]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,1,0,1,2])

testfloat = [ 2.0 2.0 0.0 3.0 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[3]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,1,0,3,4])

testfloat = [ 2.0 2.0 0.0 3.0 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
r[3]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,1,0,2,3])

testfloat = [ 0.0 2.0 5.0 3.0 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[1]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([0,2,5,3,4])

testfloat = [ 0.0 2.0 5.0 3.0 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
r[1]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([0,1,4,2,3])

testfloat = [ NaN 1.0 NaN 2.0 NaN 3.0 NaN 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=missing
a[3]=missing
a[5]=missing
a[7]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[1]=0
r[3]=0
r[5]=0
r[7]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([0,2,0,4,0,6,0,8])

testfloat = [ NaN 1.0 NaN 4.0 NaN 3.0 NaN 2.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=missing
a[3]=missing
a[5]=missing
a[7]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[1]=0
r[3]=0
r[5]=0
r[7]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([0,2,0,8,0,6,0,4])

testfloat = [ NaN 1.0 NaN 4.0 NaN 3.0 NaN 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=missing
a[3]=missing
a[5]=missing
a[7]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[1]=0
r[3]=0
r[5]=0
r[7]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([0,2,0,6,0,4,0,6])

testfloat = [ NaN 1.0 NaN 2.0 NaN NaN 3.0 NaN 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=missing
a[3]=missing
a[5]=missing
a[6]=missing
a[8]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[1]=0
r[3]=0
r[5]=0
r[6]=0
r[8]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([0,2,0,4,0,0,7,0,9])

testfloat = [ NaN 1.0 NaN 4.0 NaN NaN 3.0 NaN 2.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=missing
a[3]=missing
a[5]=missing
a[6]=missing
a[8]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[1]=0
r[3]=0
r[5]=0
r[6]=0
r[8]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([0,2,0,9,0,0,7,0,4])

testfloat = [ NaN NaN 1.0 NaN 2.0 NaN 3.0 NaN 4.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=missing
a[2]=missing
a[4]=missing
a[6]=missing
a[8]=missing
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[1]=0
r[2]=0
r[4]=0
r[6]=0
r[8]=0
r=[ Int(x) for x in r ]
@test r==Array{Int}([0,0,3,0,5,0,7,0,9])

testfloat = [ 2.0 2.0 2.0 2.0 2.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r=[ Int(x) for x in r ]
@test r==Array{Int}([1,1,1,1,1])

testfloat = [ 2.0 2.0 2.0 2.0 2.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
(r,m)=sampleRanks(a,tiesMethod=tmReverse,naIncreasesRank=true,resultMatrix=true)
r=[ Int(x) for x in r ]
@test r==Array{Int}([5,4,3,2,1])

testfloat = [ 1.0 2.0 3.0 ; 4.0 5.0 6.0 ; 7.0 8.0 9.0 ; 10.0 11.0 12.0 ]
a=Array{Union{Missing, Float64}}(undef,(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[5]=missing
a[8]=missing
a[3]=missing
(r,m)=sampleRanks(a,tiesMethod=tmReverse,naIncreasesRank=true,resultMatrix=true)
@test r[1]==1
@test r[2]==4
@test ismissing(r[3])==true
@test r[4]==11
@test ismissing(r[5])==true
@test r[6]==6
@test r[7]==9
@test ismissing(r[8])==true
@test r[9]==2
@test r[10]==7
@test r[11]==10
@test r[12]==12




