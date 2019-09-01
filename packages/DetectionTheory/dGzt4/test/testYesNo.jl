using Test, DetectionTheory

@test round(dprimeYesNo(0.8, 0.4), digits=3) == 1.095
@test round(dprimeYesNo(0.32, 0.04), digits=3) == 1.283
@test round(dprimeYesNo(0.99, 0.01), digits=2) == 4.65
