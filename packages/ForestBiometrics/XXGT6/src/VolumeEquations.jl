#CONSTANTS
#K = 0.005454 - converts diameter squared in square inches to square feet.
#0.00007854 converts diamter square centimeters to square meters
const K = 0.005454154
const KMETRIC = 0.00007854

abstract type Log end

mutable struct LogSegment<:Log
small_end_diam
large_end_diam
length
#shape #?
end

abstract type Shape end

function area(diameter)
    a=K * diameter^2
    return a
end

#Table 6.1 form Kershaw et al Forest Mensuration
#Equations to compute Cubic Volume of Important Solids

# Equation 6.1
#V=AₗL where Aₗ is the area of the base(large end).
mutable struct Cylinder
length
large_end_diam
end

function volume(solid::Cylinder)
    V = area(solid.large_end_diam)*solid.length
    return V
end

#Equation 6.2
#V= 1/2(AₗH)
#Paraboloid

mutable struct Paraboloid
length
large_end_diam
end

function volume(solid::Paraboloid)
    V = 1/2(area(solid.large_end_diam))*solid.length
    V
end

#Equation 6.3
#V=1/3(AₗL)
#Cone
#PREDICT CUBIC FOOT VOLUME FOR A CONIC SEGMENT SUCH AS A STEM TIP
mutable struct Cone
length
large_end_diam
end

function volume(solid::Cone)
    V = 1/3(area(solid.large_end_diam))*solid.length
    return V
end

#Equation 6.4
#V=1/4(AₗL)
#Neiloid

mutable struct Neiloid
length
large_end_diam
end

function volume(solid::Neiloid)
    V = 1/4(area(solid.large_end_diam))*solid.length
    return V
end

#Equation 6.5- Smalian's formula
#V=L/2(Aₗ + Aₛ) where L is the length and Aₛ is the area of the upper end (or small end)
#Paraboloid frustrum

#Equation 6.6 - Huber's formula
#V=AₘL where Aₘ is the area at middle point
#Paraboloid frustrum

#Equation 6.9 - Newton's formula
#V=L/6(Aₗ + 4*Aₘ + Aₛ)
#Neiloid,Paraboloid or Conic Frustrum

mutable struct ParaboloidFrustrum
length
large_end_diam
mid_point_diam #can set to nothing ( or missing in 0.7.0+?)
small_end_diam
end


function volume(solid::ParaboloidFrustrum; huber=false, newton = false)
    if huber == true
        V = area(solid.mid_point_diam) * solid.length
    elseif newton == true
        V = (solid.length/6) * (area(solid.large_end_diam) + 4*area(solid.mid_point_diam) + area(solid.small_end_diam))
    else
        V = area(solid.large_end_diam) + area(solid.small_end_diam) * (solid.length/2)
    end
return V
end

#Equation 6.7
#V=L/3(Aₗ + sqrt(Aₗ*Aₛ) + Aₛ)

mutable struct ConeFrustrum
length
large_end_diam
mid_point_diam #can set to nothing
small_end_diam
end

function volume(solid::ConeFrustrum; newton=false)
    if newton == true
        V = (solid.length/6) * (area(solid.large_end_diam) + 4*area(solid.mid_point_diam) + area(solid.small_end_diam))
        else
            V = area(solid.large_end_diam) + area(solid.small_end_diam) * (solid.length/2)
    end
return V
end

#Equation 6.8
#V=L/4(Aₗ + cbrt(Aₗ²*Aₛ) + cbrt(Aₗ*Aₛ²) + Aₛ)

mutable struct NeiloidFrustrum
length
large_end_diam
mid_point_diam #can set to nothing
small_end_diam
end

function volume(solid::NeiloidFrustrum; newton=false)
    if newton == true
        V = (solid.length/6) * (area(solid.large_end_diam) + 4*area(solid.mid_point_diam) + area(solid.small_end_diam))
    else
        V = (solid.length/4) *
        (cbrt(area(solid.large_end_diam)^2 * area(solid.small_end_diam)) +
        cbrt((K * solid.large_end_diam^2) * area(solid.small_end_diam)^2) +
        area(solid.small_end_diam))
    end
return V
end

macro LogSegment(a,b,c,d,shape)
    return :($shape($a,$b,$c,$d))
end

#@LogSegment(24,12,nothing,8,ParaboloidFrustrum)

