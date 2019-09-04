using Wilkinson, Test

# write your own tests here
@test PolynomialAnalysis(:(x^9-2)).val == PolynomialAnalysis(:((x-2)^9)).val
