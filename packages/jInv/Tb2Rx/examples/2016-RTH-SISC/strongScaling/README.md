# Strong Scaling Tests

## Coputing the data for the DC resistivity
For testing the scalability of the DC resistivity we used the file `runStrongScalingGetDataNthreads.jl` which can be run from the command line using 
```
#!/bin/bash
for np in {1..1}
do
	for k in {1,2,4,8,12,16}
	do
		julia -O -p $np runStrongScalingGetDataNthreads.jl --n1 256 --n2 256 --n3 128 --srcSpacing 40 --nthreads $k --out=runStrongScalingGetData.csv --solver 4 
	done
done
```
