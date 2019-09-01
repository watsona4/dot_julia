using Base, DetectionTheory

@test_throws(ErrorException, dprimeABX(1.1,0.1,"diff"))
@test_throws(ErrorException, dprimeABX(-0.1,0.1,"diff"))
@test_throws(ErrorException, dprimeABX(0.1,1.1,"diff"))
@test_throws(ErrorException, dprimeABX(0.1,1.1,"diff"))
@test_throws(ErrorException, dprimeABX(0.7,0.5,"foo"))

@test_throws(ErrorException, dprimeMAFC(0.7, 1))
@test_throws(ErrorException, dprimeMAFC(-0.1, 2))
@test_throws(ErrorException, dprimeMAFC(1.1, 2))
@test_throws(ErrorException, dprimeMAFC(-0.1, 2))
@test_throws(ErrorException, dprimeMAFC(1.1, 2))

@test_throws(ErrorException, dprimeOddity(0.3, "diff"))
@test_throws(ErrorException, dprimeOddity(1.1, "diff"))

@test_throws(ErrorException, dprimeYesNo(-0.1, 0.2))
@test_throws(ErrorException, dprimeYesNo(1.1, 0.2))
@test_throws(ErrorException, dprimeYesNo(0.7, -0.1))
@test_throws(ErrorException, dprimeYesNo(0.7, 1.1))

@test_throws(ErrorException, dprimeSD(1.1,0.1,"diff"))
@test_throws(ErrorException, dprimeSD(-0.1,0.1,"diff"))
@test_throws(ErrorException, dprimeSD(0.1,1.1,"diff"))
@test_throws(ErrorException, dprimeSD(0.1,1.1,"diff"))
@test_throws(ErrorException, dprimeSD(0.7,0.5,"foo"))


