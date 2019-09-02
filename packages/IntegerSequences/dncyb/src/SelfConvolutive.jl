# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module SelfConvolutive

using Nemo

export ModuleSelfConvolutive, SelfConvRec
export L000698, L001710, L003319, L005411, L005412, L006012, L006318
export L047891, L062980, L082298, L082301, L082302, L105523, L107716
export L111529, L111530, L111531, L111532, L111533, L146559, L167872

"""
Some exactly solvable self-convolutive recurrences.

* SelfConvRec, L000698, L001710, L003319, L005411, L005412, L006012, L006318
L047891, L062980, L082298, L082301, L082302, L105523, L107716
L111529, L111530, L111531, L111532, L111533, L146559, L167872
"""
const ModuleSelfConvolutive = ""

# R. J. Martin and M. J. Kearney,
# An exactly solvable self-convolutive recurrence
# http://arXiv.org/abs/1103.4936
# Integral representation of certain combinatorial recurrences
# see also http://oeis.org/A172455

Convolution(A, n) = sum(A[j+1] * A[n-j+1] for j in 0:n)

"""
An exactly solvable self-convolutive recurrence studied by R. J. Martin and M. J. Kearney.
"""
function SelfConvRec(len, a, b, c)
    A = fill(ZZ(0), len)
    len == 0 && return A
    A[1] = 1

    for n in 1:len - 1
        A[n+1] = (a * (n + 1) + b) * A[n] + c * Convolution(A, n-1)
    end
    A
end

# """
# Return the powers of 2.
# """
# L000079(len::Int) = SelfConvRec(len, 1, 1, -1)
# """
# Return the Catalan numbers.
# """
# L000108(len::Int) = SelfConvRec(len, 0, 0, 1)
# """
# Return the factorial numbers.
# """
# L000142(len::Int) = SelfConvRec(len, 1, -1, 0)
# """
# Return the powers of 3.
# """
# L000244(len::Int) = SelfConvRec(len, 2, 1, -2)
# """
# Return the powers of 5.
# """
# L000351(len::Int) = SelfConvRec(len, 4, 1, -4)
# """
# Return the powers of 6.
# """
# L000400(len::Int) = SelfConvRec(len, 5, 1, -5)
# """
# Return the powers of 7.
# """
# L000420(len::Int) = SelfConvRec(len, 6, 1, -6)

"""
Return the number of indecomposable perfect matchings on ``[2n]``.
"""
L000698(len::Int) = SelfConvRec(len, 2, -3, 1)
"""
Return the order of alternating group ``A_n``, or number of even permutations of ``n`` letters.
"""
L001710(len::Int) = SelfConvRec(len, 1, 1, 0)

# """
# Return n!/3!.
# """
# L001715(len::Int) = SelfConvRec(len, 1, 2, 0)
# """
# Return n!/4!.
# """
# L001720(len::Int) = SelfConvRec(len, 1, 3, 0)
# """
# Return n!/5!.
# """
# L001725(len::Int) = SelfConvRec(len, 1, 4, 0)
# """
# Return n!/6!.
# """
# L001730(len::Int) = SelfConvRec(len, 1, 5, 0)

