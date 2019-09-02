# -*- coding: utf-8 -*-
import HELICS

const h = HELICS

fedinitstring = "--federates=1"
deltat = 0.01

helicsversion = h.helicsGetVersion()

println("PI RECEIVER: Helics version = $helicsversion")

# Create Federate Info object that describes the federate properties */
println("PI RECEIVER: Creating Federate Info")
fedinfo = h.helicsCreateFederateInfo()

# Set Federate name
println("PI RECEIVER: Setting Federate Info Name")
h.helicsFederateInfoSetCoreName(fedinfo, "TestB Federate")

# Set core type from string
println("PI RECEIVER: Setting Federate Info Core Type")
h.helicsFederateInfoSetCoreTypeFromString(fedinfo, "zmq")

# Federate init string
println("PI RECEIVER: Setting Federate Info Init String")
h.helicsFederateInfoSetCoreInitString(fedinfo, fedinitstring)

# Set the message interval (timedelta) for federate. Note that
# HELICS minimum message time interval is 1 ns and by default
# it uses a time delta of 1 second. What is provided to the
# setTimedelta routine is a multiplier for the default timedelta.

# Set one second message interval
println("PI RECEIVER: Setting Federate Info Time Delta")
h.helicsFederateInfoSetTimeProperty(fedinfo, h.HELICS_PROPERTY_TIME_DELTA, deltat)

# Create value federate
println("PI RECEIVER: Creating Value Federate")
vfed = h.helicsCreateValueFederate("TestB Federate", fedinfo)
println("PI RECEIVER: Value federate created")

# Subscribe to PI SENDER's publication
sub = h.helicsFederateRegisterSubscription(vfed, "testA", "")
println("PI RECEIVER: Subscription registered")

h.helicsFederateEnterExecutingMode(vfed)
println("PI RECEIVER: Entering execution mode")

value = 0.0
prevtime = 0

currenttime = -1

while currenttime <= 100
    global currenttime
    currenttime = h.helicsFederateRequestTime(vfed, Float64(100))

    value = h.helicsInputGetString(sub)
    println(
        "PI RECEIVER: Received value = $value at time $currenttime from PI SENDER"
    )
end

h.helicsFederateFinalize(vfed)

h.helicsFederateFree(vfed)
h.helicsCloseLibrary()
println("PI RECEIVER: Federate finalized")
