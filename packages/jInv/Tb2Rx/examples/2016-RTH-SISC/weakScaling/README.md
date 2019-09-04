# Weak Scaling Tests


## Travel Time Tomography
For testing the scalability of the travel time tomography using several workers we used the file `runWeakScalingEikonal.jl` which can be run from the command line using 
```
#!/bin/bash
for np in {1..24}
do
	for k in {1..1}
	do
		julia -O -p $np runWeakScalingEikonal.jl --n1 128 --n2 128 --n3 64 --nsources=8 --out=runWeakScalingEikonal.csv 
	done
done
```

## DC Resistivity on Cloud Computing Engine
For testing the scalability of the DC resistivity we used the file `runWeakScalingDivSigGrad.jl` which can be run from the command line using 
```
usage: runWeakScalingDivSigGrad.jl [--n1 N1] [--n2 N2] [--n3 N3]
                        [--srcSpacing SRCSPACING]
                        [--nthreads NTHREADS] [--out OUT]
                        [--solver SOLVER] [-h]
```
We used Amazon EC2 cloud using a generated AMI and initialized 50 instances of which 49 got the tag "workers". Then, we ran a shell script similar to:
```
#!/bin/bash
for np in {1..50}
do
	# get machine file
	ec2-describe-instances --filter "tag:Name=workers" | grep running | awk '{ print $5; }' > mfile
	for s in 3 2 1 # use all solvers
	do
		for k in {1..5} # repeat five times
		do
			julia --machinefile mfile runWeakScalingDivSigGrad.jl --nthreads=2 --n1 48 --n2 48 --n3 24 --srcSpacing 5 --out weakScalingMUMPSAmazon.csv --solver $s
		done
	done
	# terminate one instances and remove from machine file
	ec2-describe-instances  --filter "tag:Name=workers"| grep running | awk '{ print $2; }' > idfile
	tail -1 idfile | xargs -I % sh -c  'ec2-terminate-instances  %'
done

```
