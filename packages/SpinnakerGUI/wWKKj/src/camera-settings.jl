
Base.@kwdef mutable struct information
    modelName::String = ""
    deviceSerialNumber::String = ""
    deviceFirmwareVersion::String = ""
end

Base.@kwdef mutable struct settings
    acquisitionMode::Symbol = :continuous #[:continuous,:singleFrame,:multiFrame]
    acquisitionFramerate::AbstractFloat = 30.0
    exposureMode::Symbol = :timed #[:timed,:triggerWidth]
    exposureAuto::Symbol = :off #[:off,:once,:continuous]
    exposureTime::AbstractFloat = 100.00
    gainAuto::Symbol = :off #[:off,:once,:continuous]
    gain::AbstractFloat = 0.0
    gamma::AbstractFloat = 1.25
    blackLevel::AbstractFloat = 5.0
    deviceLinkThroughputLimit::Int64 = 383328000

    width::Int64 = 100
    height::Int64 = 30
    offsetX::Int64 = 0
    offsetY::Int64 = 0
    pixelFormat::String = ""
    binningHorizontal::Int64 = 1
    binningVertical::Int64 = 1
end

Base.@kwdef mutable struct settingsLimits
    acquisitionMode::Vector{Symbol} = [:continuous,:singleFrame,:multiFrame]
    acquisitionFramerate::Tuple{AbstractFloat,AbstractFloat} = (0.0,60.0)
    exposureMode::Vector{Symbol} = [:timed,:triggerWidth]
    exposureAuto::Vector{Symbol} = [:off,:once,:continuous]
    exposureTime::Tuple{AbstractFloat,AbstractFloat} = (0.0,100.0)
    autoExposureTime::Tuple{AbstractFloat,AbstractFloat} = (0.0,100.0)
    gainAuto::Vector{Symbol} = [:off,:once,:continuous]
    gain::Tuple{AbstractFloat,AbstractFloat} = (0.0,10.0)
    gamma::Tuple{AbstractFloat,AbstractFloat} = (0.0,10.0)
    blackLevel::Tuple{AbstractFloat,AbstractFloat} = (0.0,4000.0)
    deviceLinkThroughputLimit::Tuple{Int64,Int64} = (0,383328000)

    width::Tuple{Int64,Int64} = (0,3000)
    height::Tuple{Int64,Int64} = (0,3000)
    offsetX::Tuple{Int64,Int64} = (0,3000)
    offsetY::Tuple{Int64,Int64} = (0,3000)
    binningHorizontal::Tuple{Int64,Int64} = (1,2)
    binningVertical::Tuple{Int64,Int64} = (1,2)
end

Base.@kwdef mutable struct GPIO
    triggerSelector::Symbol = :frameStart #[:frameStart,:exposureActive]
    triggerMode::Symbol = :off #[:off,:on]
    triggerSource::Symbol = :line0 #[:software,:line0,:line3,:line3]
    triggerActivation::Symbol = :fallingEdge #[:risingEdge,:fallingEdge]
    triggerOverlap::Symbol = :off #[:off,:readOut]
    triggerDelay::AbstractFloat = 0.0
    lineSelector::Symbol = :line0 #[:line0,:line1,:line2,:line3]
    lineMode::Symbol = :input #[:input]
    lineInverter::Bool = true
    lineSource::Symbol = :nothing #[:exposureActive,:externalTriggerActive,:userOutput1]
    userOutputSelector::Symbol = :UserOutputValue1 #[:UserOutputValue1,:UserOutputValue2,:UserOutputValue3]
    userOutputValue::Bool = true
end


Base.@kwdef mutable struct GPIOLimits
    triggerSelector::Vector{Symbol} = [:frameStart,:exposureActive]
    triggerMode::Vector{Symbol} = [:off,:on]
    triggerSource::Vector{Symbol} = [:software,:line0,:line3,:line3]
    triggerActivation::Vector{Symbol} = [:risingEdge,:fallingEdge]
    triggerOverlap::Vector{Symbol} = [:off,:readOut]
    triggerDelay::Tuple{AbstractFloat,AbstractFloat} = (0.0,typemax(1.0))
    lineSelector::Vector{Symbol} = [:line0,:line1,:line2,:line3]
    lineMode::Vector{Symbol} = [:input]
    lineSource::Vector{Symbol} = [:exposureActive,:externalTriggerActive,:userOutput1]
    userOutputSelector::Vector{Symbol} = [:UserOutputValue1,:UserOutputValue2,:UserOutputValue3]
end

function camSettingsRead!(cam,camSettings)
    camSettings.acquisitionFramerate = framerate(cam)
    ex,mode = exposure(cam)
    camSettings.exposureTime = ex/1000
    camSettings.gain,mode = gain(cam)
    camSettings.width,camSettings.height = imagedims(cam)
    camSettings.offsetX,camSettings.offsetY = offsetdims(cam)
