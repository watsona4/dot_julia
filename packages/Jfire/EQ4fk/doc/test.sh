set -vex
which julia
alias julia="julia --color=yes"
# call from single module
julia myth.jl hello --name world --number Int::5

# call from multiple modules 
julia myths.jl  myth1.hello1 --name world --number Int::5

julia myths.jl  myth2.hello2 --name myth --number Float32::5

# call from single function
julia  func.jl wow


# call from multiple functions
julia  funcs.jl  myth_func1 well --greet 'nice day' --fishing Bool::true

julia  funcs.jl  myth_func2 well --greet 'nice day'

echo test done
