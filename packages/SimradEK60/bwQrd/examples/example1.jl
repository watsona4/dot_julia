using SimradEK60
using SimradEK60TestData
filename = EK60_SAMPLE
ps = SimradEK60.load(filename)
ps38 = [p for p in ps if p.frequency == 38000]
Sv38 = Sv(ps38) # Volume backscatter
al38 = alongshipangle(ps38) # Split beam angle
at38 = athwartshipangle(ps38)
_R = R(ps38) # Range / depth
_t = filetime(ps38) # timestamps
