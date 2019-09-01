# Forestry charts

ForestBiometrics.jl has some graphing functionality including:

## Gingrich stocking chart

      gingrich_chart(tpa_in,basal_area_in)

will return a gingrich style stocking chart with a point (See example on Readme.md on project Github)

## Reineke SDI chart

      sdi_chart(tpa,qmd;max_sdi=450)

will return a stand density index chart with a point placed on tpa and qmd and lines at 35%(crown closure), 55%(competition-induced mortality bound) and 100% of max. max_sdi is an optional kwarg that can be used to change the upper bound. Default max_sdi used is 450. (See example on Readme.md on project Github)
