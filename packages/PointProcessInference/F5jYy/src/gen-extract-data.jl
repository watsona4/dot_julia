
function registerdatadeps()
    register(DataDep("mass-shooting", "", "https://www.dropbox.com/s/6zr083w4hbia4d0/years_passed.csv?dl=1"))
    register(DataDep("coal", "", "https://www.dropbox.com/s/uy6j8wru1nkqhw5/coal.csv?dl=1"))

    
    register(DataDep("pptest", "", [
        "https://www.dropbox.com/s/kcqe58li0pevn3g/testdat_n1.csv?dl=1"
        "https://www.dropbox.com/s/hpcu0n4xdes2sbn/testdat_n5.csv?dl=1"
        "https://www.dropbox.com/s/65i1fc7bo6uk206/testdat_n4000.csv?dl=1"
        "https://www.dropbox.com/s/88iwtx60ziwevz4/simpson_n500.csv?dl=1"
        "https://www.dropbox.com/s/qi8h75tdzj30adc/simpson_n200.csv?dl=1"
        "https://www.dropbox.com/s/nsbirz2o5lq0qq6/unit_intensity.csv?dl=1"
        ]))

    register(DataDep("tweettime", "", [
        "https://www.dropbox.com/s/psjvi58hxbvsqpo/android_hours.csv?dl=1"
        "https://www.dropbox.com/s/101esqt30ty01ut/iphone_early_hours.csv?dl=1"
        "https://www.dropbox.com/s/41kxtq0ojxmbuaa/iphone_late_hours.csv?dl=1"
        ]))
end

"""
loadexample(data_choice) -> observations, (T = T, n = n), λinfo

Load example data for one of the examples

    generated
    mass-shooting
    coal
    testdat_n1
    testdat_n5
    testdat_n4000
    simpson_n200
    simpson_n500
    unit_intensity
    android
    iphone_early
    iphone_late
    sum_android_iphone_early

Returns the observation vector, and a named tuple of `T` (endtime) and `n`
observation multiplicity and a named tuple giving additional info about the
true density (if applicable).
"""
function loadexample(data_choice)
    λ = missing
    λmax = missing

    if data_choice=="generated"
        ### Option 1: simulated data, by specifying
        # T, n, λ and λmax (the maximum of λ on [0,T])
        T = 10.0   # observation interval
        n = 500   # number of copies of PPP observed
        # Specify intensity function
        λ = x ->  2* (5 + 4*cos(x)) * exp(-x/5)
        λmax = λ(0.0)
        observations = samplepoisson((x,n)->λ(x)*n, n*λmax, 0.0, T, n)   # sample ppp on [0,T] with intensity function λ
    elseif data_choice=="mass-shooting"
        ### Read mass shooting data
        n = 1
        # in case we use years passed
        yp=readdlm(datadep"mass-shooting/years_passed.csv")
        observations = float.(yp[2:end])
        T = last(observations) + 28/365  # add 4 weeks
    elseif data_choice=="coal"
        ### Read coal mining disaster data
        n = 1
        coal=readdlm(datadep"coal/coal.csv")
        observations = float.(coal[2:end])
        T = last(observations)
    elseif data_choice=="testdat_n1"
        n = 1
        observations = vec(readdlm(datadep"pptest/testdat_n1.csv"))
        T = 10.0
        λ = function(x::Float64)
            2* (5 + 4*cos(x)) * exp(-x/5)
        end
        λmax = λ(0.0)
    elseif  data_choice=="testdat_n5"
        n = 5
        observations = vec(readdlm(datadep"pptest/testdat_n5.csv"))
        T = 10.0
        λ = function(x::Float64)
             2* (5 + 4*cos(x)) * exp(-x/5)
        end
        λmax = λ(0.0)
    elseif  data_choice=="testdat_n4000"
        n = 4000
        observations = vec(readdlm(datadep"pptest/testdat_n4000.csv"))
        T = 10.0
        λ = function(x::Float64)
             2* (5 + 4*cos(x)) * exp(-x/5)
        end
        λmax = λ(0.0)
    elseif  data_choice=="simpson_n200"
        n = 200
        observations = vec(readdlm(datadep"pptest/simpson_n200.csv"))
        T = 6.0
        λ = function(x::Float64)
            y = 0.5 * pdf(Normal(3,1), x)
            for j=0:4
              y += 0.1 * pdf(Normal(j/2-1,0.1), x-3)
            end
            y
        end
        λmax = λ(3.0)
    elseif     data_choice=="simpson_n500"
        n = 500
        observations = vec(readdlm(datadep"pptest/simpson_n500.csv"))
        T = 6.0
        λ = function(x::Float64)
            y = 0.5 * pdf(Normal(3,1), x)
            for j=0:4
                y += 0.1 * pdf(Normal(j/2-1,0.1), x-3)
            end
            y
        end
        λmax = λ(3.0)
    elseif     data_choice=="android"
        andr = vec(readdlm(datadep"tweettime/android_hours.csv"))
        observations = float.(andr[2:end])
        n = 147  # so get intensity per hour
        T = 24.0
    elseif  data_choice=="iphone_early"
        iph = vec(readdlm(datadep"tweettime/iphone_early_hours.csv"))
        observations = float.(iph[2:end])
        n = 147  # so get intensity per hour
        T = 24.0
    elseif data_choice=="iphone_late"
        iph = vec(readdlm(datadep"tweettime/iphone_late_hours.csv"))
        observations = float.(iph[2:end])
        n = 282  # so get intensity per hour
        T = 24.0
    elseif data_choice=="sum_android_iphone_early"
        andr = vec(readdlm(datadep"tweettime/android_hours.csv"))
        iph = vec(readdlm(datadep"tweettime/iphone_early_hours.csv"))
        observations = vcat(float.(iph[2:end]),float.(andr[2:end]))
        n = 147  # so get intensity per hour
        T = 24.0
    elseif   data_choice=="unit_intensity"
        observations = vec(readdlm(datadep"pptest/unit_intensity.csv"))
        n = 1
        T = 50.0
        λ = function(x::Float64)
            1.0
        end
    else
        throw(ArgumentError("Invalid `data_choice.`"))
    end
    return observations, (title=data_choice, T = T, n = n), (λ = λ, λmax = λmax)
end
