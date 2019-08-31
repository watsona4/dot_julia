module TestCAOS

    using CAOS
    using Test

    all_tests = [
        ("tree_functions.jl",   "           Testing: Tree functions"),
    #    ("gap_imputation.jl",     "       Testing: Gap imputation"),
        ("classification.jl",     "       Testing: Classification"),
        ("user_functions.jl",     "       Testing: User functions"),
        ("caos_functions.jl",     "       Testing: CAOS functions"),
        ("utils.jl",     "       Testing: Utils")

        ]

    println("Running tests:")

    for (t, test_string) in all_tests
        println("-----------------------------------------")
        println(test_string)
        include(t)
    end

end
