# MDDatasets.jl: The `DataHR` type

## Background

The first multi-dimensional container developped for the `MDDatasets.jl` moduleis called `DataHR`.  If we compare this container with `DataRS` (explained in the principal [README.md](README.md) file):

- **`DataHR` (Hyper-Rectangle)**: Collects simpler data elements (like `DataF1`) into a n-dimensional array.  Each element in `DataHR` is used to store the result of an "experiment", and each array dimension represents an *independent* control variable that was varied (swept).

- **`DataRS` (Recursive Sweep)**: Collects simpler data elements (like `DataF1`) into a recursive data structure.  Each `DataRS` element is used to store the results on an "experiment" (or collection of experiments) where a control variable was varied (swept).  Due to the recursive nature of `DataRS`, each "sweep" can potentially represent a control variable that is *dependent* on a previous "sweep".

Due to the recursive structure of `DataRS`, it is much more difficult to ensure its state is valid.  For example, if `Sweep1 => VDD`, and `Sweep2 => temp`, we could generate the following set of variable combinations:
```
{VDD=0V, temp={0, 100}}
{VDD=1V, temp={0, 25, 85, 125}}
```

As can be seen, for the case of `VDD=0V`, we have ***two*** temperature sub-sweeps, whereas for the case of `VDD=1V`, we have ***four*** temperature sub-sweeps.

***Nonetheless, the flexibility provided by having one of the control variable dependent on a previous sweep variable is quite advantageous***

As a consequence, it is highly suggested that users use the `DataRS` structure instead of the more simple `DataHR` structure.

<a name="SampleUsage_DataHR"></a>
## Usage: Constructing A Hyper-Rectangular Dataset

Assuming input data can be generated using the following:

	t = DataF1((0:.01:10)*1e-9) #Time vector stored as a function of 1 argument

	#NOTE: get_ydata returns type "DataF1" (stores data as a function of 1 argument):
	get_ydata(t::DataF1, tbit, vdd, trise) = sin(2pi*t/tbit)*(trise/tbit)+vdd

One can create a relatively complex Hyper-Rectangular (DataHR) dataset using the following pattern:

	#Parametric sweep representing independent variables of an experiment:
	sweeplist = PSweep[
		PSweep("tbit", [1, 3, 9] * 1e-9)
		PSweep("VDD", 0.9 * [0.9, 1, 1.1])
		PSweep("trise_frac", [0.1, 0.15, 0.2]) #Rise time as fraction of bit rate
	]

	#Generate Hyper-Recangular dataset (DataHR, using dimensions from sweeplist)
	datahr = fill(DataHR{DataF1}, sweeplist) do tbit, vdd, trise_frac
		trise = trise_frac*tbit
		return get_ydata(t, tbit, vdd, trise)
	end

