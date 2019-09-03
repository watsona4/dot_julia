# dummycamera

dummycamTimer = nothing
exposurefactor = camSettings.exposureTime/12.0 #dummy setting to simulate ideal 12.0 time

# Typically imported functions, made to act like t dummy camera
function getimage!(cam::String,image::Array{UInt8};normalize::Bool=false)
    image .= round.(UInt8,clamp.(rand(UInt8,size(image,1),size(image,2)).*exposurefactor,UInt8(0),UInt8(255)))
    wait(dummycamTimer)
end
function exposure!(cam::String)
    exposure = 12.0 #dummy value
    updateExposureFactor(exposure,camSettings.gain) #dummy brightness change
    return exposure
end
function exposure!(cam::String,exposure::Real)
    updateExposureFactor(exposure,camSettings.gain) #dummy brightness change
end
function gain!(cam::String)
    gain = 0.0 #dummy value
    updateExposureFactor(camSettings.exposureTime,gain) #dummy brightness change
    return gain
end
function gain!(cam::String,gain::Real)
    updateExposureFactor(camSettings.exposureTime,gain) #dummy brightness change
end
function start!(cam::String)
    global dummycamTimer
    dummycamTimer = Timer(0.0,interval=1/camSettings.acquisitionFramerate)
end
function stop!(cam::String)
    global dummycamTimer
    close(dummycamTimer)
    dummycamTimer = nothing
end
function framerate!(cam::String,framerate::Real)
    global dummycamTimer
    dummycamTimer = Timer(0.0,interval=1/camSettings.acquisitionFramerate)
end
function imagedims!(cam::String,dims)
    global camImage
    camImage = Array{UInt8}(undef,dims...)
end
function offsetdims!(cam::String, dims)
    # do something with dims
end
function sensordims(cam::String)
    return (2048,1536)
end
function isrunning(cam::String)
    return camRunning
end

# Helper functions for dummy behaviour
function updateExposureFactor(exposure,gain)
    global exposurefactor
    exposurefactor = (exposure/12.0)*(1.0 + gain)
end

# Main functions
function runCamera()
    global dummycamTimer
    global perfGrabFramerate
    global cam, camImage, camImageFrameBuffer
    global camSettingsLimits

    # Initialize dummy camera
    cam = "dummycam"

    camSettingsLimitsUpdater!(cam,camSettingsLimits)

    start!(cam)

    camImage = Array{UInt8}(undef,camSettings.width,camSettings.height)

    perfGrabTime = time()
    while gui_open
        if isrunning(cam)
            #cim_id, cim_timestamp, cim_exposure = getimage!(camera, previewimage)
            try
                getimage!(cam,camImage,normalize=false)
            catch err
                if err isa EOFError
                    # Do nothing. This happens if the camera is stopped before the camRunning
                    # bool is set due to async
                else
                    rethrow()
                end
            end
            # Loop timing
            perfGrabFramerate = 1/(time() - perfGrabTime)
            perfGrabTime = time()
        end
        yield()
    end
    stop!(cam)
end
