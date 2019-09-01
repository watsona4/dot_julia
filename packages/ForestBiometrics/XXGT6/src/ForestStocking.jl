#Reineke SDI calculation
function sdi(tpa,qmd)
    sdi=tpa*(qmd/10.0)^1.605
end

function qmd(ba, tpa, constant)
    qmd=sqrt((ba/tpa)/constant)
end
