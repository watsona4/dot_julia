# These tests require an FT device which supports D2XX to be connected 
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
  @test numdevs > 0

  # FT_GetDeviceInfoList tests...
  devinfolist, numdevs2 = FT_GetDeviceInfoList(numdevs)
  @test numdevs2 == numdevs
  @test length(devinfolist) == numdevs
  
  description = ntuple2string(devinfolist[1].description)

  if Sys.iswindows() # should not have a locid on windows
    @test devinfolist[1].locid == 0
  end

  # FT_GetDeviceInfoDetail tests...
  idx, flags, typ, id, locid, serialnumber, description, fthandle = FT_GetDeviceInfoDetail(0)

  @test idx == 0
  @test flags == devinfolist[1].flags
  @test typ == devinfolist[1].typ
  @test id == devinfolist[1].id
  @test locid == devinfolist[1].locid
  @test serialnumber == ntuple2string(devinfolist[1].serialnumber)
  @test description == ntuple2string(devinfolist[1].description)
  @test Wrapper._ptr(fthandle) == devinfolist[1].fthandle_ptr

  # FT_ListDevices tests...
  numdevs2 = Ref{UInt32}()
  retval = FT_ListDevices(numdevs2, Ref{UInt32}(), FT_LIST_NUMBER_ONLY)
  @test retval == nothing
  @test numdevs2[] == numdevs

  devidx = Ref{UInt32}(0)
  buffer = pointer(Vector{Cchar}(undef, 64))
  @test_throws ErrorException FT_ListDevices(devidx, buffer, FT_LIST_BY_INDEX|FT_OPEN_BY_SERIAL_NUMBER)
  @test description != unsafe_string(buffer)

  # FT_Open tests...
  handle = FT_Open(0)
  @test handle isa FT_HANDLE
  @test Wrapper._ptr(handle) != C_NULL
  FT_Close(handle)

  # FT_OpenEx tests...
  # by description
  handle = FT_OpenEx(description, FT_OPEN_BY_DESCRIPTION)
  @test handle isa FT_HANDLE
  @test Wrapper._ptr(handle) != C_NULL
  FT_Close(handle)
  # by serialnumber
  handle = FT_OpenEx(serialnumber, FT_OPEN_BY_SERIAL_NUMBER)
  @test handle isa FT_HANDLE
  @test Wrapper._ptr(handle) != C_NULL
  FT_Close(handle)

  # FT_Close tests...
  handle = FT_Open(0)
  retval = FT_Close(handle)
  @test retval == nothing
  @test_throws FT_STATUS_ENUM FT_Close(handle) # can't close twice...

  # FT_Read tests...
  handle = FT_Open(0)
  buffer = zeros(UInt8, 5)
  nread = FT_Read(handle, buffer, 0) # read 0 bytes
  @test nread == 0
  @test buffer == zeros(UInt8, 5)
  @test_throws AssertionError FT_Read(handle, buffer, 6) # read 5 bytes
  @test_throws AssertionError FT_Read(handle, buffer, -1) # read -1 bytes
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_Read(handle, buffer, 0)

  # FT_Write tests...
  handle = FT_Open(0)
  buffer = ones(UInt8, 5)
  nwr = FT_Write(handle, buffer, 0) # write 0 bytes
  @test nwr == 0
  @test buffer == ones(UInt8, 5)
  nwr = FT_Write(handle, buffer, 2) # write 2 bytes
  @test nwr == 2
  @test buffer == ones(UInt8, 5)
  @test_throws AssertionError FT_Write(handle, buffer, 6) # write 6 bytes
  @test_throws AssertionError FT_Write(handle, buffer, -1) # write -1 bytes
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_Write(handle, buffer, 0)

  # FT_SetDataCharacteristics tests...
  handle = FT_Open(0)
  retval = FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_1, FT_PARITY_NONE)
  @test retval == nothing
  # other combinations...
  FT_SetDataCharacteristics(handle, FT_BITS_7, FT_STOP_BITS_1, FT_PARITY_NONE)
  FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_2, FT_PARITY_NONE)
  FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_1, FT_PARITY_EVEN)
  FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_1, FT_PARITY_ODD)
  FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_1, FT_PARITY_MARK)
  FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_1, FT_PARITY_SPACE)
  # Bad values
  @test_throws AssertionError FT_SetDataCharacteristics(handle, ~(FT_BITS_8 | FT_BITS_7), FT_STOP_BITS_1, FT_PARITY_NONE)
  @test_throws AssertionError FT_SetDataCharacteristics(handle, FT_BITS_8, ~(FT_STOP_BITS_1 | FT_STOP_BITS_2), FT_PARITY_NONE)
  @test_throws AssertionError FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_1, ~(FT_PARITY_NONE | FT_PARITY_EVEN))
  # closed handle
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_SetDataCharacteristics(handle, FT_BITS_8, FT_STOP_BITS_1, FT_PARITY_NONE)

  # FT_SetTimeouts tests...
  handle = FT_Open(0)
  FT_SetBaudRate(handle, 9600)
  timeout_read, timeout_wr = 200, 100 # milliseconds
  FT_SetTimeouts(handle, timeout_read, timeout_wr)
  buffer = zeros(UInt8, 5000);
  tread = 1000 * @elapsed nread = FT_Read(handle, buffer, 5000)
  twr = 1000 * @elapsed nwr = FT_Write(handle, buffer, 5000)
  @test timeout_read < 1.5*tread
  @test timeout_wr < 1.5*twr
  @test_throws InexactError FT_SetTimeouts(handle, timeout_read, -1)
  @test_throws InexactError FT_SetTimeouts(handle, -1, timeout_wr)
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_SetTimeouts(handle, timeout_read, timeout_wr)

  # FT_GetModemStatus tests
  handle = FT_Open(0)
  flags = FT_GetModemStatus(handle)
  @test flags isa DWORD
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_GetModemStatus(handle)

  # FT_GetQueueStatus tests
  handle = FT_Open(0)
  nbrx = FT_GetQueueStatus(handle)
  @test nbrx isa DWORD
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_GetQueueStatus(handle)

  # FT_GetDeviceInfo tests
  id_buf = id
  serialnumber_buf = serialnumber
  description_buf = description
  handle = FT_Open(0)
  typ, id, serialnumber, description = FT_GetDeviceInfo(handle)
  @test typ isa FT_DEVICE
  @test serialnumber == serialnumber_buf
  @test description == description_buf
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_GetDeviceInfo(handle)

  # FT_GetDriverVersion tests
  if Sys.iswindows()
    handle = FT_Open(0)
    version = FT_GetDriverVersion(handle)
    @test version isa DWORD
    @test version > 0
    @test (version >> 24) & 0xFF == 0x00 # 4th byte should be 0 according to docs
    FT_Close(handle)
    @test_throws FT_STATUS_ENUM FT_GetDriverVersion(handle)
  else
    handle = FT_Open(0)
    @test_throws UndefVarError FT_GetDriverVersion(handle)
    FT_Close(handle)
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
  handle = FT_Open(0)
  nbrx, nbtx, eventstatus = FT_GetStatus(handle)
  @test nbrx isa DWORD
  @test nbtx isa DWORD
  @test eventstatus isa DWORD
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_GetStatus(handle)

  # FT_SetBreakOn tests
  handle = FT_Open(0)
  retval = FT_SetBreakOn(handle)
  @test retval == nothing
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_SetBreakOn(handle)

  # FT_SetBreakOff tests
  handle = FT_Open(0)
  retval = FT_SetBreakOff(handle)
  @test retval == nothing
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_SetBreakOff(handle)

  # FT_Purge tests
  handle = FT_Open(0)
  retval = FT_Purge(handle, FT_PURGE_RX|FT_PURGE_TX)
  @test retval == nothing
  nbrx, nbtx, eventstatus = FT_GetStatus(handle)
  nbrx_2 = FT_GetQueueStatus(handle)
  @test nbrx == nbtx == nbrx_2 == 0
  FT_Purge(handle, FT_PURGE_RX)
  FT_Purge(handle, FT_PURGE_TX)
  @test_throws AssertionError FT_Purge(handle, ~(FT_PURGE_RX))
  @test_throws AssertionError FT_Purge(handle, ~(FT_PURGE_TX))
  @test_throws AssertionError FT_Purge(handle, ~(FT_PURGE_RX | FT_PURGE_TX))
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_Purge(handle, FT_PURGE_RX|FT_PURGE_TX)

  # FT_StopInTask and FT_RestartInTask tests
  handle = FT_Open(0)
  retval = FT_StopInTask(handle)
  @test retval == nothing
  nbrx, nbtx, eventstatus = FT_GetStatus(handle)
  sleep(0.1)
  nbrx_2, nbtx, eventstatus = FT_GetStatus(handle)
  @test nbrx == nbrx_2
  retval = FT_RestartInTask(handle)
  @test retval == nothing
  FT_Close(handle)
  @test_throws FT_STATUS_ENUM FT_StopInTask(handle)
  @test_throws FT_STATUS_ENUM FT_RestartInTask(handle)
  
end

end # module TestWrapper