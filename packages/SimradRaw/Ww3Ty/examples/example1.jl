using SimradRaw
using SimradEK60TestData
filename = EK60_SAMPLE # or some other RAW file
datagrams = SimradRaw.load(filename)
