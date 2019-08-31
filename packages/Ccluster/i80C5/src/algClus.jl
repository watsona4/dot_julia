#
#  Copyright (C) 2019 Remi Imbach
#
#  This file is part of Ccluster.
#
#  Ccluster is free software: you can redistribute it and/or modify it under
#  the terms of the GNU Lesser General Public License (LGPL) as published
#  by the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.  See <http://www.gnu.org/licenses/>.
#

import Nemo: fmpz, fmpq, arb, acb, acb_poly, fmpq_poly, ArbField, AcbField, RealField, ComplexField, ball
             
mutable struct algClus                      # represents an algebraic cluster \alpha
    _nbSols::Int                            # the sum of multiplicity of roots in the cluster
    _prec::Int                              # the precision of the cluster; i.e. w() < 2*2^{-prec}
    _isolatingBox::Ccluster.box             # a box isolating \alpha st width(_isolatingBox) < 2*2^(-prec)
    _approx::acb                       # satisfies |\alpha - a |<2^{-prec}
    
    _CC::Ptr{Ccluster.connComp}             # a pointer on the connected component of boxes
    _initBox::Ccluster.box                  # the initial box i.e. root in the subdivision tree
    
    function algClus( objCC::Ccluster.connComp, ptrCC::Ptr{Ccluster.connComp}, bInit::Ccluster.box, prec::Int )
        z = new()
        
        z._nbSols = Ccluster.getNbSols(objCC)
        z._prec = prec
        z._initBox = Ccluster.box( Ccluster.getCenterRe(bInit), Ccluster.getCenterIm(bInit), Ccluster.getWidth(bInit) )
        z._CC = ptrCC
        
        z._isolatingBox = Ccluster.getComponentBox(objCC,z._initBox)
        R::ArbField = RealField(z._prec)
        C::AcbField = ComplexField(z._prec)
        bRe::arb = ball(R(Ccluster.getCenterRe(z._isolatingBox)), R(fmpq(1,2)*Ccluster.getWidth(z._isolatingBox)))
        bIm::arb = ball(R(Ccluster.getCenterIm(z._isolatingBox)), R(fmpq(1,2)*Ccluster.getWidth(z._isolatingBox)))
        z._approx = C(bRe, bIm)
        return z
    end
    
    function algClus( a::algClus )
        z = new()
        
        z._nbSols = a._nbSols
        z._prec = a._prec
        z._initBox = Ccluster.box( Ccluster.getCenterRe(a._initBox), Ccluster.getCenterIm(a._initBox), Ccluster.getWidth(a._initBox) )
        z._CC = Ccluster.copy_Ptr(a._CC)
        
        z._isolatingBox = Ccluster.box( Ccluster.getCenterRe(a._isolatingBox), Ccluster.getCenterIm(a._isolatingBox), Ccluster.getWidth(a._isolatingBox) )
        R::ArbField = RealField(z._prec)
        C::AcbField = ComplexField(z._prec)
        bRe::arb = ball(R(Ccluster.getCenterRe(z._isolatingBox)), R(fmpq(1,2)*Ccluster.getWidth(z._isolatingBox)))
        bIm::arb = ball(R(Ccluster.getCenterIm(z._isolatingBox)), R(fmpq(1,2)*Ccluster.getWidth(z._isolatingBox)))
        z._approx = C(bRe, bIm)
        return z
    end
end

function toStr(a::algClus)
    res = ""
    res = res * "algebraic cluster: prec: $(a._prec), nbsols: $(a._nbSols)\n"
    res = res * Ccluster.toStr(a._isolatingBox)
    res = res * "\n approx: $(a._approx)"
    res = res * "\n"
    res 
    return res
end

function getPrec(a::algClus)::Int          #get the precision of a cluster
    return a._prec
end

function getPrec(a::Array{algClus,1})::Int #get the precision of a TAC, i.e. an array of algClus
    prec::Int = a[1]._prec
    for index in 2:length(a)
        if a[index]._prec < prec
            prec = a[index]._prec
        end
    end
    return prec
end

function getMaxPrec(a::Array{algClus,1})::Int #get the maximum precision of a TAC, i.e. an array of algClus
    prec::Int = a[1]._prec
    for index in 2:length(a)
        if a[index]._prec > prec
            prec = a[index]._prec
        end
    end
    return prec
end

function getPrecs(a::Array{algClus,1})::Array{Int,1}   #get the array of precisions of a TAC
    precs = Int[]
    for index in 1:length(a)
        push!(precs, a[index]._prec)
    end
    return precs
end

