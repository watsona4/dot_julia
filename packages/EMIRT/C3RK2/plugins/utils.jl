using DataFrames
using EMIRT

"""
transform error curve to dataframe
"""
function ec2df(ec::ScoreCurve, ecname::Symbol=:ecname)
    df = DataFrame()
    for (k,v) in ec
        df[k] = v
    end
    df[:tag] = ecname
    return df
end

"""
transfer error curves to dataframe
"""
function ecs2df(ecs::ScoreCurves)
    df = DataFrame()
    for (ecname,ec) in ecs
        if isempty(df)
            df = ec2df(ec, ecname)
        else
          metrics = collect(keys(first(values(ecs))))
          @show metrics
          df = join(df, ec2df(ec, ecname), on=metrics, kind=:outer)
        end
    end
    return df
end
