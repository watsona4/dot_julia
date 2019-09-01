# Grace/Linux Crash Issue

On certain installations, Grace has been noticed to suffer severe crashes that will boot users entirely out of their session (to the login screen).

## Offending Installation

The crash issue was noticed with the following setup:
 - Ubuntu 14.04.3LTS (Trusty)
 - Grace 5.1.23 (Installed with `apt-get install grace`)
 - Intel i5.

## Additional Conditions

The crash issue was observed only when Ubuntu was installed directly on the machine.  Interestingly enough, the problem was not present on Grace sessions launched within a VMWare session (i.e. i5|Trusty|VMWare|Trusty|Grace).

## Test code

The following test code almost always causes the i5|Ubuntu(Trusty)|Grace installation to crash Ubuntu back to its login screen:

```
#!/bin/bash
#CMD='map color 0 to (128, 128, 128), "white"'
CMD="ARRANGE(2, 3, 0.15, 0.15, 0.15)"
for i in `seq 1 15`; do
	echo $CMD|xmgrace -dpipe 0 -nosafe -noask&
done
```