#Function to calculate the Scribner scale volume
#for more info see: http://oak.snr.missouri.edu/forestry_functions/scribnerbfvolume.php

## Scribner Decimal C table
using OffsetArrays
scribner_decimal_c=OffsetArray([[5 5 5 5 5 5 10 10 10 10 10 10 20 20 20 20 20];
[5 5 5 5 5 5 10 10 10 10 10 10 20 20 20 20 20];
[5 5 5 10 10 10 10 20 20 20 20 20 30 30 30 30 30];
[5 10 10 10 10 10 20 20 20 20 20 20 30 30 30 30 30];
[10 10 10 20 20 20 30 30 30 30 30 30 40 40 40 40 40];
[10 10 20 20 30 30 30 30 30 40 40 50 60 60 60 60 70];
[10 20 20 20 30 30 40 40 40 50 50 60 70 70 80 80 80];
[20 20 30 30 40 40 50 50 60 60 70 70 80 80 90 100 100];
[20 30 40 40 50 50 60 70 70 80 80 90 100 100 110 120 120];
[30 40 40 50 60 60 70 80 90 90 100 110 110 120 130 140 140];
[40 40 50 60 70 80 90 100 110 120 120 130 140 150 160 170 180];
[40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200];
[50 60 70 80 90 100 120 130 140 150 160 170 180 200 210 220 230];
[50 70 80 90 110 120 130 150 160 170 190 200 210 230 240 260 270];
[60 80 90 100 120 130 150 160 180 190 210 220 240 250 270 280 300];
[70 90 110 120 140 160 170 190 210 230 240 260 280 300 310 330 350];
[80 100 120 130 150 170 190 210 230 250 270 280 300 320 340 360 380];
[80 100 130 150 170 190 210 230 250 270 290 310 330 350 380 400 420];
[90 120 140 160 190 210 230 260 280 310 330 350 380 400 420 440 470];
[100 130 150 180 210 230 250 280 300 330 350 380 400 430 450 480 500];
[110 140 170 200 230 260 290 310 340 370 400 430 460 490 520 540 570];
[120 160 190 220 250 280 310 340 370 410 440 470 500 530 560 590 620];
[140 170 210 240 270 310 340 380 410 440 480 510 550 580 620 650 680];
[150 180 220 250 290 330 360 400 440 470 510 540 580 620 650 690 730];
[150 190 230 270 310 350 380 420 460 490 530 570 610 650 680 720 760];
[160 210 250 290 330 370 410 450 490 530 570 620 660 700 740 780 820];
[180 220 270 310 360 400 440 490 530 580 620 670 710 750 800 840 890];
[180 230 280 320 370 410 460 510 550 600 640 690 740 780 830 880 920];
[200 240 290 340 390 440 490 540 590 640 690 730 780 830 880 930 980];
[200 250 300 350 400 450 500 550 600 650 700 750 800 850 900 950 1000];
[220 270 330 380 440 490 550 600 660 710 770 820 880 930 980 1040 1090];
[230 290 350 400 460 520 580 630 690 750 810 860 920 980 1040 1100 1150];
[260 320 390 450 510 580 640 710 770 840 900 960 1030 1090 1160 1220 1290];
[270 330 400 470 540 600 670 730 800 870 930 1000 1070 1130 1200 1260 1330];
[280 350 420 490 560 630 700 770 840 910 980 1050 1120 1190 1260 1330 1400];
[300 380 450 530 600 680 750 830 900 980 1050 1130 1200 1280 1350 1420 1500];
[320 390 480 560 640 720 790 870 950 1030 1110 1190 1270 1350 1430 1510 1590];
[330 420 500 590 670 760 840 920 1010 1090 1170 1260 1340 1430 1510 1600 1680];
[350 430 520 610 700 790 870 960 1050 1130 1220 1310 1400 1480 1570 1660 1740];
[370 460 560 650 740 830 930 1020 1110 1200 1290 1390 1480 1570 1660 1760 1850];
[380 470 570 660 760 850 950 1040 1140 1230 1330 1430 1520 1610 1710 1800 1900];
[390 490 590 690 790 890 990 1090 1190 1290 1390 1490 1590 1690 1780 1880 1980];
[410 520 620 720 830 930 1040 1140 1240 1340 1450 1550 1660 1760 1860 1960 2070];
[430 540 650 760 860 970 1080 1190 1300 1400 1510 1620 1730 1840 1940 2050 2160];
[450 560 670 790 900 1010 1120 1240 1350 1460 1570 1680 1800 1910 2020 2140 2250];
[470 580 700 820 940 1050 1170 1290 1400 1520 1640 1750 1870 1990 2110 2220 2340]],5:50,4:20)

