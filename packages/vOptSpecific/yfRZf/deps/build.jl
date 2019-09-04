cd("LAP") do
    print(pwd())
    run(`make`)
end

cd("UMFLP") do
    print(pwd())
    run(`make`)
end

cd("Combo") do
    run(`make`)
end

