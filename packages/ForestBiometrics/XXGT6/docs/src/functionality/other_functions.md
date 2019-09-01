# Other functions
## Calculating limiting distance for a variable radius plot

While this may not be useful in a programming context, it is a relatively simple function and may be useful for demonstration purposes.

    limiting_distance(baf, dbh, horizontal distance)


## Calculating equilibrium moisture content

Equilibrium moisture content is the content where a piece of wood neither gains or loses moisture. The equation is from
**The National Fire Danger Rating System: Basic Equations;
Jack D Cohen, John E. Deeming. GTR PSW-82**

    emc(relative_humidity::Float64,temp::Float64)
