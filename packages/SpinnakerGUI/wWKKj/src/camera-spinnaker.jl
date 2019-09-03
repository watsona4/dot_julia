# SpinnakerGUI.jl

using Spinnaker

function cam_init(;camid::Int64=0,silent=false,bufferMode="NewestOnly")
    global camSettings
    !silent && (@info "Checking for cameras")
    camlist = Spinnaker.CameraList()
    if length(camlist) == 0
        error("No camera found")
    else
        !silent && (@info "Selecting camera $camid")
        cam = camlist[camid]
        !silent && (@info "Switching to continuous mode")
        acquisitionmode!(cam,"Continuous")
        triggermode!(cam,"Off")
        !silent && (@info "Reading settings from camera")
        camSettingsRead!(cam,camSettings)
        camSettingsLimitsRead!(cam,camSettingsLimits)
        buffermode!(cam,bufferMode)
        !silent && (@info "Camera ready")
    end
    return cam
end


function canGetImage(cam)
    try
        getimage(cam,timeout=2000)
        return true
    catch e
        return false
    end
end

"""
startcheckrunningfix!(cam;bufferMode="NewestOnly")

Attempt a start!(cam) and check if able to grab images. If not, repeatedly reinitialize camera until it works,
up to attempsmax (5 by default)
This function exists because of instability experienced with the Grasshopper 3.

"""
function startcheckrunningfix!(cam;bufferMode="NewestOnly",maxattempts=5)
    try
        start!(cam)
    catch e
        reinitcam(bufferMode=bufferMode,maxattempts=maxattempts)
    end
    if canGetImage(cam)
        @info "Camera started"
    else
        reinitcam(bufferMode=bufferMode,maxattempts=maxattempts)
    end
end

function reinitcam(;bufferMode="NewestOnly",maxattempts=5)
    global cam
    @info "Camera Issue: Reinitializing camera"
    attempts = 0
    while !canGetImage(cam) || attempts < maxattempts
        isrunning(cam) && stop!(cam)
        cam = cam_init(silent=true,bufferMode=bufferMode)
        start!(cam)
        attempts += 1
    end
    if attempts == maxattempts
        error("Camera couldn't be reinitialized (tried $attempts times)")
    else
        @info "Camera reinitialized"
    end
end


function runCamera()
    global perfGrabFramerate
    global cam, camImage, camImageFrameBuffer
    global camSettings, camSettingsLimits
    global sessionStat
    global camImageFrameBuffer

    camImage = Array{UInt8}(undef,camSettings.width,camSettings.height)

    startcheckrunningfix!(cam,bufferMode="OldestFirst")
    camSettingsLimitsRead!(cam,camSettingsLimits) #some things change once running

    perfGrabTime = time()
    grabNotRunningTimer = Timer(0.0,interval=1/5)
    while !sessionStat.terminate
        if isrunning(cam)
            if sessionStat.resolutionupdate
                camImage = Array{UInt8}(undef,camSettings.width,camSettings.height)
                sessionStat.resolutionupdate = false
            end
            try
                cim_id, cim_timestamp, cim_exposure = getimage!(cam,camImage,normalize=false,timeout=0)
                if sessionStat.recording
                    push!(camImageFrameBuffer,copy(camImage))
                    sessionStat.bufferedframes = length(camImageFrameBuffer)
                    sessionStat.droppedframes = bufferunderrun(cam)
                end
                # Loop timing
                perfGrabFramerate = 1/(time() - perfGrabTime)
                perfGrabTime = time()
            catch err
                if occursin("SPINNAKER_ERR_TIMEOUT(-1011)",sprint(showerror, err))
                    # No frame available
                    #println("No frame available")
                elseif err isa EOFError || occursin("SPINNAKER_ERR_IO(-1010)",sprint(showerror, err))
                    @warn "Noncritical framegrab error"
                else
                    rethrow()
                end
            end
            yield()
        else
            wait(grabNotRunningTimer)
            #println("Not running")
        end

    end
    isrunning(cam) && stop!(cam)

end
