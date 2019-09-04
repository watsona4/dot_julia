# Joint DC resistivity and travel time tomography example

For testing the joint inversion example we used the file `SEG_DC_EIK_JointInversionTests.jl` which can be run on julia without any parameters. For fast results, use several Julia workers. For choosing between the different tests, see the following lines in the driver:
```
invertDC  = true;
invertEik = true;
invertJoint = invertDC & invertEik
```  
Choose the appropriate combination of flags for the desired experiment.
