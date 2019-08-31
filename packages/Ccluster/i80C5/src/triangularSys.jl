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

# utility functions for triangular systems
#

import AbstractAlgebra: Generic

import Nemo: fmpz, fmpq, acb, acb_poly, fmpq_poly, degree, ArbField, AcbField, RealField, ComplexField, 
             AcbPolyRing, PolynomialRing, evaluate, coeff

# export TIMEINGETPOLAT

# TIMEINGETPOLAT = [0.];

function getDeg(pol, ind::Int)::Array{Int,1} #get the vector of degrees of pol
    if ind==1
        return [degree(pol)]
    else
        d::Int = degree(pol)
        degrees = Int[]
        if d==-1
            for i=1:ind-1
                push!(degrees,0)
            end
        else
            degrees = getDeg( pol.coeffs[1], ind-1)
            for i = 2:d+1
                degtemp::Array{Int,1} = getDeg( pol.coeffs[i], ind-1)
                for j=1:ind-1
                    if degtemp[j]>degrees[j]
                        degrees[j] = degtemp[j]
                    end
                end
            end
        end
        push!(degrees, d)
        return degrees
    end
end

function evalUniFMPQPol(P::fmpq_poly, b::acb, prec::Int)::acb
    CC::AcbField = ComplexField(prec)
    R::AcbPolyRing, dummy::acb_poly = PolynomialRing(CC, "dummy")
    res::acb_poly = R(0)
    ccall((:acb_poly_set_fmpq_poly, :libarb), 
      Cvoid, (Ref{acb_poly}, Ref{fmpq_poly}, Int), 
              res,           P,             prec)
    return evaluate(res, CC(b))
end
    
function evalPolAt(P, b::Array{acb, 1}, prec::Int)::acb
    if (length(b)==1)
        res = evalUniFMPQPol(P, b[1], prec)
    else
        btemp::acb=pop!(b)
        CC::AcbField = ComplexField(prec)
        R::AcbPolyRing, dummy::acb_poly = PolynomialRing(CC, "dummy")
        pol::acb_poly = R(0);
        for index=0:degree(P)
            pol = pol + evalPolAt(coeff(P,index), b, prec)*dummy^index
        end
        res::acb = evaluate(pol, CC(btemp))
        push!(b,btemp)
    end
    return res
end

function evalPolAtHorner(P::fmpq_poly, b::Array{acb, 1}, prec::Int, field::AcbField, ring::AcbPolyRing)::acb
    poly::acb_poly = ring(0)
    ccall((:acb_poly_set_fmpq_poly, :libarb), 
            Cvoid, (Ref{acb_poly}, Ref{fmpq_poly}, Int), 
                    poly,          P,              prec)
    return evaluate(poly, b[1])
end

function evalPolAtHorner(P::Generic.Poly{fmpq_poly}, 
                         b::Array{acb, 1}, prec::Int, field::AcbField, ring::AcbPolyRing)::acb
    res::acb = field(0)
    deg = degree(P)
    temp::acb_poly = ring(0)
    while deg>=0
    
        ccall((:acb_poly_set_fmpq_poly, :libarb), 
                Cvoid, (Ref{acb_poly}, Ref{fmpq_poly},      Int), 
                        temp,          coeff(P,deg), prec)
        
        res = evaluate(temp, b[1]) + b[2]*res
        
        deg = deg - 1
    end
    return res
end

function evalPolAtHorner(P::Generic.Poly{Generic.Poly{fmpq_poly}}, 
                         b::Array{acb, 1}, prec::Int, field::AcbField, ring::AcbPolyRing)::acb
    
    res::acb = field(0)
    deg = degree(P)
    temp::acb_poly = ring(0)
    
    P2::Generic.Poly{fmpq_poly} = coeff(P,deg)
    deg2::Int = degree(P2)
    res2::acb = field(0)
        
    while deg>=0
        
        while deg2>=0
            ccall((:acb_poly_set_fmpq_poly, :libarb), 
                    Cvoid, (Ref{acb_poly}, Ref{fmpq_poly},      Int), 
                           temp,           coeff(P2,deg2), prec)
            res2 = evaluate(temp, b[1]) + b[2]*res2
            deg2 = deg2-1
        end
        
        res = res2 + b[3]*res
        
        deg = deg - 1
        
        if deg>=0

            P2 = coeff(P,deg)
            deg2= degree(P2)
            res2 = field(0)
            
        end
        
    end
    
    return res
end

