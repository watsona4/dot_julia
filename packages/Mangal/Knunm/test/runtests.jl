using Mangal
using Test

my_tests = [
    "backbone.jl",
    "nodes.jl",
    "cache.jl",
    "datasets.jl",
    "networks.jl",
    "interactions.jl"
]

global test_n
global anyerrors

# Shhhh...
Mangal.login_message()

test_n = 1
anyerrors = false

for my_test in my_tests
  try
    include(my_test)
    println("[TEST $(lpad(test_n,2))] \033[1m\033[32mPASS\033[0m $(my_test)")
  catch e
    global anyerrors = true
    println("[TEST $(lpad(test_n,2))] \033[1m\033[31mFAIL\033[0m $(my_test)")
    showerror(stdout, e, backtrace())
    println()
    throw("TEST FAILED")
  end
  global test_n += 1
end

if anyerrors
  throw("Tests failed")
end