"""
Return the number of connected permutations of ``[1..n]``. Also called indecomposable permutations.
"""
L003319(len::Int) = SelfConvRec(len, 1, -2, 1)
"""
Return the number of non-vanishing Feynman diagrams of order ``2n`` for the electron or the photon propagators in quantum electrodynamics.
"""
L005411(len::Int) = SelfConvRec(len, 2, -4, 1)
"""
Return the number of non-vanishing Feynman diagrams of order ``2n`` for the vacuum polarization in quantum electrodynamics.
"""
L005412(len::Int) = SelfConvRec(len, 2, -2, 1)
"""
Counting some sets of permutations.
"""
L006012(len::Int) = SelfConvRec(len, -1, 2, 2)
"""
Return the large Schröder numbers.
"""
L006318(len::Int) = SelfConvRec(len, 0, 1, 1)
"""
Return the number of planar rooted trees with ``n`` nodes and tricolored end nodes.
"""
L047891(len::Int) = SelfConvRec(len, 0, 2, 1)
# """
# Return (n+7)!/7!.
# """
# L049388(len::Int) = SelfConvRec(len, 1, 6, 0)
# """
# Return (3*n+4)!!!/4!!!.
# """
# L051604(len::Int) = SelfConvRec(len, 3, 1, 0)
# """
# Return (3*n+5)!!!/5!!!.
# """
# L051605(len::Int) = SelfConvRec(len, 3, 2, 0)
# """
# Return (3*n+6)!!!/6!!!.
# """
# L051606(len::Int) = SelfConvRec(len, 3, 3, 0)
# """
# Return (3*n+7)!!!/7!!!.
# """
# L051607(len::Int) = SelfConvRec(len, 3, 4, 0)
# """
# Return (3*n+8)!!!/8!!!.
# """
# L051608(len::Int) = SelfConvRec(len, 3, 5, 0)
# """
# Return (3*n+9)!!!/9!!!.
# """
# L051609(len::Int) = SelfConvRec(len, 3, 6, 0)
# """
# Return (4*n+5)(!^4)/5(!^4).
# """
# L051617(len::Int) = SelfConvRec(len, 4, 1, 0)
# """
# Return  (4*n+6)(!^4)/6(!^4).
# """
# L051618(len::Int) = SelfConvRec(len, 4, 2, 0)
# """
# Return (4*n+7)(!^4)/7(!^4).
# """
# L051619(len::Int) = SelfConvRec(len, 4, 3, 0)
# """
# Return (4*n+8)(!^4)/8(!^4).
# """
# L051620(len::Int) = SelfConvRec(len, 4, 4, 0)
# """
# Return (4*n+9)(!^4)/9(!^4).
# """
# L051621(len::Int) = SelfConvRec(len, 4, 5, 0)
# """
# Return (4*n+10)(!^4)/10(!^4).
# """
# L051622(len::Int) = SelfConvRec(len, 4, 6, 0)
# """
# Return (5*n+6)(!^5)/6.
# """
# L051687(len::Int) = SelfConvRec(len, 5, 1, 0)
# """
# Return (5*n+7)(!^5)/7(!^5).
# """
# L051688(len::Int) = SelfConvRec(len, 5, 2, 0)
# """
# Return (5*n+8)(!^5)/8(!^5).
# """
# L051689(len::Int) = SelfConvRec(len, 5, 3, 0)
# """
# Return (5*n+9)(!^5)/9(!^5).
# """
# L051690(len::Int) = SelfConvRec(len, 5, 4, 0)
# """
# Return (5*n+10)(!^5)/10(!^5).
# """
# L051691(len::Int) = SelfConvRec(len, 5, 5, 0)
# """
# Return ((6*n+7)(!^6))/7.
# """
# L053100(len::Int) = SelfConvRec(len, 6, 1, 0)
# """
# Return ((6*n+8)(!^6))/8(!^6).
# """
# L053101(len::Int) = SelfConvRec(len, 6, 2, 0)
# """
# Return ((6*n+9)(!^6))/9(!^6).
# """
# L053102(len::Int) = SelfConvRec(len, 6, 3, 0)
# """
# Return ((6*n+10)(!^6))/10(!^6).
# """
# L053103(len::Int) = SelfConvRec(len, 6, 4, 0)
# """
# Return ((7*n+8)(!^7))/8.
# """
# L053104(len::Int) = SelfConvRec(len, 7, 1, 0)
# """
# Return ((7*n+9)(!^7))/9(!^7).
# """
# L053105(len::Int) = SelfConvRec(len, 7, 2, 0)
# """
# Return ((7*n+10)(!^7))/10(1^7).
# """
# L053106(len::Int) = SelfConvRec(len, 7, 3, 0)

