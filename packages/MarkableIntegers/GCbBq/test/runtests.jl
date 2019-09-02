using MarkableIntegers
using Test

pos1, pos2 = Int16( 1),  2
neg1, neg2 = Int16(-1), -2

pos1_nomark, pos2_nomark = Unmarked(pos1), Unmarked(pos2)
neg1_nomark, neg2_nomark = Unmarked(neg1), Unmarked(neg2)

pos1_marked, pos2_marked = Marked(pos1), Marked(pos2_nomark)
neg1_marked, neg2_marked = Marked(neg1), Marked(neg2_nomark)



@test ismarked(pos1)        == false
@test ismarked(pos1_nomark) == false
@test ismarked(pos1_marked) == true

@test pos2        == pos2_nomark
@test pos2        == pos2_marked
@test pos2_nomark == pos2_marked

@test pos2        == pos2_nomark
@test pos2        == pos2_marked
@test pos2_nomark == pos2_marked


@test isless(pos1, pos2_nomark)
@test isless(pos1, pos2_marked)
@test isless(pos1_nomark, pos2_nomark)
@test isless(pos1_nomark, pos2_marked)
@test isless(pos1_marked, pos2_nomark)
@test isless(pos1_marked, pos2_marked)

@test isless(neg2_nomark, neg1)
@test isless(neg2_marked, neg1)
@test isless(neg2_nomark, neg1_nomark)
@test isless(neg2_marked, neg1_nomark)
@test isless(neg2_nomark, neg1_marked)
@test isless(neg2_marked, neg1_marked)

@test isequal(pos2       , pos2_nomark)
@test isequal(pos2       , pos2_marked)
@test isequal(pos2_nomark, pos2_marked)
@test isequal(pos2_nomark, pos2)
@test isequal(pos2_marked, pos2)
@test isequal(pos2_marked, pos2_marked)

@test !isless(pos2       , pos2_nomark)
@test !isless(pos2       , pos2_marked)
@test !isless(pos2_nomark, pos2_marked)
@test !isless(pos2_nomark, pos2)
@test !isless(pos2_marked, pos2)
@test !isless(pos2_marked, pos2_marked)

pos3_nomark = pos1_nomark + pos2_nomark
pos3_marked = pos1_nomark + pos2_marked
@test !ismarked(pos3_nomark)
@test ismarked(pos3_marked)
@test pos3_nomark == pos3_marked
@test pos3_nomark == 3

@test pos2_nomark * neg2_nomark == -4
tst = div(pos3_nomark, pos2_marked)
@test ismarked(tst)
@test tst == div(3,2)
tst = fld(pos3_nomark, pos2_marked)
@test ismarked(tst)
@test tst == fld(3,2)
tst = cld(pos3_nomark, pos2_nomark)
@test isunmarked(tst)
@test tst == cld(3,2)
tst = mod(pos3_nomark, pos2_marked)
@test ismarked(tst)
@test tst == mod(3,2)
tst = rem(pos3_nomark, pos2_nomark)
@test isunmarked(tst)
@test tst == rem(3,2)

tst = pos3_nomark | 8
@test typeof(tst) == typeof(pos3_nomark)
@test tst == 3|8
