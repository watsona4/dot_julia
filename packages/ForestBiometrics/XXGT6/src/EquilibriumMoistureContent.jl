#Equilibrium Moisture Content
#The National Fire Danger Rating Sysytem: Basic Equations
#Jack D Cohen, John E. Deeming
#GTR PSW-82

function emc(relative_humidity::Float64,temp::Float64)
    if relative_humidity < 10.0
        emc = 0.03229 + 0.281073 * relative_humidity - 0.000578 * temp * relative_humidity
    elseif relative_humidity >= 10.0 && relative_humidity < 50.0
        emc = 2.22749+0.160107 * relative_humidity - 0.014784 * temp
    else
        emc = 21.0606 + 0.005565 * relative_humidity ^ 2 - 0.00035 * relative_humidity * temp - 0.483199 * relative_humidity
    end
end
