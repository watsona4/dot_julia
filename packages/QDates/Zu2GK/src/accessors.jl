# accessors.jl
import Dates:
    year,
    month,
    day,
    yearmonth,
    monthday,
    yearmonthday,
    days

function year(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    qdinfo.y
end

function month(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    qdinfo.m
end

function day(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    qdinfo.md
end

function yearmonth(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    (qdinfo.y, qdinfo.m)
end

function monthday(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    (qdinfo.m, qdinfo.md)
end

function yearmonthday(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    (qdinfo.y, qdinfo.m, qdinfo.md)
end

function isleapmonth(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    qdinfo.leap
end

function yearmonthleap(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    (qdinfo.y, qdinfo.m, qdinfo.leap)
end

function monthleapday(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    (qdinfo.m, qdinfo.leap, qdinfo.md)
end

function yearmonthleapday(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    (qdinfo.y, qdinfo.m, qdinfo.leap, qdinfo.md)
end

@inline days(qdt::QDate) = value(qdt)
