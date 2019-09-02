# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module FigurativeNumbers

export ModuleFigurativeNumbers
export PolygonalNumber, PyramidalNumber
export V014107, V095794, V067998, V080956, V001477, V000217, V000290
export V000326, V000384, V000566, V000567, V001106, V001107
export V005564, V058373, V254749, V000292, V000330, V002411, V002412
export V002413, V002414, V007584, V007585

"""
* PolygonalNumber, PyramidalNumber, V014107, V095794, V067998, V080956, V001477, V000217, V000290, V000326, V000384, V000566, V000567, V001106, V001107, V005564, V058373, V254749, V000292, V000330, V002411, V002412, V002413, V002414, V007584, V007585
"""
const ModuleFigurativeNumbers = ""

"""
Return the polygonal number with shape k.
"""
function PolygonalNumber(n, k)
    s = div(n^2 * (k - 2) - n * (k - 4), 2)
    k < 2 ? -s : s
end

"""
Return the pyramidal number with shape k.
"""
function PyramidalNumber(n, k)
    s = div(3 * n^2 + n^3 * (k - 2) - n * (k - 5), 6)
    k < 2 ? -s : s
end

"""
Return the polygonal numbers of shape -2.
"""
V014107(n) = PolygonalNumber(n, -2)
"""
Return the polygonal numbers of shape -1.
"""
V095794(n) = PolygonalNumber(n, -1)
"""
Return the polygonal numbers of shape 0.
"""
V067998(n) = PolygonalNumber(n, 0)
"""
Return the polygonal numbers of shape 1.
"""
V080956(n) = PolygonalNumber(n, 1)
"""
Return the polygonal numbers of shape 2 (these are the natural numbers).
"""
V001477(n) = PolygonalNumber(n, 2)
"""
Return the polygonal numbers of shape 3 (the triangular numbers).
"""
V000217(n) = PolygonalNumber(n, 3)
"""
Return the polygonal numbers of shape 4 (the squares).
"""
V000290(n) = PolygonalNumber(n, 4)
"""
Return the polygonal numbers of shape 5 (the pentagonal numbers).
"""
V000326(n) = PolygonalNumber(n, 5)
"""
Return the polygonal numbers of shape 6 (the hexagonal numbers).
"""
V000384(n) = PolygonalNumber(n, 6)
"""
Return the polygonal numbers of shape 7 (the heptagonal numbers).
"""
V000566(n) = PolygonalNumber(n, 7)
"""
Return the polygonal numbers of shape 8 (the octagonal numbers).
"""
V000567(n) = PolygonalNumber(n, 8)
"""
Return the polygonal numbers of shape 9 (the nonagonal numbers).
"""
V001106(n) = PolygonalNumber(n, 9)
"""
Return the polygonal numbers of shape 10 (decagonal numbers).
"""
V001107(n) = PolygonalNumber(n, 10)

"""
Return the pyramidal numbers of shape -1.
"""
V005564(n) = PyramidalNumber(n, -1)
"""
Return the pyramidal numbers of shape 0.
"""
V058373(n) = PyramidalNumber(n, 0)
"""
Return the pyramidal numbers of shape 1.
"""
V254749(n) = PyramidalNumber(n, 1)
#"""
#Return the pyramidal numbers of shape 2 (triangular numbers).
#"""
#V000217(n) = PyramidalNumber(n, 2)
"""
Return the pyramidal numbers of shape 3 (tetrahedral numbers).
"""
V000292(n) = PyramidalNumber(n, 3)
"""
Return the pyramidal numbers of shape 4 (square pyramidal numbers).
"""
V000330(n) = PyramidalNumber(n, 4)
"""
Return the pyramidal numbers of shape 5 (pentagonal pyramidal numbers).
"""
V002411(n) = PyramidalNumber(n, 5)
"""
Return the pyramidal numbers of shape 6 (hexagonal pyramidal numbers).
"""
V002412(n) = PyramidalNumber(n, 6)
"""
Return the pyramidal numbers of shape 7 (heptagonal pyramidal numbers).
"""
V002413(n) = PyramidalNumber(n, 7)
"""
Return the pyramidal numbers of shape 8 (octagonal pyramidal numbers).
"""
V002414(n) = PyramidalNumber(n, 8)
"""
Return the pyramidal numbers of shape 9 (enneagonal pyramidal numbers).
"""
V007584(n) = PyramidalNumber(n, 9)
"""
Return the pyramidal numbers of shape 10 (decagonal pyramidal numbers).
"""
V007585(n) = PyramidalNumber(n, 10)

