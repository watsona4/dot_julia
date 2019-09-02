# Terminology

Illustration of a simple federation consisting of two federates.

```bash
    +--------------------+               +--------------------+
    |                    |               |                    |
    |                    |               |                    |
    |                    |               |                    |
    |                    |               |                    |
    |                    |               |                    |
    |                    |               |                    |
    |                    |               |                    |
    |    Federate - 1    |               |    Federate - 2    |
    |                    |               |                    |
    |                    |               |                    |
    |                    |               |                    |
    |       +-----------------+     +-----------------+       |
    |       |                 |     |                 |       |
    |       |                 |     |                 |       |
    |       | helicsSharedLib |     | helicsSharedLib |       |
    |       |                 |     |                 |       |
    |       |                 |     |                 |       |
    |       +---------------x-+     +-x---------------+       |
    |                    |  ^         ^  |                    |
    +--------------------+  |         |  +--------------------+
                            |         |
                            v         v
                         +--x---------x--+
                         |               |
                         |               |
                         | helics-broker |
                         |               |
                         |               |
                         +---------------+
```

A federation, also called a co-simulation consists of multiple federates, or components, agents or actors.
These federates exchange data at given points in time.
HELICS manages time in a distributed fashion based on how the federation is configured during initialization.
If you have a Julia program, and you wish to exchange data with another HELICS federate, you can create a `Federate` by calling the [`HELICS.helicsCreateCombinationFederate`](@ref) function.
This federate must be provided with some information in order to set it up correctly.
A `FederateInfo` object must be first created in order to set up a `Federate`.
This `FederateInfo` object contains information about what type of communication core is used in HELICS (e.g. `zmq`, `mpi`, `tcp`, `udp`), the name of the `Federate`, where the `Broker` is located, etc.
All `Federate`s must connect to a `Broker`.
A `Broker` is a separate process that can run on the same machine or a remote machine.
You can start a `Broker` by running [`HELICS.helicsCreateBroker`](@ref), or running `helics_broker -f ${NUMBER_OF_FEDERATES}` from the command line.
Both creating a `FederateInfo` and `Broker` object can take some initialization options in the form of a `initstring`.
See the [`examples`](https://github.com/GMLC-TDC/HELICS-Examples) folder for more information.

After creating a `Federate`, you will want to create `Publication`s and `Subscription`s.
The strings you choose for these publications and subscriptions must be unique, and they act like topics in a federation.
You can send data in the form of values from a `Publication` to a `Subscription`.
Additionally, you can register `Endpoint`s as well, which allow you to send `Message`s.
`Message`s can be filtered on by any `Federate` and can be used to model complex communication interactions.

You can use functions like [`HELICS.helicsPublicationPublishDouble`](@ref) to send values at the "current time", and use functions like [`HELICS.helicsSubscriptionGetKey`](@ref) or [`HELICS.helicsInputGetDouble`](@ref) to receive values at the "current time".
You can use functions like [`HELICS.helicsEndpointSendMessage`](@ref) to send messages at the "current time", and use functions like [`HELICS.helicsEndpointGetMessage`](@ref) functions to receive messages that arrived before the "current time".

You can request to move to a time by using the [`HELICS.helicsFederateRequestTime`](@ref) function.
This function returns a time back that you can safely move to.
The time granted will always be less than or equal to the requested time.
If you wish to move to the requested time, you may use a while loop until that the granted time is equal to the requested time.

```julia hl_lines="4 5 6"
for t in 1:100

    requested_time = t
    while granted_time < requested_time
        granted_time = helicsFederateRequestTime(requested_time)
    end

    # granted_time here will be equal to requested time
    # Send or Receive data here

end
```

[`HELICS.helicsFederateRequestTime`](@ref) is a blocking call.
There are other asynchronous request time functions available that allow you to do work while you wait for others to move forward in simulation time.

`helicsSharedLib` is a shared library that is included in the Julia package.
This C/C++ shared library interfaces with the broker in other to communicate with other federates.



