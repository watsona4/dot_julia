# -*- coding: utf-8 -*-
import HELICS

const h = HELICS

initstring = "-f 2 --name=mainbroker"
fedinitstring = "--broker=mainbroker --federates=1"
deltat = 0.01

helicsversion = h.helicsGetVersion()

println("PI SENDER: Helics version = $helicsversion")

# Create broker #
println("Creating Broker")
broker = h.helicsCreateBroker("zmq", "", initstring)
println("Created Broker")

println("Checking if Broker is connected")
isconnected = h.helicsBrokerIsConnected(broker)
println("Checked if Broker is connected")

if isconnected == 1
    println("Broker created and connected")
end

# Create Federate Info object that describes the federate properties #
fedinfo = h.helicsCreateFederateInfo()

# Set Federate name #
h.helicsFederateInfoSetCoreName(fedinfo, "TestA Federate")

# Set core type from string #
h.helicsFederateInfoSetCoreTypeFromString(fedinfo, "zmq")

# Federate init string #
h.helicsFederateInfoSetCoreInitString(fedinfo, fedinitstring)

# Set the message interval (timedelta) for federate. Note th#
# HELICS minimum message time interval is 1 ns and by default
# it uses a time delta of 1 second. What is provided to the
# setTimedelta routine is a multiplier for the default timedelta.

# Set one second message interval #
h.helicsFederateInfoSetTimeProperty(fedinfo, h.HELICS_PROPERTY_TIME_DELTA, deltat)

# Create value federate #
vfed = h.helicsCreateValueFederate("TestA Federate", fedinfo)
println("PI SENDER: Value federate created")

# Register the publication #
pub = h.helicsFederateRegisterGlobalTypePublication(vfed, "testA", "double", "")
println("PI SENDER: Publication registered")

# Enter execution mode #
h.helicsFederateEnterExecutingMode(vfed)
println("PI SENDER: Entering execution mode")

# This federate will be publishing deltat*pi for numsteps steps #
this_time = 0.0
value = pi

for t in 5:10
    val = value

    currenttime = h.helicsFederateRequestTime(vfed, Float64(t))

    h.helicsPublicationPublishDouble(pub, Float64(val))
    println(
        "PI SENDER: Sending value pi = $val at time $currenttime to PI RECEIVER"
    )

    sleep(1)
end

h.helicsFederateFinalize(vfed)
println("PI SENDER: Federate finalized")

while h.helicsBrokerIsConnected(broker)
    sleep(1)
end

h.helicsFederateFree(vfed)
h.helicsCloseLibrary()

println("PI SENDER: Broker disconnected")