#copying
function copyIn( dest::algClus, src::algClus )::Nothing
    dest._nbSols = src._nbSols
    dest._prec = src._prec
    dest._isolatingBox = Ccluster.box( Ccluster.getCenterRe(src._isolatingBox), 
                                       Ccluster.getCenterIm(src._isolatingBox), 
                                       Ccluster.getWidth(src._isolatingBox) )
    dest._initBox = Ccluster.box( Ccluster.getCenterRe(src._initBox), Ccluster.getCenterIm(src._initBox), Ccluster.getWidth(src._initBox) )
    dest._CC = Ccluster.copy_Ptr(src._CC)
    R::ArbField = RealField(src._prec)
    C::AcbField = ComplexField(src._prec)
    bRe::arb = ball(R(Ccluster.getCenterRe(dest._isolatingBox)), R(fmpq(1,2)*Ccluster.getWidth(dest._isolatingBox)))
    bIm::arb = ball(R(Ccluster.getCenterIm(dest._isolatingBox)), R(fmpq(1,2)*Ccluster.getWidth(dest._isolatingBox)))
    dest._approx = C(bRe, bIm);
    return
end

function copyIn( dest::Array{algClus,1}, src::Array{algClus,1} )::Nothing
    for index in 1:length(src)
        copyIn( dest[index], src[index] )
    end
    return
end

function clusCopy(a::algClus)::Ccluster.algClus
    return algClus(a)
end

function clusCopy(a::Array{algClus,1})::Array{Ccluster.algClus,1}
    res=Ccluster.algClus[]
    for index in 1:length(a)
        push!(res, algClus(a[index]))
    end
    return res
end

#require: prec<=a._prec
function getApproximation(a::algClus, prec::Int)::acb #get approximation of the center 
#     R::ArbField = RealField(prec)
    C::AcbField = ComplexField(prec)
    if prec<a._prec
        return C(a._approx)
    else
        return a._approx
    end
end

# #require: prec<=getPrec(a)
function getApproximation(a::Array{algClus,1}, prec::Int)::Array{acb,1}
    res=acb[]
    for index in 1:length(a)
        push!(res, getApproximation(a[index], prec) )
    end
    return res
end

function getBestApproximation(a::algClus)::acb
    return a._approx
end

function getBestApproximation(a::Array{algClus,1})::Array{acb,1}
    res=acb[]
    for index in 1:length(a)
        push!(res, getBestApproximation(a[index]) )
    end
    return res
end

# refine an algebraic cluster
function refine_algClus( a::algClus, getApproximation::Function, prec::Int, strat::Int, verb::Int )::Array{Array{Ccluster.algClus,1},1}
    lCC = Ccluster.listConnComp()
    lCCRes = Ccluster.listConnComp()
    eps::fmpq = fmpq(1, fmpz(2)^(prec-1))
    Ccluster.push_ptr(lCC, a._CC)
    Ccluster.ccluster_refine(lCCRes, getApproximation, lCC, a._initBox, eps, strat, verb)
    
    res = Array{Ccluster.algClus,1}[]
    while !Ccluster.isEmpty(lCCRes)
        objCC, ptrCC = Ccluster.pop_obj_and_ptr(lCCRes)
        push!(res, [algClus( objCC, ptrCC, a._initBox, prec )] )
    end
    
    return res
end

# # test with sqrt(2)
# using Nemo
# Rx, x = PolynomialRing(QQ, "x")
# P = x^2 - fmpq(2)
# function getApproximation( dest::Ptr{acb_poly}, prec::Int )
#     ccall((:acb_poly_set_fmpq_poly, :libarb), 
#       Cvoid, (Ptr{acb_poly}, Ref{fmpq_poly}, Int), 
#              dest,          P,            prec)
# end
# mprec = 53
# eps = fmpq(1, fmpz(2)^(mprec-1))
# strat = 23
# bInit = Ccluster.box(Nemo.fmpq(1,1),Nemo.fmpq(0,1),Nemo.fmpq(1,1))
# # qRes = Ccluster.ccluster(getApproximation, bInit, eps, strat, 1);
# qRes = Ccluster.ccluster_solve(getApproximation, bInit, eps, strat, 1)
# objCC, ptrCC = Ccluster.pop_obj_and_ptr(qRes)
# sqrtOfTwo = Ccluster.algClus(objCC, ptrCC, bInit, 53)
# Ccluster.toStr(sqrtOfTwo)
# sqrtOfTwo2 = Ccluster.algClus(sqrtOfTwo)
# sqrtOfTwo3 = Ccluster.algClus(sqrtOfTwo)
# Ccluster.getApproximation(sqrtOfTwo,53)
# Ccluster.getBestApproximation(sqrtOfTwo)
# Ccluster.getApproximation([sqrtOfTwo2, sqrtOfTwo3],53)
# Ccluster.getBestApproximation([sqrtOfTwo2, sqrtOfTwo3])
# 
# res = Ccluster.refine_algClus( sqrtOfTwo, getApproximation, 212, strat, 0)
