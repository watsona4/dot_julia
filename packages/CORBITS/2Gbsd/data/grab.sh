#!/bin/bash

today=$(date -I)
name="koi-data" #"koi-$today"

#download data from the Exoplanet Archive
#query api: http://exoplanetarchive.ipac.caltech.edu/docs/program_interfaces.html

wget "http://exoplanetarchive.ipac.caltech.edu/cgi-bin/nstedAPI/nph-nstedAPI?table=q1_q17_dr24_koi&select=kepid,kepoi_name,koi_period,koi_period_err1,koi_impact,koi_impact_err1,koi_incl,koi_sma,koi_dor,koi_ror,koi_prad,koi_srad,koi_model_snr,koi_slogg&order=kepoi_name&where=koi_disposition+like+'C%25'&format=ascii" -O data/$name.txt &> data/grab.log

#remove first few lines of file and any null content
sed -e "/[/\|].*/d" -e "/.*null.*/d" "data/$name.txt" > "data/$name-edit.txt"
