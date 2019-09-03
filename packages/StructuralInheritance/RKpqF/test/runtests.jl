using Test

#NOTE: @testset will not work for testing this.
using StructuralInheritance
## TEST BASIC STRUCTURAL INHERITENCE ##

SI = StructuralInheritance

  StructuralInheritance.@protostruct struct A
     f_a::Int
     f_b
  end

  StructuralInheritance.@protostruct struct B <: A
      f_c::Float32
      f_d
  end

  @test fieldnames(B) == (:f_a,:f_b,:f_c,:f_d) #Test names of fields and order
  @test fieldtype.(B,[1,2,3,4]) == [Int,Any,Float32,Any]
  @test B <: ProtoB && B <: ProtoA

# exception thrown when inherited class uses same names
  @test_throws Any StructuralInheritance.@protostruct struct C <: A
      f_a::Int
  end

  @test_throws Any StructuralInheritance.@protostruct struct D <: A
      f_b
  end

  # exception thrown trying to inherit from a concrete class not defined
  # by @protostruct
  @test_throws Any StructuralInheritance.@protostruct struct E <: Int
      f_b
  end

  @test_throws Any StructuralInheritance.@protostruct struct E <: Int
      f_b
  end

  #inheritence from any abstract class
  StructuralInheritance.@protostruct struct F <: Real
      f_b
  end

  @test F(3).f_b == 3

  StructuralInheritance.@protostruct struct G <: B
      f_e::Float32
      f_f
  end

  @test fieldnames(G) == (:f_a,:f_b,:f_c,:f_d,:f_e,:f_f) #Test names of fields and order
  @test fieldtype.(G,[1,2,3,4,5,6]) == [Int,Any,Float32,Any,Float32,Any]
  @test G <: ProtoG && G <: ProtoB && G <: ProtoA


#TEST MODULE SANITIZATION FACILITY
module MA
  using Main.StructuralInheritance
  @protostruct struct A
    f_a_MA::Int
  end
  @protostruct struct B <: A
    f_a::A
  end
end

@protostruct struct H <: MA.B
  f_c::A
end

@protostruct struct H_2 <: MA.B
  f_c::MA.A
end

@test fieldnames(H_2) == (:f_a_MA,:f_a,:f_c)
@test fieldtype.(H_2,[1,2,3]) == [Int,MA.A,MA.A]

@test fieldnames(H) == (:f_a_MA,:f_a,:f_c)
@test fieldtype.(H,[1,2,3]) == [Int,MA.A,A]

@test StructuralInheritance.@protostruct(struct I <: A
    f_c::Float32
    f_d
end,"ProtoType") == ProtoTypeI

@test StructuralInheritance.@protostruct(struct J
    f_c::Float32
    f_d
end,:("ProtoType")) == ProtoTypeJ

@test_throws Any StructuralInheritance.@protostruct(struct K
    f_c::Float32
    f_d
end,"") == ProtoTypeK

#TEST PARAMETRIC INHERITENCE
module M_paramfields
    using Main.StructuralInheritance
    using Test
    @test @protostruct(struct A
        f_a::Core.Main.Base.Array{Float16,3}
    end) == ProtoA

    @test @protostruct(struct B <: A
        f_b::Complex{Float64}
    end) == ProtoB

    @test @protostruct(struct C <: B
        field_c::Array{Float32,4}
    end) == ProtoC

    @test fieldnames(C) == (:f_a,:f_b,:field_c)
    @test fieldtype.(C,[1,2,3]) == [Array{Float16,3},Complex{Float64},Array{Float32,4}]

    @protostruct struct D{X,B}
        f1::Array{X,B}
    end

    @protostruct struct E{T} <: D{Complex{T},2} end

    @protostruct struct F <: E{Int} end

    @test fieldnames(F) == (:f1,)
    @test fieldtype(F,1) == Array{Complex{Int64},2}
end



@test StructuralInheritance.@protostruct(struct K{T}
    f_a::T
end) == ProtoK

@test fieldtype(K{Int},1) == Int
@test fieldnames(K) == (:f_a,)


@test @protostruct(struct L{T} <: K{T}
    f_b::T
end) == ProtoL

@test fieldnames(L) == (:f_a,:f_b)
@test fieldtype.(L{Real},[1,2]) == [Real,Real]

@test @protostruct(struct N{R} <: K{R}
    f_b::R
end) == ProtoN


@test fieldnames(N) == (:f_a,:f_b)
@test fieldtype.(N{Complex},[1,2]) == [Complex,Complex]


@protostruct mutable struct BB
        f_a::Int
end

@protostruct mutable struct CC{A,BA} <: BB
    f_b::A
    f_c::BA
end


@test @protostruct( mutable struct DD{C,D} <: CC{D,Complex}
    f_d::C
end) == ProtoDD

@test @protostruct( mutable struct DD_2{C,D} <: CC{D,Complex{C}}
    f_d::C
end) == ProtoDD_2