"""
Return the number of rooted unlabeled connected triangular maps on a compact closed oriented surface with ``2n`` faces.
"""
L062980(len::Int) = SelfConvRec(len, 6, -8, 1)
"""
Return the number of lattice paths from ``(0,0)`` to ``(n+1,n+1)`` that consist of steps ``(i,0)`` and ``(0,j)`` with ``i,j≥1`` and stay strictly below the diagonal line ``y=x`` except at the endpoints.
"""
L082298(len::Int) = SelfConvRec(len, 0, 3, 1)
"""
Return the number of Schröder paths of semilength n in which the (2,0)-steps come in 4 colors.
"""
L082301(len::Int) = SelfConvRec(len, 0, 4, 1)
"""
Return the coefficients in the expansion of ``(1-5x-√(25x^2-14x+1))/(2x)``.
"""
L082302(len::Int) = SelfConvRec(len, 0, 5, 1)

# """
# Return the coefficients in the expansion of ``(1-6x-√(36x^2-16x+1))/(2x)``.
# """
# L082305(len::Int) = SelfConvRec(len, 0, 6, 1)
# """
# Return the coefficients in the expansion of ``(1-7x-√(49x^2-18x+1))/(2x)``.
# """
# L082366(len::Int) = SelfConvRec(len, 0, 7, 1)
# """
# Return the coefficients in the expansion of ``(1-8x-√(64x^2-20x+1))/(2*x)``.
# """
# L082367(len::Int) = SelfConvRec(len, 0, 8, 1)

"""
Return the coefficients in the expansion of ``(1+2x-√(1+4x^2))/(2x)``.
"""
L105523(len::Int) = SelfConvRec(len, 0, -2, 1)
"""
A transform the of triple factorial numbers.
"""
L107716(len::Int) = SelfConvRec(len, 3, -4, 1)
"""
A convolutory inverse of the factorial sequence.
"""
L111529(len::Int) = SelfConvRec(len, 1, -3, 2)
"""
A convolutory inverse of the factorial sequence.
"""
L111530(len::Int) = SelfConvRec(len, 1, -4, 3)
"""
A convolutory inverse of the factorial sequence.
"""
L111531(len::Int) = SelfConvRec(len, 1, -5, 4)
"""
A convolutory inverse of the factorial sequence.
"""
L111532(len::Int) = SelfConvRec(len, 1, -6, 5)
"""
A convolutory inverse of the factorial sequence.
"""
L111533(len::Int) = SelfConvRec(len, 1, -7, 6)

#"""
#"""
#L111546(len::Int) = SelfConvRec(len, 1, 0, 1)
#"""
#"""
#L111556(len::Int) = SelfConvRec(len, 1, 1, 1)

"""
Return the expansion of ``(1-x)/(1 - 2x + 2x^2)``.
"""
L146559(len::Int) = SelfConvRec(len, 1, 1, -2)
"""
Return half the number of Feynman diagrams of order ``2(n+1)``, for the electron self-energy in quantum electrodynamics.
"""
L167872(len::Int) = SelfConvRec(len, 2, -3, 2)

# """
# """
# L172450(len::Int) = SelfConvRec(len, 2, 0, -1)
# """
# """
# L172455(len::Int) = SelfConvRec(len, 6, -4, -1)
# """
# """
# L172485(len::Int) = SelfConvRec(len, -1, -2, 3)
# """
# """
# L177354(len::Int) = SelfConvRec(len, 1, 2, 1)

#START-TEST-########################################################
using Test, SeqTests

function test()
    @testset "SelfConvRec" begin
        if is_oeis_installed()

            L = [L005411, L005412, L006012, L006318, L047891, L062980, L082298,
                L082301, L082302, L105523, L107716, L111529, L111530, L111531,
                L111532, L111533, L146559, L167872]
            SeqTest(L, 'L')
        end
    end
end

function demo()

    for n in 0:6 println(n, " ↦ ", L005411(n)) end

    f(len) = SelfConvRec(len, 2, -1, -1)
    println(f(11))
end

