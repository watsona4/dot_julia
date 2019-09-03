@testset "Low-Level tests of the PortAudio ringbuf library" begin
    @testset "Can create PA ring buffer" begin
        buf = RingBuffers.PaUtilRingBuffer(8, 16)
        @test RingBuffers.PaUtil_GetRingBufferWriteAvailable(buf) == 16
        @test RingBuffers.PaUtil_GetRingBufferReadAvailable(buf) == 0
    end

    @testset "Throws on non power of two element count" begin
        @test_throws ErrorException RingBuffers.PaUtilRingBuffer(8, 15)
    end

    @testset "Can read/write to PA ring buffer" begin
        buf = RingBuffers.PaUtilRingBuffer(sizeof(Int), 16)
        writedata = collect(1:5)
        readdata = collect(6:10)

        @test RingBuffers.PaUtil_WriteRingBuffer(buf, writedata, 5) == 5
        @test RingBuffers.PaUtil_GetRingBufferWriteAvailable(buf) == 11
        @test RingBuffers.PaUtil_GetRingBufferReadAvailable(buf) == 5
        @test RingBuffers.PaUtil_ReadRingBuffer(buf, readdata, 5) == 5
        @test RingBuffers.PaUtil_GetRingBufferWriteAvailable(buf) == 16
        @test RingBuffers.PaUtil_GetRingBufferReadAvailable(buf) == 0
        @test readdata == writedata
    end

    @testset "Can flush PA ring buffer" begin
        buf = RingBuffers.PaUtilRingBuffer(sizeof(Int), 16)
        writedata = collect(1:5)
        readdata = collect(6:10)

        @test RingBuffers.PaUtil_WriteRingBuffer(buf, writedata, 5) == 5
        @test RingBuffers.PaUtil_GetRingBufferWriteAvailable(buf) == 11
        @test RingBuffers.PaUtil_GetRingBufferReadAvailable(buf) == 5
        RingBuffers.PaUtil_FlushRingBuffer(buf)
        @test RingBuffers.PaUtil_GetRingBufferWriteAvailable(buf) == 16
        @test RingBuffers.PaUtil_GetRingBufferReadAvailable(buf) == 0
    end

    @testset "PA ring buffer handles overflow/underflow" begin
        buf = RingBuffers.PaUtilRingBuffer(sizeof(Int), 8)
        writedata = collect(1:5)
        readdata = collect(6:10)

        @test RingBuffers.PaUtil_WriteRingBuffer(buf, writedata, 5) == 5
        @test RingBuffers.PaUtil_WriteRingBuffer(buf, writedata, 5) == 3
        @test RingBuffers.PaUtil_GetRingBufferWriteAvailable(buf) == 0
        @test RingBuffers.PaUtil_GetRingBufferReadAvailable(buf) == 8
        @test RingBuffers.PaUtil_ReadRingBuffer(buf, readdata, 5) == 5
        @test RingBuffers.PaUtil_ReadRingBuffer(buf, readdata, 5) == 3
        @test RingBuffers.PaUtil_GetRingBufferWriteAvailable(buf) == 8
        @test RingBuffers.PaUtil_GetRingBufferReadAvailable(buf) == 0
    end
end
