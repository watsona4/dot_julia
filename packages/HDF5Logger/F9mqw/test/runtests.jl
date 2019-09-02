using HDF5Logger
using Test
using HDF5 # For reading in wholesale time histories

# Set up some data to work with.
num_samples = 5
vector_data = [1., 2., 3.]
matrix_data = transpose([1 2 3; 4 5 6])
scalar_data = 1.
c           = 2

# Create the log.
file_name = "test_log.h5"
log = Log(file_name)
try

    # Test a vector
    add!(log, "/vector", vector_data, num_samples)
    log!(log, "/vector", vector_data)
    log!(log, "/vector", c * vector_data)

    # Test a matrix
    add!(log, "/group/matrix", matrix_data, num_samples, true) # Keep data.
    # log!(log, "/group/matrix", matrix_data) # First sample is kept this time!
    log!(log, "/group/matrix", c * matrix_data)

    # Test a scalar
    add!(log, "/group/scalar", scalar_data, num_samples)
    log!(log, "/group/scalar", scalar_data)
    log!(log, "/group/scalar", c * scalar_data)

catch err
    close!(log)
    rethrow(err)
end

close!(log)

# Now test that the right stuff happened. Use the regular HDF5 library to open
# the files we created. With the `do` block, the file will be automatically
# closed if anything goes wrong.
h5open(file_name, "r") do file

    vector_result = read(file, "/vector")
    matrix_result = read(file, "/group/matrix")
    scalar_result = read(file, "/group/scalar")

    @test(vector_result[:,1]   == vector_data)
    @test(matrix_result[:,:,1] == matrix_data)
    @test(scalar_result[1]     == scalar_data)

    @test(vector_result[:,2]   == c * vector_data)
    @test(matrix_result[:,:,2] == c * matrix_data)
    @test(scalar_result[2]     == c * scalar_data)

    @test(size(vector_result) == (3, num_samples))
    @test(size(matrix_result) == (3, 2, num_samples))
    @test(size(scalar_result) == (1, num_samples))

    @test(eltype(vector_result) == Float64)
    @test(eltype(matrix_result) == Int64)
    @test(eltype(scalar_result) == Float64)

end

# Clean up after ourselves.
rm(file_name)
