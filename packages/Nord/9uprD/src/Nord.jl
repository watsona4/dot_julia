# This package provides colours from the popular nord project, which can be found at:
#     <https://github.com/arcticicestudio/nord>

module Nord

using Colors, ColorTypes, FixedPointNumbers

# Dictionaries of colours
export NordColours, PolarNight, SnowStorm, Frost, Aurora

const nord0 = colorant"#2E3440"
const nord1 = colorant"#3B4252"
const nord2 = colorant"#434C5E"
const nord3 = colorant"#4C566A"
const nord4 = colorant"#D8DEE9"
const nord5 = colorant"#E5E9F0"
const nord6 = colorant"#ECEFF4"
const nord7 = colorant"#8FBCBB"
const nord8 = colorant"#88C0D0"
const nord9 = colorant"#81A1C1"
const nord10 = colorant"#5E81AC"
const nord11 = colorant"#BF616A"
const nord12 = colorant"#D08770"
const nord13 = colorant"#EBCB8B"
const nord14 = colorant"#A3BE8C"
const nord15 = colorant"#B48EAD"

const black = nord0
const grey = nord3
const white = nord6
const blue = nord9
const red = nord11
const orange = nord12
const yellow = nord13
const green = nord14

const info = white
const debug = grey
const pass = green
const warn = yellow
const fail = red
const error = red

const NordColours = Dict("nord0" => nord0,
                         "nord1" => nord1,
                         "nord2" => nord2,
                         "nord3" => nord3,
                         "nord4" => nord4,
                         "nord5" => nord5,
                         "nord6" => nord6,
                         "nord7" => nord7,
                         "nord8" => nord8,
                         "nord9" => nord9,
                         "nord10" => nord10,
                         "nord11" => nord11,
                         "nord12" => nord12,
                         "nord13" => nord13,
                         "nord14" => nord14,
                         "nord15" => nord15,
                         )

const PolarNight = Dict("nord0" => nord0,
                        "nord1" => nord1,
                        "nord2" => nord2,
                        "nord3" => nord3
                        )

const SnowStorm = Dict("nord4" => nord4,
                       "nord5" => nord5,
                       "nord6" => nord6
                       )

const Frost = Dict("nord7" => nord7,
                   "nord8" => nord8,
                   "nord9" => nord9,
                   "nord10" => nord10,                   
                  )

const Aurora = Dict("nord11" => nord11,
                    "nord12" => nord12,
                    "nord13" => nord13,
                    "nord14" => nord14,
                    "nord15" => nord15,
                   )

end # module
