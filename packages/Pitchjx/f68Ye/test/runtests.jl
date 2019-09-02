using Test
using Pitchjx
using DataFrames

# test for no game day.
empty = DataFrame(
  date=String[],
  pitcherid=String[],
  pitcher_teamid=String[],
  pitcher_firstname=String[],
  pitcher_lastname=String[],
  pitcher_teamname=String[],
  pitcherthrow=String[],
  batterid=String[],
  batter_teamid=String[],
  batter_firstname=String[],
  batter_lastname=String[],
  batter_teamname=String[],
  batterstand=String[],
  eventdesc=String[],
  pitchresult=String[],
  x=String[],
  y=String[],
  px=String[],
  pz=String[],
  sztop=String[],
  szbottom=String[],
  pitchtype=String[],
  startspeed=String[],
  endspeed=String[],
  spindir=String[],
  spinrate=String[]
)

@test pitchjx("2018-01-01") == empty
