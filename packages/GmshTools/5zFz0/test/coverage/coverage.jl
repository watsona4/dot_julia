using Coverage

cd(joinpath(@__DIR__, "..", "..")) do
    Codecov.submit(Codecov.process_folder())
    Coveralls.submit(Coveralls.process_folder())
end