function evalPolAtHorner(P::Generic.Poly{Generic.Poly{Generic.Poly{fmpq_poly}}}, 
                         b::Array{acb, 1}, prec::Int, field::AcbField, ring::AcbPolyRing)::acb
    res::acb = field(0)
    deg = degree(P)
    temp::acb_poly = ring(0)
    
    P2::Generic.Poly{Generic.Poly{fmpq_poly}} = coeff(P,deg)
    deg2::Int = degree(P2)
    res2::acb = field(0)
    
    P3::Generic.Poly{fmpq_poly} = coeff(P2,deg2)
    deg3::Int = degree(P3)
    res3::acb = field(0)
    
    while deg>=0
        
        while deg2>=0
            
            while deg3>=0
                ccall((:acb_poly_set_fmpq_poly, :libarb), 
                        Cvoid, (Ref{acb_poly}, Ref{fmpq_poly},      Int), 
                               temp,           coeff(P3,deg3), prec)
                        res3 = evaluate(temp, b[1]) + b[2]*res3
            
                deg3 = deg3-1
            end
            
            res2 = res3 + b[3]*res2
            deg2 = deg2-1
            
            if deg2 >=0
                P3 = coeff(P2,deg2)
                deg3 = degree(P3)
                res3 = field(0)
            end
        end
        
        res = res2 + b[4]*res
        
        deg = deg - 1
        
        if deg>=0

            P2 = coeff(P,deg)
            deg2= degree(P2)
            res2 = field(0)
            
            P3 = coeff(P2,deg2)
            deg3 = degree(P3)
            res3 = field(0)

        end
    end
    
    return res
end

function evalPolAtHorner(P, b::Array{acb, 1}, prec::Int, field::AcbField, ring::AcbPolyRing)::acb
    res::acb = field(0)
    btemp::acb=pop!(b)
    deg = degree(P)
    while deg>=0
        res = evalPolAtHorner( coeff(P,deg), b, prec, field, ring ) + btemp*res
        deg = deg - 1
    end
    push!(b, btemp)
    return res
end

function getPolAtHorner(P, b::Array{acb, 1}, prec::Int)::acb_poly
#     tic=time()
    CC::AcbField = ComplexField(prec)
    R::AcbPolyRing, dummy::acb_poly = PolynomialRing(CC, "dummy")
    res::acb_poly = R(0)
    deg = degree(P)
    while deg>=0
        if coeff(P,deg)==0
            res = dummy*res
        else
            res = evalPolAtHorner( coeff(P,deg), b, prec, CC, R ) + dummy*res
        end
        deg = deg - 1
    end
#     global TIMEINGETPOLAT
#     TIMEINGETPOLAT[1] = TIMEINGETPOLAT[1] + (time()-tic)
    return res
end

function getPolAt(P, b::Array{acb, 1}, prec::Int)::acb_poly
#     print("--------------------------\n")
#     tic=time()
    CC::AcbField = ComplexField(prec)
    R::AcbPolyRing, dummy::acb_poly = PolynomialRing(CC, "dummy")
    res::acb_poly = R(0)
    for index=0:degree(P)
        res = res + evalPolAt(coeff(P,index), b, prec)*dummy^index
    end
#     toc=time()-tic
#     global TIMEINGETPOLAT
#     TIMEINGETPOLAT[1] = TIMEINGETPOLAT[1] + (time()-tic)
#     if length(b)==3
#         print("--------------------------\n")
#         print("res recursive: $res\n")
# #         res2::acb_poly = R(0)
# #         res2 = getPolAt2(P, b, prec)
# #         print("res iterative: $res2\n")
#         tic=time()
#         res3::acb_poly = R(0)
#         res3 =getPolAtHorner(P, b, prec)
#         toc2=time()-tic
#         print("res Horner   : $res3\n")
#         print("time rec: $toc, time Horner: $toc2\n")
#         
# #         print("time rec: $toc\n")
# #         @time getPolAt4Horner(P, b, prec) 
#         
# #     print("arguments: ")
# #     for i=1:length(b)
# #         print("$(b[i]), ");
# #     end
# #     print("\n")
# #     print("res $(length(b)): $res\n")
#         print("--------------------------\n")
#     end
    return res
end