end

function camSettingsLimitsRead!(cam,camSettingsLimits)
    camSettingsLimits.acquisitionFramerate = framerate_limits(cam)
    camSettingsLimits.exposureTime = exposure_limits(cam)./1000
    camSettingsLimits.autoExposureTime = autoexposure_limits(cam)./1000

    camSettingsLimits.gain = gain_limits(cam)

    # Image size
    camSettingsLimits.width,camSettingsLimits.height = imagedims_limits(cam)
    camSettingsLimits.offsetX,camSettingsLimits.offsetY = offsetdims_limits(cam)
end

function camSettingsUpdater(;timerInterval::AbstractFloat=1/10)
    global sessionStat
    global camSettings, camSettingsLimits
    global camGPIO, camGPIOLimits

    updateTimer = Timer(0,interval=timerInterval)
    lastSessionStat = deepcopy(sessionStat)
    lastCamSettings = deepcopy(camSettings)
    lastCamSettingsLimits = deepcopy(camSettingsLimits)
    lastCamGPIO = deepcopy(camGPIO)
    first_autoexposure = true
    while !sessionStat.terminate
        t_before = time()
        if isrunning(cam)

            # RECORDING

            # FRAMERATE
            if (camSettings.acquisitionFramerate != lastCamSettings.acquisitionFramerate)
                framerate!(cam,camSettings.acquisitionFramerate)
                lastCamSettings.acquisitionFramerate = camSettings.acquisitionFramerate
                camSettingsLimitsRead!(cam,camSettingsLimits)
                camSettingsRead!(cam,camSettings)
                if camSettings.exposureAuto != :off
                    camSettingsLimits.autoExposureTime = autoexposure_limits!(cam,(0,1e9)) #intentionally too small/large to find lims
                end
            end

            # EXPOSURE
            if (camSettings.exposureAuto != lastCamSettings.exposureAuto) || (camSettings.exposureTime != lastCamSettings.exposureTime)
                if camSettings.exposureAuto == :off
                    exposure!(cam,camSettings.exposureTime*1000)
                elseif camSettings.exposureAuto == :continuous
                    exposure!(cam)
                end
                lastCamSettings.exposureAuto = camSettings.exposureAuto
                lastCamSettings.exposureTime = camSettings.exposureTime
            end
            if camSettings.exposureAuto != :off
                ex,mode = exposure(cam)
                camSettings.exposureTime = ex/1000
                if first_autoexposure
                    #Catches first opportunity to set auto exposure lims, in case framerate hasn't changed first
                    #(can only be set when auto exposure is enabled)
                    camSettingsLimits.autoExposureTime = autoexposure_limits!(cam,(0,1e9)) #intentionally too small/large to find lims
                    first_autoexposure = false
                end
            end

            # GAIN
            if (camSettings.gainAuto != lastCamSettings.gainAuto) || (camSettings.gain != lastCamSettings.gain)
                if camSettings.gainAuto == :off
                    gain!(cam,camSettings.gain)
                elseif camSettings.gainAuto == :continuous
                    gain!(cam)
                end
                lastCamSettings.gainAuto = camSettings.gainAuto
                lastCamSettings.gain = camSettings.gain
            end
            if camSettings.gainAuto != :off
                camSettings.gain, _ = gain(cam)
            end

            # IMAGE OFFSET
            if (camSettings.offsetX != lastCamSettings.offsetX) || (camSettings.offsetY != lastCamSettings.offsetY)
                try
                    offsetdims!(cam,(camSettings.offsetX,camSettings.offsetY))
                    lastCamSettings.offsetX = camSettings.offsetX
                    lastCamSettings.offsetY = camSettings.offsetY
                    camSettingsLimitsRead!(cam,camSettingsLimits)
                catch e
                    #@info "Selected x or y offset not allowed"
                    camSettings.offsetX = lastCamSettings.offsetX
                    camSettings.offsetY = lastCamSettings.offsetY
                end
            end
        else
            # IMAGE SIZE (Can't be set while running)
            if (camSettings.width != lastCamSettings.width) || (camSettings.height != lastCamSettings.height)
                try
                    imagedims!(cam,(camSettings.width,camSettings.height))
                    lastCamSettings.width = camSettings.width
                    lastCamSettings.height = camSettings.height
                    camSettingsLimitsRead!(cam,camSettingsLimits)
                    sessionStat.resolutionupdate = true
                catch e
                    #@info "Selected width or height not allowed"
                    camSettings.width = lastCamSettings.width
                    camSettings.height = lastCamSettings.height
                end
            end
        end
        if time()-t_before < timerInterval
            wait(updateTimer)
        else
            yield()
        end

    end
    close(updateTimer)
    updateTimer = nothing
end

function camGPIOLimitsUpdater!(camGPIOLimits::GPIOLimits)

end