"""
L005411(500) :: 0.238653 seconds (252.99 k allocations: 3.887 MB)
"""
function perf()
    GC.gc()
    @time L005411(500)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=
L --> A000079
Nemo.fmpz[1, 2, 4, 8, 16, 32]
Nemo.fmpz[1, 2, 4, 8, 16, 32]
L --> A000108
Nemo.fmpz[1, 1, 2, 5, 14, 42]
Nemo.fmpz[1, 1, 2, 5, 14, 42]
L --> A000142
Nemo.fmpz[1, 1, 2, 6, 24, 120]
Nemo.fmpz[1, 1, 2, 6, 24, 120]
L --> A000244
Nemo.fmpz[1, 3, 9, 27, 81, 243]
Nemo.fmpz[1, 3, 9, 27, 81, 243]
L --> A000351
Nemo.fmpz[1, 5, 25, 125, 625, 3125]
Nemo.fmpz[1, 5, 25, 125, 625, 3125]
L --> A000400
Nemo.fmpz[1, 6, 36, 216, 1296, 7776]
Nemo.fmpz[1, 6, 36, 216, 1296, 7776]
L --> A000420
Nemo.fmpz[1, 7, 49, 343, 2401, 16807]
Nemo.fmpz[1, 7, 49, 343, 2401, 16807]
#############################
L --> A000698
Nemo.fmpz[1, 1, 2, 10, 74, 706]
Nemo.fmpz[1, 2, 10, 74, 706, 8162]
#####################
seq((n+2)!/2, n=0..9);
L --> A001710
Nemo.fmpz[1, 1, 1, 3, 12, 60]
Nemo.fmpz[1, 3, 12, 60, 360, 2520]
######################
L --> A001715
Nemo.fmpz[1, 4, 20, 120, 840, 6720]
Nemo.fmpz[1, 4, 20, 120, 840, 6720]
L --> A001720
Nemo.fmpz[1, 5, 30, 210, 1680, 15120]
Nemo.fmpz[1, 5, 30, 210, 1680, 15120]
L --> A001725
Nemo.fmpz[1, 6, 42, 336, 3024, 30240]
Nemo.fmpz[1, 6, 42, 336, 3024, 30240]
L --> A001730
Nemo.fmpz[1, 7, 56, 504, 5040, 55440]
Nemo.fmpz[1, 7, 56, 504, 5040, 55440]
##################
L --> A003319
Nemo.fmpz[0, 1, 1, 3, 13, 71]
Nemo.fmpz[1, 1, 3, 13, 71, 461]
##################
L --> A005411
Nemo.fmpz[1, 1, 4, 25, 208, 2146]
Nemo.fmpz[1, 1, 4, 25, 208, 2146]
L --> A005412
Nemo.fmpz[1, 3, 18, 153, 1638, 20898]
Nemo.fmpz[1, 3, 18, 153, 1638, 20898]
L --> A006012
Nemo.fmpz[1, 2, 6, 20, 68, 232]
Nemo.fmpz[1, 2, 6, 20, 68, 232]
L --> A006318
Nemo.fmpz[1, 2, 6, 22, 90, 394]
Nemo.fmpz[1, 2, 6, 22, 90, 394]
L --> A047891
Nemo.fmpz[1, 3, 12, 57, 300, 1686]
Nemo.fmpz[1, 3, 12, 57, 300, 1686]
L --> A049388
Nemo.fmpz[1, 8, 72, 720, 7920, 95040]
Nemo.fmpz[1, 8, 72, 720, 7920, 95040]
L --> A051604
Nemo.fmpz[1, 7, 70, 910, 14560, 276640]
Nemo.fmpz[1, 7, 70, 910, 14560, 276640]
L --> A051605
Nemo.fmpz[1, 8, 88, 1232, 20944, 418880]
Nemo.fmpz[1, 8, 88, 1232, 20944, 418880]
L --> A051606
Nemo.fmpz[1, 9, 108, 1620, 29160, 612360]
Nemo.fmpz[1, 9, 108, 1620, 29160, 612360]
L --> A051607
Nemo.fmpz[1, 10, 130, 2080, 39520, 869440]
Nemo.fmpz[1, 10, 130, 2080, 39520, 869440]
L --> A051608
Nemo.fmpz[1, 11, 154, 2618, 52360, 1204280]
Nemo.fmpz[1, 11, 154, 2618, 52360, 1204280]
L --> A051609
Nemo.fmpz[1, 12, 180, 3240, 68040, 1632960]
Nemo.fmpz[1, 12, 180, 3240, 68040, 1632960]
L --> A051617
Nemo.fmpz[1, 9, 117, 1989, 41769, 1044225]
Nemo.fmpz[1, 9, 117, 1989, 41769, 1044225]
L --> A051618
Nemo.fmpz[1, 10, 140, 2520, 55440, 1441440]
Nemo.fmpz[1, 10, 140, 2520, 55440, 1441440]
L --> A051619
Nemo.fmpz[1, 11, 165, 3135, 72105, 1946835]
Nemo.fmpz[1, 11, 165, 3135, 72105, 1946835]
L --> A051620
Nemo.fmpz[1, 12, 192, 3840, 92160, 2580480]
Nemo.fmpz[1, 12, 192, 3840, 92160, 2580480]
L --> A051621
Nemo.fmpz[1, 13, 221, 4641, 116025, 3364725]
Nemo.fmpz[1, 13, 221, 4641, 116025, 3364725]
L --> A051622
Nemo.fmpz[1, 14, 252, 5544, 144144, 4324320]
Nemo.fmpz[1, 14, 252, 5544, 144144, 4324320]
L --> A051687
Nemo.fmpz[1, 11, 176, 3696, 96096, 2978976]
Nemo.fmpz[1, 11, 176, 3696, 96096, 2978976]
L --> A051688
Nemo.fmpz[1, 12, 204, 4488, 121176, 3877632]
Nemo.fmpz[1, 12, 204, 4488, 121176, 3877632]
L --> A051689
Nemo.fmpz[1, 13, 234, 5382, 150696, 4972968]
Nemo.fmpz[1, 13, 234, 5382, 150696, 4972968]
L --> A051690
Nemo.fmpz[1, 14, 266, 6384, 185136, 6294624]
Nemo.fmpz[1, 14, 266, 6384, 185136, 6294624]
L --> A051691
Nemo.fmpz[1, 15, 300, 7500, 225000, 7875000]
Nemo.fmpz[1, 15, 300, 7500, 225000, 7875000]
L --> A053100
Nemo.fmpz[1, 13, 247, 6175, 191425, 7082725]
Nemo.fmpz[1, 13, 247, 6175, 191425, 7082725]
L --> A053101
Nemo.fmpz[1, 14, 280, 7280, 232960, 8852480]
Nemo.fmpz[1, 14, 280, 7280, 232960, 8852480]
L --> A053102
Nemo.fmpz[1, 15, 315, 8505, 280665, 10945935]
Nemo.fmpz[1, 15, 315, 8505, 280665, 10945935]
L --> A053103
Nemo.fmpz[1, 16, 352, 9856, 335104, 13404160]
Nemo.fmpz[1, 16, 352, 9856, 335104, 13404160]
L --> A053104
Nemo.fmpz[1, 15, 330, 9570, 344520, 14814360]
Nemo.fmpz[1, 15, 330, 9570, 344520, 14814360]
L --> A053105
Nemo.fmpz[1, 16, 368, 11040, 408480, 17973120]
Nemo.fmpz[1, 16, 368, 11040, 408480, 17973120]
L --> A053106
Nemo.fmpz[1, 17, 408, 12648, 480624, 21628080]
Nemo.fmpz[1, 17, 408, 12648, 480624, 21628080]
L --> A062980
Nemo.fmpz[1, 5, 60, 1105, 27120, 828250]
Nemo.fmpz[1, 5, 60, 1105, 27120, 828250]
L --> A082298
Nemo.fmpz[1, 4, 20, 116, 740, 5028]
Nemo.fmpz[1, 4, 20, 116, 740, 5028]
L --> A082301
Nemo.fmpz[1, 5, 30, 205, 1530, 12130]
Nemo.fmpz[1, 5, 30, 205, 1530, 12130]
L --> A082302
Nemo.fmpz[1, 6, 42, 330, 2814, 25422]
Nemo.fmpz[1, 6, 42, 330, 2814, 25422]
L --> A082305
Nemo.fmpz[1, 7, 56, 497, 4760, 48174]
Nemo.fmpz[1, 7, 56, 497, 4760, 48174]
L --> A082366
Nemo.fmpz[1, 8, 72, 712, 7560, 84616]
Nemo.fmpz[1, 8, 72, 712, 7560, 84616]
L --> A082367
Nemo.fmpz[1, 9, 90, 981, 11430, 140058]
Nemo.fmpz[1, 9, 90, 981, 11430, 140058]
L --> A105523
Nemo.fmpz[1, -1, 0, 1, 0, -2]
Nemo.fmpz[1, -1, 0, 1, 0, -2]
L --> A107716
Nemo.fmpz[1, 3, 21, 219, 2973, 49323]
Nemo.fmpz[1, 3, 21, 219, 2973, 49323]
L --> A111529
Nemo.fmpz[1, 1, 4, 22, 148, 1156]
Nemo.fmpz[1, 1, 4, 22, 148, 1156]
L --> A111530
Nemo.fmpz[1, 1, 5, 33, 261, 2361]
Nemo.fmpz[1, 1, 5, 33, 261, 2361]
L --> A111531
Nemo.fmpz[1, 1, 6, 46, 416, 4256]
Nemo.fmpz[1, 1, 6, 46, 416, 4256]
L --> A111532
Nemo.fmpz[1, 1, 7, 61, 619, 7045]
Nemo.fmpz[1, 1, 7, 61, 619, 7045]
L --> A111533
Nemo.fmpz[1, 1, 8, 78, 876, 10956]
Nemo.fmpz[1, 1, 8, 78, 876, 10956]
L --> A111546
Nemo.fmpz[1, 3, 15, 99, 783, 7083]
Nemo.fmpz[1, 3, 15, 99, 783, 7083]
L --> A111556
Nemo.fmpz[1, 4, 24, 184, 1664, 17024]
Nemo.fmpz[1, 4, 24, 184, 1664, 17024]
L --> A146559
Nemo.fmpz[1, 1, 0, -2, -4, -4]
Nemo.fmpz[1, 1, 0, -2, -4, -4]
L --> A167872
Nemo.fmpz[1, 3, 21, 207, 2529, 36243]
Nemo.fmpz[1, 3, 21, 207, 2529, 36243]
L --> A172450
Nemo.fmpz[1, 3, 12, 63, 432, 3798]
Nemo.fmpz[1, 3, 12, 63, 432, 3798]
L --> A172485
Nemo.fmpz[1, -1, -1, 3, 3, -21]
Nemo.fmpz[1, -1, -1, 3, 3, -21]
#################################
L --> A177354
Nemo.fmpz[5, 35, 305, 3095, 35225, 439775]
Nemo.fmpz[1, 5, 35, 305, 3095, 35225]
###########################

L = [ L000079, L000108, L000142, L000244, L000351, L000400,
 L000420, L001715, L001720, L001725, L001730,
 L005411, L005412, L006012, L006318, L047891, L049388, L051604,
 L051605, L051606, L051607, L051608, L051609, L051617, L051618,
 L051619, L051620, L051621, L051622, L051687, L051688, L051689,
 L051690, L051691, L053100, L053101, L053102, L053103, L053104,
 L053105, L053106, L062980, L082298, L082301, L082302, L082305,
 L082366, L082367, L105523, L107716, L111529, L111530, L111531,
 L111532, L111533, L111546, L111556, L146559, L167872,
 L172450, L172485 ]
# L000698, L001710, L003319, L177354
SeqTest(L, 'L')

=#
