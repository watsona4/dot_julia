using VideoIO, Dates


```
videowritelistener(;compression=0,overwrite=false, options=``)
Write video to file

Based on https://discourse.julialang.org/t/creating-a-video-from-a-stack-of-images/646/8
Reference for H.264: https://trac.ffmpeg.org/wiki/Encode/H.264#LosslessH.264
The range of the compression (CRF) scale is 0–51, where 0 is lossless, 23 is the default, and 51 is worst quality possible
```
function videowritelistener(;compression=0,overwrite=false,threads=0)

    ow = overwrite ? `-y` : `-n`
    preset = (compression == 0) ? "ultrafast" : "medium"

    global sessionStat
    global camImageFrameBuffer

    while !sessionStat.terminate
        if length(camImageFrameBuffer) > 0
            sessionStat.savedframes = 0
            fname = string(Dates.format(now(), "yyyy-mm-dd_HHMMSS"),".mp4")
            h, w = size(camImageFrameBuffer[1])
            if (h % 2 != 0) || (w % 2 != 0)
                @info "Image dims for H264 video encoding need to be even ($h x $w)"
                sessionStat.recording = false
                camImageFrameBuffer = Vector{Array{UInt8}}(undef,0)
                sessionStat.bufferedframes = 0
            else
                fps = camSettings.acquisitionFramerate
                withenv("PATH" => VideoIO.libpath,
                    "LD_LIBRARY_PATH" => VideoIO.libpath,
                    "DYLD_LIBRARY_PATH" => VideoIO.libpath) do
                    open(`$(VideoIO.ffmpeg)
                        -loglevel warning
                        -threads $threads
                        $ow -f rawvideo -pix_fmt gray -s:v $(h)x$(w)
                        -r $fps -i pipe:0 -c:v libx264 -preset: $preset
                        -crf $compression -pix_fmt yuv422p
                        $fname`, "w") do out
                        while (length(camImageFrameBuffer) > 0 || sessionStat.recording) && !sessionStat.terminate
                            while length(camImageFrameBuffer) == 0 && sessionStat.recording
                                wait(Timer(0.01)) #wait without blocking during recording time
                            end
                            if length(camImageFrameBuffer) >0
                                write(out, camImageFrameBuffer[1])
                                deleteat!(camImageFrameBuffer, 1)
                                sessionStat.bufferedframes = length(camImageFrameBuffer)
                                sessionStat.savedframes += 1
                            end
                            yield()
                        end
                        filepath = joinpath(pwd(),fname)
                        @info "Video saved [$(sessionStat.savedframes) frames, $(fps) fps]: $(filepath)"
                    end
                end
            end
        end
        yield()
    end
end
