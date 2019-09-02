# These tests do not require an FT device which supports D2XX to be connected
#
# By Reuben Hill 2019, Gowerlabs Ltd, reuben@gowerlabs.co.uk
#
# Copyright (c) Gowerlabs Ltd.

module TestWrapper

using Test
using LibFTD2XX.Wrapper
using LibFTD2XX.Util

@testset "wrapper" begin
  
  # FT_CreateDeviceInfoList tests...
  numdevs = FT_CreateDeviceInfoList()
  @test numdevs == 0

  # FT_GetDeviceInfoList tests...
  devinfolist, numdevs2 = FT_GetDeviceInfoList(numdevs)
  @test numdevs2 == numdevs == 0 
  @test length(devinfolist) == numdevs == 0
  
  # FT_GetDeviceInfoDetail tests...
  @test_throws FT_STATUS_ENUM FT_GetDeviceInfoDetail(0)

  # FT_ListDevices tests...
  numdevs2 = Ref{UInt32}()
  retval = FT_ListDevices(numdevs2, Ref{UInt32}(), FT_LIST_NUMBER_ONLY)
  @test retval == nothing
  @test numdevs2[] == numdevs
  devidx = Ref{UInt32}(0)
  buffer = pointer(Vector{Cchar}(undef, 64))
  @test_throws ErrorException FT_ListDevices(devidx, buffer, FT_LIST_BY_INDEX|FT_OPEN_BY_SERIAL_NUMBER)

  # FT_Open tests...
  @test_throws FT_STATUS_ENUM FT_Open(0)

  # FT_OpenEx tests...
  # by description
  @test_throws FT_STATUS_ENUM FT_OpenEx("", FT_OPEN_BY_DESCRIPTION)
  # by serialnumber
  @test_throws FT_STATUS_ENUM FT_OpenEx("", FT_OPEN_BY_SERIAL_NUMBER)
  
  # FT_Close tests...
  handle = FT_HANDLE() # create with invalid handle...
  @test_throws FT_INVALID_HANDLE FT_Close(handle)

  # FT_Read tests...
  buffer = zeros(UInt8, 5)
  @test_throws FT_INVALID_HANDLE FT_Read(handle, buffer, 0) # read 0 bytes
  @test buffer == zeros(UInt8, 5)
  @test_throws AssertionError FT_Read(handle, buffer, 6) # read 5 bytes
  @test_throws AssertionError FT_Read(handle, buffer, -1) # read -1 bytes
  
  # FT_Write tests...
  buffer = ones(UInt8, 5)
  @test_throws FT_INVALID_HANDLE FT_Write(handle, buffer, 0) # write 0 bytes
  @test buffer == ones(UInt8, 5)
  @test_throws AssertionError FT_Write(handle, buffer, 6) # write 6 bytes
  @test_throws AssertionError FT_Write(handle, buffer, -1) # write -1 bytes
  
  # FT_SetDataCharacteristics tests...
  @test_throws FT_INVALID_HANDLE FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_1, FT_PARITY_NONE)
  # Bad values
  @test_throws AssertionError FT_SetDataCharacteristics(handle, ~(FT_BITS_8 | FT_BITS_7), FT_STOP_BITS_1, FT_PARITY_NONE)
  @test_throws AssertionError FT_SetDataCharacteristics(handle, FT_BITS_8, ~(FT_STOP_BITS_1 | FT_STOP_BITS_2), FT_PARITY_NONE)
  @test_throws AssertionError FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_1, ~(FT_PARITY_NONE | FT_PARITY_EVEN))
  # closed handle
  
  # FT_SetTimeouts tests...
  timeout_read, timeout_wr = 200, 100 # milliseconds
  @test_throws FT_INVALID_HANDLE FT_SetTimeouts(handle, timeout_read, timeout_wr)
  @test_throws InexactError FT_SetTimeouts(handle, timeout_read, -1)
  @test_throws InexactError FT_SetTimeouts(handle, -1, timeout_wr)
  
  # FT_GetModemStatus tests
  @test_throws FT_INVALID_HANDLE FT_GetModemStatus(handle)
  
  # FT_GetQueueStatus tests
  @test_throws FT_INVALID_HANDLE FT_GetQueueStatus(handle)
  
  # FT_GetDeviceInfo tests
  @test_throws FT_INVALID_HANDLE FT_GetDeviceInfo(handle)

  # FT_GetDriverVersion tests
  if Sys.iswindows()
    @test_throws FT_INVALID_HANDLE FT_GetDriverVersion(handle)
  else
    @test_throws UndefVarError FT_GetDriverVersion(handle)
  end

  # FT_GetLibraryVersion tests
  if Sys.iswindows()
    version = FT_GetLibraryVersion()
    @test version isa DWORD
    @test version > 0
    @test (version >> 24) & 0xFF == 0x00 # 4th byte should be 0 according to docs
  else
    @test_throws UndefVarError FT_GetLibraryVersion()
  end

  # FT_GetStatus tests
  @test_throws FT_INVALID_HANDLE FT_GetStatus(handle)

  # FT_SetBreakOn tests
  @test_throws FT_INVALID_HANDLE FT_SetBreakOn(handle)

  # FT_SetBreakOff tests
  @test_throws FT_INVALID_HANDLE FT_SetBreakOff(handle)

  # FT_Purge tests
  @test_throws FT_INVALID_HANDLE FT_Purge(handle, FT_PURGE_RX|FT_PURGE_TX)
  @test_throws AssertionError FT_Purge(handle, ~(FT_PURGE_RX))
  @test_throws AssertionError FT_Purge(handle, ~(FT_PURGE_TX))
  @test_throws AssertionError FT_Purge(handle, ~(FT_PURGE_RX | FT_PURGE_TX))
  
  # FT_StopInTask and FT_RestartInTask tests
  @test_throws FT_INVALID_HANDLE FT_StopInTask(handle)
  @test_throws FT_INVALID_HANDLE FT_RestartInTask(handle)
  
end

end # module TestWrapper