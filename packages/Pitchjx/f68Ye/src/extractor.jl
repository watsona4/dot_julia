using HTTP
using EzXML
using DataFrames
using Dates

function extract(date)
    result = DataFrame(
        date = String[],
        pitcherid = String[],
        pitcher_teamid = String[],
        pitcher_firstname = String[],
        pitcher_lastname = String[],
        pitcher_teamname = String[],
        pitcherthrow = String[],
        batterid = String[],
        batter_teamid = String[],
        batter_firstname = String[],
        batter_lastname = String[],
        batter_teamname = String[],
        batterstand = String[],
        eventdesc = String[],
        pitchresult = String[],
        x = String[],
        y = String[],
        px = String[],
        pz = String[],
        pfxx = String[],
        pfxz = String[],
        zone = String[],
        sztop = String[],
        szbottom = String[],
        pitchtype = String[],
        startspeed = String[],
        endspeed = String[],
        spindir = String[],
        spinrate = String[],
        nasty = String[]
    )
    year = Dates.year(date)
    month = lpad(Dates.month(date), 2, "0")
    day = lpad(Dates.day(date), 2, "0")
    base = "https://gd2.mlb.com/components/game/mlb/year_$year/month_$month/day_$day"
    gidlist = gethtml(base)
    for li in findall("//li/a/text()",gidlist)
        litext = strip(li.content)
        if occursin(r"gid_*", litext)
            @info "Process dataset: " date "/" litext ": Start"
            playerdf = getplayers(base, litext, date)
            pitchdf = getpitches(base, litext, date)
            processdf = join(pitchdf, playerdf, on=(:pitcherid, :id), kind=:inner, makeunique=true)
            df = join(processdf, playerdf, on=(:batterid, :id), kind=:inner, makeunique=true)
            df = rename(df, [
                    :firstname => :pitcher_firstname,
                    :lastname => :pitcher_lastname,
                    :teamname => :pitcher_teamname,
                    :teamid => :pitcher_teamid,
                    :firstname_1 => :batter_firstname,
                    :lastname_1 => :batter_lastname,
                    :teamname_1 => :batter_teamname,
                    :teamid_1 => :batter_teamid,
                ]
            )
            result = vcat(result, df[
                [
                    :date,
                    :pitcherid,
                    :pitcher_teamid,
                    :pitcher_firstname,
                    :pitcher_lastname,
                    :pitcher_teamname,
                    :pitcherthrow,
                    :batterid,
                    :batter_teamid,
                    :batter_firstname,
                    :batter_lastname,
                    :batter_teamname,
                    :batterstand,
                    :eventdesc,
                    :pitchresult,
                    :x,
                    :y,
                    :px,
                    :pz,
                    :pfxx,
                    :pfxz,
                    :zone,
                    :sztop,
                    :szbottom,
                    :pitchtype,
                    :startspeed,
                    :endspeed,
                    :spindir,
                    :spinrate,
                    :nasty
                ]
            ])
            @info "Process dataset: " date "/" litext ": Finish!"
        end
    end
    return result
end

function gethtml(url)
    r = HTTP.get(url)
    if 200 <= r.status < 300
        return root(parsehtml(String(r.body)))
    else
        error("Page is not accessable.")
    end
end

function getxml(url)
    r = HTTP.get(url)
    if 200 <= r.status < 300
        return root(parsexml(String(r.body)))
    else
        error("Page is not accessable.")
    end
end

function getplayers(base, gid, date)
    playerdf = DataFrame(
        date = String[],
        id = String[],
        firstname = String[],
        lastname = String[],
        teamid = String[],
        teamname = String[]
    )
    url = base * "/" * gid * "players.xml"
    players = getxml(url)
    for player in findall("//player", players)
        try
            id = player["id"]
            firstname = player["first"]
            lastname = player["last"]
            teamid = player["team_id"]
            teamname = player["team_abbrev"]
            push!(playerdf, [Dates.format(date, "yyyy-mm-dd"), id, firstname, lastname, teamid, teamname])
        catch
            @warn "player tag " player " is not extractable."
        end
    end
    return playerdf
end

function getpitches(base, gid, date)
    pitchdf = DataFrame(
        date = String[],
        pitcherid = String[],
        batterid = String[],
        pitcherthrow = String[],
        batterstand = String[],
        eventdesc = String[],
        pitchresult = String[],
        x = String[],
        y = String[],
        px = String[],
        pz = String[],
        pfxx = String[],
        pfxz = String[],
        zone = String[],
        sztop = String[],
        szbottom = String[],
        pitchtype = String[],
        startspeed = String[],
        endspeed = String[],
        spindir = String[],
        spinrate = String[],
        nasty = String[]
    )
    url = base * "/" * gid * "inning/inning_all.xml"
    pitches = getxml(url)
    for atbat in findall("//atbat", pitches)
        pitcherid = atbat["pitcher"]
        batterid = atbat["batter"]
        pitcherthrow = atbat["p_throws"]
        batterstand = atbat["stand"]
        eventdesc = atbat["des"]
        for pitch in findall("./pitch", atbat)
            try
                pitchresult = pitch["des"]
                x = pitch["x"]
                y = pitch["y"]
                px = pitch["px"]
                pz = pitch["pz"]
                pfxx = pitch["pfx_x"]
                pfxz = pitch["pfx_z"]
                zone = pitch["zone"]
                sztop = pitch["sz_top"]
                szbottom = pitch["sz_bot"]
                pitchtype = pitch["pitch_type"]
                startspeed = pitch["start_speed"]
                endspeed = pitch["end_speed"]
                spindir = pitch["spin_dir"]
                spinrate = pitch["spin_rate"]
                nasty = pitch["nasty"]
                push!(pitchdf, [
                    Dates.format(date, "yyyy-mm-dd"),
                    pitcherid,
                    batterid,
                    pitcherthrow,
                    batterstand,
                    eventdesc,
                    pitchresult,
                    x,
                    y,
                    px,
                    pz,
                    pfxx,
                    pfxz,
                    zone,
                    sztop,
                    szbottom,
                    pitchtype,
                    startspeed,
                    endspeed,
                    spindir,
                    spinrate,
                    nasty
                    ]
                )
            catch
               @warn "pitch tag " pitch " is not extractable."
            end
        end
    end
    return pitchdf
end