# function getPolAt2(P::Generic.Poly{fmpq_poly}, 
#                   b::Array{acb, 1}, prec::Int)::acb_poly
# #     tic=time()
#     CC::AcbField = ComplexField(prec)
#     R::AcbPolyRing, dummy::acb_poly = PolynomialRing(CC, "dummy")
#     res::acb_poly = R(0)
#     temp::acb_poly = R(0)
#     for index=0:degree(P)
#         
#         ccall((:acb_poly_set_fmpq_poly, :libarb), 
#                 Cvoid, (Ref{acb_poly}, Ref{fmpq_poly},      Int), 
#                         temp,          coeff(P,index), prec)
#                         
#         res = res + evaluate(temp, b[1])*dummy^index
#         
#     end
#     
# #     print("--------------------------\n")
# 
# #     global TIMEINGETPOLAT
# #     TIMEINGETPOLAT[1] = TIMEINGETPOLAT[1] + (time()-tic)
#     return res
# end
# 
# function getPolAt2Horner(P::Generic.Poly{fmpq_poly}, 
#                          b::Array{acb, 1}, prec::Int)::acb_poly
# 
#     CC::AcbField = ComplexField(prec)
#     R::AcbPolyRing, dummy::acb_poly = PolynomialRing(CC, "dummy")
#     res::acb_poly = R(0)
#     deg::Int = degree(P)
#     #higher degree coeff
#     temp::acb_poly = R(0)
#     while deg>=0
#         
#         ccall((:acb_poly_set_fmpq_poly, :libarb), 
#             Cvoid, (Ref{acb_poly}, Ref{fmpq_poly},      Int), 
#                     temp,          coeff(P,deg), prec)
#                     
#         res = evaluate(temp, b[1]) + dummy*res
#                     
#         deg = deg-1
#     end
#     
#     return res
# end
# 
# function getPolAt3Horner(P::Generic.Poly{Generic.Poly{fmpq_poly}}, 
#                          b::Array{acb, 1}, prec::Int)::acb_poly
# 
#     CC::AcbField = ComplexField(prec)
#     R::AcbPolyRing, dummy::acb_poly = PolynomialRing(CC, "dummy")
#     res::acb_poly = R(0)
#     deg1::Int = degree(P)
#     #higher degree coeff
# #     temp::acb_poly = R(0)
#     while deg1>=0
#         
#         P2::Generic.Poly{fmpq_poly} = coeff(P,deg1)
#         deg2::Int = degree(P2)
#         res2::acb = CC(0)
#         temp2::acb_poly = R(0)
#         while deg2>=0
#             ccall((:acb_poly_set_fmpq_poly, :libarb), 
#                     Cvoid, (Ref{acb_poly}, Ref{fmpq_poly},      Int), 
#                            temp2,           coeff(P2,deg2), prec)
#             res2 = evaluate(temp2, b[1]) + b[2]*res2
#             deg2 = deg2-1
#         end
#         
#         res = res2 + dummy*res
#         
#         deg1 = deg1-1
#     end
#     
#     return res
# end
# 
# function getPolAt4Horner(P::Generic.Poly{Generic.Poly{Generic.Poly{fmpq_poly}}}, 
#                          b::Array{acb, 1}, prec::Int)::acb_poly
# 
#     CC::AcbField = ComplexField(prec)
#     R::AcbPolyRing, dummy::acb_poly = PolynomialRing(CC, "dummy")
#     res::acb_poly = R(0)
#     deg1::Int = degree(P)
#     #higher degree coeff
# #     temp::acb_poly = R(0)
#     while deg1>=0
#         
#         P2::Generic.Poly{Generic.Poly{fmpq_poly}} = coeff(P,deg1)
#         deg2::Int = degree(P2)
#         res2::acb = CC(0)
# #         temp2::acb_poly = R(0)
#         while deg2>=0
#             
#             P3::Generic.Poly{fmpq_poly} = coeff(P2,deg2)
#             deg3::Int = degree(P3)
#             res3::acb = CC(0)
#             temp3::acb_poly = R(0)
#             
#             while deg3>=0
#                 
#                 ccall((:acb_poly_set_fmpq_poly, :libarb), 
#                     Cvoid, (Ref{acb_poly}, Ref{fmpq_poly},      Int), 
#                            temp3,           coeff(P3,deg3), prec)
#                 res3 = evaluate(temp3, b[1]) + b[2]*res3
#             
#                 deg3 = deg3-1
#             end
#             
#             res2 = res3 + b[3]*res2
#             
#             deg2 = deg2-1
#         end
#         
#         res = res2 + dummy*res
#         
#         deg1 = deg1-1
#     end
#     
#     return res
# end
# 
# function getPolAt5Horner(P::Generic.Poly{Generic.Poly{Generic.Poly{Generic.Poly{fmpq_poly}}}}, 
#                          b::Array{acb, 1}, prec::Int)::acb_poly
# 
#     CC::AcbField = ComplexField(prec)
#     R::AcbPolyRing, dummy::acb_poly = PolynomialRing(CC, "dummy")
#     res::acb_poly = R(0)
#     deg1::Int = degree(P)
#     #higher degree coeff
# #     temp::acb_poly = R(0)
#     while deg1>=0
#         
#         P2::Generic.Poly{Generic.Poly{Generic.Poly{fmpq_poly}}} = coeff(P,deg1)
#         deg2::Int = degree(P2)
#         res2::acb = CC(0)
# #         temp2::acb_poly = R(0)
#         while deg2>=0
#             
#             P3::Generic.Poly{Generic.Poly{fmpq_poly}} = coeff(P2,deg2)
#             deg3::Int = degree(P3)
#             res3::acb = CC(0)
# #             temp3::acb_poly = R(0)
#             
#             while deg3>=0
#             
#                 P4::Generic.Poly{fmpq_poly} = coeff(P3,deg3)
#                 deg4::Int = degree(P4)
#                 res4::acb = CC(0)
#                 temp4::acb_poly = R(0)
#                 
#                 while deg4>=0
#                 
#                     ccall((:acb_poly_set_fmpq_poly, :libarb), 
#                            Cvoid, (Ref{acb_poly}, Ref{fmpq_poly},      Int), 
#                                    temp4,           coeff(P4,deg4), prec)
#                            res4 = evaluate(temp4, b[1]) + b[2]*res4
#                     
#                     deg4 = deg4-1
#                 end
#             
#                 res3 = res4 + b[3]*res3
#                 
#                 deg3 = deg3-1
#             end
#             
#             res2 = res3 + b[4]*res2
#             
#             deg2 = deg2-1
#         end
#         
#         res = res2 + dummy*res
#         
#         deg1 = deg1-1
#     end
#     
#     return res
# end
