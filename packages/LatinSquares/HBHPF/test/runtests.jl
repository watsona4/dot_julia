using LatinSquares, Test

A,B = ortho_latin(4)
@test check_ortho(A,B)
A,B = ortho_latin(5)
@test check_ortho(A,B)