@test @protostruct( mutable struct O <: DD{Int,Real}
    f_e::Complex
end) == ProtoO

@test @protostruct( mutable struct O_2 <: DD_2{Int,Real}
    f_e::Complex
end) == ProtoO_2

@test fieldnames(O) == (:f_a,:f_b,:f_c,:f_d,:f_e)
@test fieldtype.(O,[1,2,3,4,5]) == [Int,Real,Complex,Int,Complex]

@test fieldnames(O_2) == (:f_a,:f_b,:f_c,:f_d,:f_e)
@test fieldtype.(O_2,[1,2,3,4,5]) == [Int,Real,Complex{Int},Int,Complex]

module M_literal_func
    using Main.StructuralInheritance
    f(x) = Int
    f(x::Array) = length(x) == 2 ? Complex : Array
    @protostruct struct P
        f1::f(2)
        f2::f([])
        f3::f([1,2])
    end
end

@protostruct struct Q <: M_literal_func.P
    f4::Real
end

@test fieldnames(Q) == (:f1,:f2,:f3,:f4)
@test fieldtype.(Q,[1,2,3,4]) == [Int,Array,Complex,Real]

@test SI.totuple(4 + 5im) == (4,5)
@test SI.totuple(4) == (4,)

@protostruct struct R
    ff::Int
    sf
    R(x) = new(x,x^2)
    R(x,y) = new(x,y)
end

@protostruct struct S <: R
    tf::Int
end

S(x) = S(SI.totuple(R(x))...,x^3)

@test S(2) == S(2,4,8)

module mutabilityTestings
    using Main.StructuralInheritance
    using Test
    @protostruct struct A_im; end;
    @protostruct mutable struct A_m; end;
    @test_throws Any @protostruct mutable struct B_m <: A_im; end;
    @test_throws Any @protostruct struct B_im <: A_m; end;
    @test_throws Any @protostruct mutable struct B_m <: A_im
    end "Proto" "hat"

    @test @protostruct(mutable struct B_m <: A_im end,
                       "Sudo",
                       true) == SudoB_m
    @test @protostruct(struct B_im <: A_m; end,
                       "A",
                       true) == AB_im;
end



module macroLiteral
    using Main.StructuralInheritance
    using Test
    module Inner
        using Main.StructuralInheritance

        macro m(x)
             x
         end
         @protostruct struct A
             f::@m(Int)
         end
    end

    @protostruct struct B <: Inner.A
        f2::Inner.@m Float64
    end

    @test fieldnames(B) == (:f,:f2)
    @test fieldtype.(B,[1,2]) == [Int,Float64]

end

module ParametricTypeConstraints
    using Test
    using Main.StructuralInheritance

    @protostruct struct A{T<:Number}
        ffa::T
    end

    @test_throws Any A("hmm")

    @test A(3).ffa == 3

    @protostruct struct B{T<:Real,A<:Array} <: A{T}
        ffb::A
    end

    @protostruct struct C{T,A,L} <: B{T,A}
        ffc::L
    end

    @test_throws Any C(4+3im,[],"huh")
    @test_throws Any C(2,4,"huh")

    @test StructuralInheritance.totuple(C(1,[4],"huh")) == (1,[4],"huh")

end

module MacroFields
    using Test
    using Main.StructuralInheritance

    macro e1()
        esc(quote f1::Int; f2::X; end)
    end

    macro e2()
        esc(quote f4::K; end)
    end

    macro e3()
        esc(quote; f5::Int; f6::T; end)
    end

    @protostruct struct A{X}
        @e1
    end

    @protostruct struct B{X,T,K} <: A{Array{X,T}}
        @e2()
    end

    @protostruct struct C{T} <: B{Complex{T},2,T}
        @e3
    end

    @protostruct struct D <: C{Float32} end

    fieldnames(D) == (:f1,:f2,:f4,:f5,:f6)
    fieldtype.(D,(1,2,3,4,5)) == (Int,Array{Complex{Float32},2},Float32,Int,Float32)
end

#whitebox tests
@test SI.qualifyname(Int64) == :(Core.Int64)
@test SI.inherits(:x) == false
@test SI.inherits(:(x <: y)) == true
@test SI.inherits(:(x{z} <: y)) == true
@test SI.inherits(:(x{y})) == false

@test SI.qualifyname(:Xib,[:c,:v,:l,:k]) == :(c.v.l.k.Xib)
@test SI.qualifyname(:(M.P.Xib),[:c,:v,:l,:k]) == :(c.v.l.k.M.P.Xib)

@test SI.detypevar(:x) == :x

@test SI.iscontainerlike(:(x.v)) == false
@test SI.iscontainerlike(4) == false

@test SI.ispath(:x) == false
@test SI.ispath(:(x.c)) == true


@test SI.flattenfields("str") == SI.FieldType[]
@test SI.flattenfields(:x) == SI.FieldType[:x]