function scribner_volume(small_end_diam,length;decimal_C=false)
    if decimal_C==false
    log_bf=((0.79*small_end_diam^2)-(2*small_end_diam)-4)*(length/16)
    return log_bf
    elseif decimal_C==true
        # ROUND DIB TO NEAREST INTEGER, ROUND LOGFEET DOWN TO NEXT INTEGER
        scale_dib=ceil(Int64,small_end_diam)
        log_feet=floor(Int64,length)
        println(scale_dib,log_feet)
        if scale_dib > 5 && scale_dib < 50 && log_feet > 4 && log_feet < 20
            #STANDARD SIZE LOG, USE LOOKUP TABLE
            log_bf=scribner_decimal_c[scale_dib,log_feet]*1.0
        else
        #OVERSIZE LOG, I.E., DIB>50 AND/OR LOGLENGTH>20, USE FORMULA VERSION
            log_bf=scribner_volume(scale_dib,log_feet,decimal_C=false)
        return log_bf
        end
    end
 end

 #Function to calculate the Doyle scale volume
 #for more info see: http://oak.snr.missouri.edu/forestry_functions/doylebfvolume.php
 function doyle_volume(small_end_diam,length)
   volume=((small_end_diam-4.0)/4.0)^2*length
  return volume
   end

#Function to calculate the International scale volume
#for more info see: http://oak.snr.missouri.edu/forestry_functions/int14bfvolume.php
function international_volume(small_end_diam,length)
  if length == 4
      volume = 0.22*small_end_diam^2-0.71*small_end_diam
    elseif length == 8
      volume = 0.44*small_end_diam^2-1.20*small_end_diam-0.30
    elseif length == 12
      volume = 0.66*small_end_diam^2 - 1.47 * small_end_diam - 0.79
    elseif length == 16
      volume = 0.88 * small_end_diam^2 - 1.52 * small_end_diam - 1.36
    elseif length == 20
      volume = 1.10 * small_end_diam^2 - 1.35 * small_end_diam - 1.90
    elseif length == 24
      volume = 1.10 * small_end_diam^2 - 1.35 * small_end_diam - 1.90 + 0.22 * small_end_diam^2 - 0.71 * small_end_diam
    elseif length == 28
      volume = 1.10 * small_end_diam^2 - 1.35 * small_end_diam - 1.90 + 0.44 * small_end_diam^2 - 1.20 * small_end_diam - 0.30
    elseif length == 32
      volume = 1.10 * small_end_diam^2 - 1.35 * small_end_diam - 1.90 + 0.66 * small_end_diam^2 - 1.47 * small_end_diam - 0.79
    elseif length == 36
      volume = 1.10 * small_end_diam^2 - 1.35 * small_end_diam - 1.90 + 0.88 * small_end_diam^2 - 1.52 * small_end_diam - 1.36
    elseif length == 40
      volume = (1.10 * small_end_diam^2 - 1.35 * small_end_diam - 1.90 )*2
      return volume
    end
  end

####
#I don't know what a NVEL/Volume Equations API should look like?
#Various attempts below...
#introduce abstract super types
abstract type VolumeEquation end
abstract type MerchSpecs end

mutable struct Sawtimber<:MerchSpecs
std_length
trim
min_length
max_length
min_dib
stumpht
end
s=Sawtimber(16.0,0.5,8.0,20.0,6.0,1.0)

mutable struct Fiber<:MerchSpecs
min_length
std_length
min_dib
min_dbh
end
#Fiber(8.0,20.0,2.6,4.6)

mutable struct Pulp<:MerchSpecs
min_live_dib #pulp sawlogs
min_dead_dib #pulp sawlogs
end
#Pulp(6.0,6.0)

####work in progress
#bark thickness separate?
function dib_to_dob() end

#PREDICT DIAMETER INSIDE BARK AT ANY LOGICAL HEIGHT
function get_dib(species,dbh,tht,ht)
end

#PREDICT THE HEIGHT AT WHICH A SPECIFIED DIAMETER INSIDE BARK OCCURS
function get_height_to_dib(species,dbh,tht,dib)
 end

