# StaticMaps/Masks.jl
#
# MIT License
#
# Copyright (c) 2019 Brandon Gomes
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


"""
    Masks

...
"""
baremodule Masks

import Base: |, &

include("base.jl")

export StaticMask, apply, MaskNone, MaskAll, OR, AND


"""
    StaticMask

...
"""
abstract type StaticMask{F, Args} <: BroadcastedMap{F, Args} end


"""
    apply(::Type{<: StaticMask}, ::AbstractArray)

...
"""
apply(M::Type{<: StaticMask}, array::AbstractArray) = array[M(array)]


"""
    MaskNone

...
"""
abstract type MaskNone <: StaticMask{x -> true, ()} end


"""
    MaskAll

...
"""
abstract type MaskAll <: StaticMask{x -> false, ()} end


"""
    OR{A, B}

...
"""
abstract type OR{A <: StaticMask, B <: StaticMask} <: AbstractStaticMap end


"""
    AND{A, B}

...
"""
abstract type AND{A <: StaticMask, B <: StaticMask} <: AbstractStaticMap end


"""
    A | B

...
"""
Base.:|(A::Type{AA}, B::Type{BB}) where {AA <: StaticMask, BB <: StaticMask} = OR{A, B}


"""
    A & B

...
"""
Base.:&(A::Type{AA}, B::Type{BB}) where {AA <: StaticMask, BB <: StaticMask} = AND{A, B}


"""
    MaskNone | B === MaskNone

...
"""
Base.:|(A::Type{AA}, B::Type{BB}) where {AA <: MaskNone, BB <: StaticMask} = A


"""
    A | MaskNone === MaskNone

...
"""
Base.:|(A::Type{AA}, B::Type{BB}) where {AA <: StaticMask, BB <: MaskNone} = B


"""
    MaskAll | B === B

...
"""
Base.:|(A::Type{AA}, B::Type{BB}) where {AA <: MaskAll, BB <: StaticMask} = B


"""
    A | MaskAll === A

...
"""
Base.:|(A::Type{AA}, B::Type{BB}) where {AA <: StaticMask, BB <: MaskAll} = A


"""
    MaskNone & B === B

...
"""
Base.:&(A::Type{AA}, B::Type{BB}) where {AA <: MaskNone, BB <: StaticMask} = B


"""
    A & MaskNone === A

...
"""
Base.:&(A::Type{AA}, B::Type{BB}) where {AA <: StaticMask, BB <: MaskNone} = A


"""
    MaskAll & B === MaskAll

...
"""
Base.:&(A::Type{AA}, B::Type{BB}) where {AA <: MaskAll, BB <: StaticMask} = A


"""
    A & MaskAll === MaskAll

...
"""
Base.:&(A::Type{AA}, B::Type{BB}) where {AA <: StaticMask, BB <: MaskAll} = B


"""
    MaskNone | MaskAll === MaskNone

...
"""
Base.:|(A::Type{AA}, B::Type{BB}) where {AA <: MaskNone, BB <: MaskAll} = A


"""
    MaskAll | MaskNone === MaskNone

...
"""
Base.:|(A::Type{AA}, B::Type{BB}) where {AA <: MaskAll, BB <: MaskNone} = B


"""
    MaskNone & MaskAll === MaskAll

...
"""
Base.:&(A::Type{AA}, B::Type{BB}) where {AA <: MaskNone, BB <: MaskAll} = B


"""
    MaskAll & MaskNone === MaskAll

...
"""
Base.:&(A::Type{AA}, B::Type{BB}) where {AA <: MaskAll, BB <: MaskNone} = A


"""
    OR{A, B}(::AbstractArray)

...
"""
(::Type{<:OR{A, B}})(array::AbstractArray) where {A <: StaticMask, B <: StaticMask} = broadcast(|, A(array), B(array))


"""
    AND{A, B}(::AbstractArray)

...
"""
(::Type{<:AND{A, B}})(array::AbstractArray) where {A <: StaticMask, B <: StaticMask} = broadcast(&, A(array), B(array))


"""
    ComparisonMask{CMP, V}

...
"""
abstract type ComparisonMask{CMP, V} <: StaticMask{CMP, (V)} end


"""
    EQ{V}

...
"""
const EQ = ComparisonMask{==}


"""
    NEQ{V}

...
"""
const NEQ = ComparisonMask{!=}


"""
    LT{V}

...
"""
const LT = ComparisonMask{<}


"""
    LEQ

...
"""
const LEQ = ComparisonMask{<=}


"""
    GT{V}

...
"""
const GT = ComparisonMask{>}


"""
    GEQ{V}

...
"""
const GEQ = ComparisonMask{>=}


end # baremodule Masks