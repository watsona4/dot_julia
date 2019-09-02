# These tests do not require an FT device which supports D2XX to be connected 
#
# By Reuben Hill 2019, Gowerlabs Ltd, reuben@gowerlabs.co.uk
#
# Copyright (c) Gowerlabs Ltd.

module TestLibFTD2XX

using Test
using LibFTD2XX
import LibFTD2XX.Wrapper

@testset "high level" begin

  # libversion
  if Sys.iswindows()
    ver = libversion()
    @test ver isa VersionNumber
  else
    @test_throws UndefVarError libversion()
  end

  # createdeviceinfolist
  numdevs = LibFTD2XX.createdeviceinfolist()
  @test numdevs == 0

  # LibFTD2XX.getdeviceinfodetail
  @test_throws D2XXException LibFTD2XX.getdeviceinfodetail(0)

  # FT_HANDLE functions...
  @testset "FT_HANDLE" begin

    # open by description
    @test_throws Wrapper.FT_DEVICE_NOT_FOUND open("", OPEN_BY_DESCRIPTION)
    
    # open by serialnumber
    @test_throws Wrapper.FT_DEVICE_NOT_FOUND open("", OPEN_BY_SERIAL_NUMBER)
    
    handle = FT_HANDLE() # create invalid handle...
  
    # bytesavailable
    @test_throws D2XXException bytesavailable(handle)

    # read
    @test_throws D2XXException read(handle, 0)
    @test_throws D2XXException read(handle, 1)
    @test_throws ErrorException read(handle, -1) # exception type set by Base/io.jl

    # write
    txbuf = ones(UInt8, 10)
    @test_throws D2XXException write(handle, txbuf)
    @test txbuf == ones(UInt8, 10)
    @test_throws ErrorException write(handle, Int.(txbuf)) # No byte I/O...

    # readavailable
    @test_throws D2XXException readavailable(handle)

    # baudrate
    @test_throws D2XXException baudrate(handle, 9600)
    @test_throws DomainError baudrate(handle, 0)
    @test_throws DomainError baudrate(handle, -1)

    # flush and eof
    @test_throws D2XXException flush(handle)
    @test_throws D2XXException eof(handle)

    # driverversion
    if Sys.iswindows()
      @test_throws D2XXException driverversion(handle)
    else
      @test_throws UndefVarError driverversion(handle)
    end

    # datacharacteristics
    @test_throws D2XXException datacharacteristics(handle, wordlength = BITS_8, stopbits = STOP_BITS_1, parity = PARITY_NONE)

    # timeouts tests...
    timeout_read, timeout_wr = 200, 100 # milliseconds
    @test_throws D2XXException timeouts(handle, timeout_read, timeout_wr)
    @test_throws DomainError timeouts(handle, timeout_read, -1)
    @test_throws DomainError timeouts(handle, -1, timeout_wr)

    # status
    @test_throws D2XXException status(handle)

    # close and isopen
    retval = close(handle)
    @test retval == nothing
    @test !isopen(handle)
    @test LibFTD2XX.Wrapper._ptr(handle) == C_NULL
    retval = close(handle) # check can close more than once without issue...
    @test !isopen(handle)
  end

  # D2XXDevice
  @testset "D2XXDevice" begin

    # Constructor
    @test_throws DomainError D2XXDevice(-1)
    @test_throws D2XXException D2XXDevice(0)

    # D2XXDevices
    devices = D2XXDevices()
    @test length(devices) == numdevs == 0

    device = D2XXDevice(0, 0, 0, 0, 0, "", "", FT_HANDLE()) # blank device...

    # isopen
    @test !isopen(device)

    # open
    @test_throws Wrapper.FT_DEVICE_NOT_FOUND open(device)
    
    # bytesavailable
    @test_throws D2XXException bytesavailable(device)

    nb = 1

    # read
    @test_throws D2XXException read(device, nb)
    @test_throws ErrorException read(device, -1) # exception type set by Base/io.jl

    # write
    txbuf = ones(UInt8, 10)
    @test_throws D2XXException write(device, txbuf)
    @test txbuf == ones(UInt8, 10)
    @test_throws ErrorException write(device, Int.(txbuf)) # No byte I/O...

    # readavailable
    @test_throws D2XXException readavailable(device)

    # baudrate
    @test_throws D2XXException baudrate(device, 9600)
    @test_throws DomainError baudrate(device, 0)
    @test_throws DomainError baudrate(device, -1)

    # flush and eof
    @test_throws D2XXException flush(device)
    @test_throws D2XXException eof(device)

    # driverversion
    if Sys.iswindows()
      @test_throws D2XXException driverversion(device)
    else
      @test_throws UndefVarError driverversion(device)
    end

    # datacharacteristics
    @test_throws D2XXException datacharacteristics(device, wordlength = BITS_8, stopbits = STOP_BITS_1, parity = PARITY_NONE)

    # timeouts tests...
    timeout_read, timeout_wr = 200, 100 # milliseconds
    @test_throws D2XXException timeouts(device, timeout_read, timeout_wr)
    @test_throws DomainError timeouts(device, timeout_read, -1)
    @test_throws DomainError timeouts(device, -1, timeout_wr)

    # status
    @test_throws D2XXException status(device)

    # close and isopen (all devices)
    retval = close.(devices)
    @test all(retval .== nothing)
    @test all(.!isopen.(devices))
    @test all(LibFTD2XX.Wrapper._ptr.(fthandle.(devices)) .== C_NULL)
    close.(devices) # check can close more than once without issue...
    @test all(.!isopen.(devices))
  end

end

end # module TestLibFTD2XX