#TO BREAK A SAWTIMBER BOLE INTO LOGS AND POPULATE THE SEGMENT LENGTH
function stem_buck(m::Sawtimber)
    #DETERMINE LENGTH OF BOLE TO DIVIDE INTO LOGS
    bole_length=52.9815
    #bole_length=ht2sawdib-stumpht
    #DETERMINE THE NUMBER OF FULL STANDARD LENGTH LOGS POSSIBLE
    n_logs=floor(Int64,bole_length/(m.std_length+m.trim))
    #POPULATE SEGLEN WITH STANDARD LOG LENGTHS TO START
    seg_length=zeros(n_logs)
    for i in 1:n_logs
        seg_length[i]=m.std_length+m.trim
    end
#ADJUST LOG LENGTHS ACCORDING TO BUCKING RULE AND AMOUNT OF SAWTIMBER EXCESS
    saw_excess=bole_length-n_logs*(m.std_length+m.trim)
    isaw_excess=floor(Int64,saw_excess/2.0)*2
    if n_logs == floor(Int64,n_logs/2.0)*2
        even=true
    else
        even=false
    end
    if isaw_excess >=2.0 && isaw_excess<6.0       #EXTRA SAWEXCESS IS  2' OR 4'
        if even
            if isaw_excess == 2.0
                 seg_length[n_logs-1]=seg_length[n_logs-1]+2.0 # Add 2' to last log
             else
                 seg_length[n_logs-1]=seg_length[n_logs-1]+2.0 # Add 2' to top 2 logs
                 seg_length[n_logs]=seg_length[n_logs]+2.0
             end
        else
            seg_length[n_logs]=seg_length[n_logs] + isaw_excess #Add 2' or 4' to top log
         end
    elseif isaw_excess>=6.0
        if (saw_excess-m.trim) >= m.min_length
            n_logs=n_logs+1 # Create whole new log
            push!(seg_length,isaw_excess+m.trim)
            #seg_length[n_logs]=isaw_excess+m.trim
        else
            n_logs=n_logs+1 # Create new log, split top
            saw_excess=saw_excess+seg_length[n_logs-1]
            seg_length[n_logs]=floor(Int64,saw_excess-(2.0*m.trim)/4.0)*2.0+m.trim
            seg_length[n_logs-1]=floor(saw_excess-seg_length[n_logs]-m.trim/2.0)*2.0+m.trim
        end
    end
    #FAILSAFE TO ENSURE LOGS ARE OF SUFFICIENT LENGTH (B/T MIN SCALE LEN AND MAXLEN)
    sawtop=m.stumpht
    for i in 1:n_logs
        if seg_length[i]<(m.min_length+m.trim)
            seg_length[i]=0
        elseif seg_length[i] > (m.max_length+m.trim)
            seg_length[i]=(m.max_length+m.trim)
        end
        #DETERMINE SAWTOP
        sawtop=seg_length[i]
    return seg_length
    end
end
stem_buck(s)


function stem_buck(m::Fiber)
    fiber_bole=30
#DETERMINE THE NUMBER OF FULL STANDARD LENGTH FIBER LOGS POSSIBLE
n_logs_fiber=floor(Int64,bole_length/m.std_length)

#POPULATE SEGLEN WITH STANDARD LOG LENGTHS TO START
for i in n_logs+1:n_logs+n_logs_fiber
    seg_length[i]=m.std_length
end

#SEE IF ADDITIONAL FIBER ABOVE STANDARD LENGTH LOGS CONSTITUTES A FIBER LOG
fiber_excess=fiber_bole-(n_logs_fiber*m.std_length)
if fiber_excess>m.min_length
    n_logs_fiber=n_logs_fiber+1
    seg_length[n_logs+n_logs_fiber] = fiber_excess
end
end
#TO ASSIGN PRODUCT CLASSES TO EACH LOG SEGMENT IN A SINGLE TREE
function prod_classify()
end

#TO MERCHANDIZE AN INDIVIDUAL TREE WITH PREVIOUSLY BUCKED LOGS AND
#PRODUCTS ASSIGNED TO INDIVIDUAL LOGS INTO PIECES, AND DEVELOP THE NECESSARY PIECE INFORMATION (DIB,LEN,GRS,NET,NPCS)
function merchandize_tree() end
