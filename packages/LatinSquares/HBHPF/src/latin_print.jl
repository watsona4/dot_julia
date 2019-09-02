# tools for displaying latin squares

# alphabets

abc = [ "$ch" for ch in 'a':'z']
ABC = uppercase.(abc)
greek = [ "$(Char(t))" for t in 945:969 if t != 962 ]
GREEK = uppercase.(greek)

export print_latin

"""
`print_latin(A)` prints out the Latin square `A` using uppercase
Latin letters.

`print_latin(A,B)` prints out the pair of (presumably orthogonal)
Latin squares using upper case Latin letters for `A` and lower case Greek
letters for `B`.

Both versions permit alternate character sets:
* `print_latin(A,charlist)`
* `print_latin(A,B,charlist1,charlist2)`

The following pre-built character sets are available:
* `LatinSquares.abc`: lower case Latin letters
* `LatinSquares.ABC`: upper case Latin letters
* `LatinSquares.greek`: lower case Greek letters
* `LatinSquares.GREEK`: upper case Greek letters 
"""

function print_latin(A::Matrix{Int}, chars::Array{String,1}=ABC)
    r,c = size(A)
    for i=1:r
        for j=1:c
            print(chars[A[i,j]])
            if j < c
                print(" ")
            else
                println()
            end
        end
    end
    nothing
end


function print_latin(A::Matrix{Int}, B::Matrix{Int}, chars1::Array{String}=ABC, chars2::Array{String}=greek)
    r,c = size(A)
    for i=1:r
        for j=1:c
            print(chars1[A[i,j]]*chars2[B[i,j]])
            if j<c
                print(" ")
            else
                println()
            end
        end
    end
    nothing
end
