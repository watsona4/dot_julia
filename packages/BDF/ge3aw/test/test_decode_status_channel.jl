using BDF, Compat.Test

speedModes = [0,4,5,6,7,9]

for i in speedModes
  local dats, evtTab, trigs, statusChan = readBDF(string("MK2_speedmode", i, "_CMS_not_in_range_battery_charged.bdf"))
    statusChanInfo = decodeStatusChannel(statusChan)
    @test isequal(unique(statusChanInfo["CMSInRange"]) , [false])
    @test isequal(unique(statusChanInfo["speedMode"]) , [i])
    @test isequal(unique(statusChanInfo["batteryLow"]) , [false])
    @test isequal(unique(statusChanInfo["isMK2"]) , [true])
end
    
