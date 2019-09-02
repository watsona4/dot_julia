
using StaticArrays
using MolecularBoxes
using MolecularTrajectories
using MolecularTopologies
using Test

const Vec = SVector{3,Float64}

time = 99.9
numatoms = 8
box = Box(Vec(1.0,2.0,3.0))
test_pos = [Vec(i,i+1,i-1) for i in 1:numatoms]
frame = Frame{Vec}(time, box, test_pos, Vec[])

@test get_num_atoms(frame) == numatoms

for i in 1:numatoms
    @test frame.positions[i] == test_pos[i]
end

@test frame.time == time
time2 = -12.1

@test frame.box == box

#define a dummy trajectory type

#@warn "Tests only check that XTC trajectory can be read without runs without crashing"
#
#testfile = "test.xtc"
#
#xtc = XTC{Vec}([testfile, testfile])
#xtc2 = XTC{Vec}(testfile, testfile)
#for a_frame in xtc
#    @test a_frame.time > -1 #dummy test
#end

grofile = "test.gro"
gro = GroTrajectory{Vec}([grofile, grofile, grofile], dt = 10)

for (i,a_frame) in enumerate(gro)
    @test a_frame.time == i*10
    @test a_frame.positions[1] == Vec(0.071, 8.301, 0.000)
    @test a_frame.positions[29998] == Vec(1.744, 5.789, 19.704)
    @test a_frame.positions[end] == Vec(2.587, 0.535, 9.567)
    @test length(a_frame.positions) == 62322
    @test a_frame.box == Box(
        Vec(8.52000,  8.36230, 37.00000)
    )
end

# test different constructor
gro = GroTrajectory{Vec}(grofile, grofile, grofile, dt = 10)
for (i,a_frame) in enumerate(gro)
    @test a_frame.time == i*10
    @test a_frame.positions[1] == Vec(0.071, 8.301, 0.000)
    @test a_frame.velocities[3489] == Vec(0.0853, 0.6458, 0.2153)
end

let gro = GroTrajectory{Vec}(grofile)
    topology = open(gro_topology, grofile)
    frame = first(gro)
    buffer = PipeBuffer()
    write_frame(buffer, GroTrajectory, frame, topology, "1941 deposited molecules")
    result = String(take!(buffer))
    open("test_result.gro", "w") do f
        print(f,result)
    end
    expected = String(open(read, grofile))
    compare = (result==expected)
    @test compare == true
end


