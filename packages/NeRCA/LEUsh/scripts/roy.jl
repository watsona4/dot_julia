using NeRCA
using ROy
using Sockets

calib = NeRCA.read_calibration("scripts/NeRCA_00000043_20022019.detx")
calib = NeRCA.read_calibration("/home/tgal/data/detx/NeRCA_-00000001_20171212.detx")

client = NeRCA.CHClient(ip"127.0.0.1", 5553, ["IO_EVT"])

try
    for message in client
        event = NeRCA.read_io(IOBuffer(message.data), NeRCA.DAQEvent)
        hits = event.snapshot_hits
        chits = NeRCA.calibrate(hits, calib)
        thits = event.triggered_hits
        cthits = NeRCA.calibrate(thits, calib)
        println(length(cthits))
    end
catch InterruptException
    println("ok")
end