#START-TEST-########################################################

using Test, SeqTests

function test()

    @testset "Figurative" begin
        @test V002411(1000) == 500500000

        if is_oeis_installed()

            V = [V014107, V067998, V001477, V000217, V000290, V000326,
                V000384, V000566, V000567, V001106, V001107, V000292,
                V000330, V002411, V002412, V002413, V007584, V007585]
                # V080956, V095794, V005564, V058373, V254749, V002414
            for v in V  SeqTest(v, 'V') end
        end
    end
end

function demo()
    for k in -2:10
        V = [PolygonalNumber(n, k) for n in 0:9]
        println(k, " ", V)
    end

    for k in -2:10
        V = [PyramidalNumber(n, k) for n in 0:9]
        println(k, " ", V)
    end
end

"""
"""
function perf()
    @time (for n in 1:1000 V000326(n) end)
end

function main()
    test()
    demo()
    perf()
end

main()

#-2 [0, -1,  2, 9, 20, 35,  54,  77, 104, 135]
#-1 [0, -1,  1, 6, 14, 25,  39,  56,  76,  99]
# 0 [0, -1,  0, 3,  8, 15,  24,  35,  48,  63]
# 1 [0, -1, -1, 0,  2,  5,   9,  14,  20,  27]
# --------------------------------------------
# 2 [0, 1,  2,  3,  4,  5,   6,   7,   8,   9]
# 3 [0, 1,  3,  6, 10, 15,  21,  28,  36,  45]
# 4 [0, 1,  4,  9, 16, 25,  36,  49,  64,  81]
# 5 [0, 1,  5, 12, 22, 35,  51,  70,  92, 117]
# 6 [0, 1,  6, 15, 28, 45,  66,  91, 120, 153]
# 7 [0, 1,  7, 18, 34, 55,  81, 112, 148, 189]
# 8 [0, 1,  8, 21, 40, 65,  96, 133, 176, 225]
# 9 [0, 1,  9, 24, 46, 75, 111, 154, 204, 261]
#10 [0, 1, 10, 27, 52, 85, 126, 175, 232, 297]

# ==============================================
# -2 [0,-1,  1, 10, 30,  65, 119, 196, 300,  435]
# -1 [0,-1,  0,  6, 20,  45,  84, 140, 216,  315] V005564
#  0 [0,-1, -1,  2, 10,  25,  49,  84, 132,  195] V058373
#  1 [0,-1, -2, -2,  0,   5,  14,  28,  48,   75] V254749
# -----------------------------------------------
#  2 [0, 1,  3,  6, 10,  15,  21,  28,  36,   45] V000217
#  3 [0, 1,  4, 10, 20,  35,  56,  84, 120,  165] V000292
#  4 [0, 1,  5, 14, 30,  55,  91, 140, 204,  285] V000330
#  5 [0, 1,  6, 18, 40,  75, 126, 196, 288,  405] V002411
#  6 [0, 1,  7, 22, 50,  95, 161, 252, 372,  525] V002412
#  7 [0, 1,  8, 26, 60, 115, 196, 308, 456,  645] V002413
#  8 [0, 1,  9, 30, 70, 135, 231, 364, 540,  765] V002414
#  9 [0, 1, 10, 34, 80, 155, 266, 420, 624,  885] V007584
# 10 [0, 1, 11, 38, 90, 175, 301, 476, 708, 1005] V007585

end # module
