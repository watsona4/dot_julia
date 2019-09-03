# arithmetic.jl

function Base.:+(qdt::QDate, y::Year)
    qdinfo = QREF.qref(qdt)
    ny = qdinfo.y + value(y)
    nqdinfo = QREF.rqref_strict(ny, qdinfo.m, false, 1)
    nqdinfo1 = QREF.nextmonth(nqdinfo)
    nqdinfo1.m == qdinfo.m && nqdinfo1.leap == qdinfo.leap && (nqdinfo = nqdinfo1)
    ld = QREF.daysinmonth(nqdinfo)
    return jdn2qdate(nqdinfo.j - 1 + (qdinfo.md <= ld ? qdinfo.md : ld))
end
function Base.:-(qdt::QDate, y::Year)
    qdinfo = QREF.qref(qdt)
    ny = qdinfo.y - value(y)
    nqdinfo = QREF.rqref_strict(ny, qdinfo.m, false, 1)
    nqdinfo1 = QREF.nextmonth(nqdinfo)
    nqdinfo1.m == qdinfo.m && nqdinfo1.leap == qdinfo.leap && (nqdinfo = nqdinfo1)
    ld = QREF.daysinmonth(nqdinfo)
    return jdn2qdate(nqdinfo.j - 1 + (qdinfo.md <= ld ? qdinfo.md : ld))
end

const _DAYS_IN_MONTH_F = 29.530589

function Base.:+(qdt::QDate, m::Month)
    oqdinfo = QREF.qref(qdt)
    nqdinfo = QREF._check_qdinfo(QREF.addmonth(oqdinfo, value(m)))
    ld = QREF.daysinmonth(nqdinfo)
    return jdn2qdate(nqdinfo.j - 1 + (oqdinfo.md <= ld ? oqdinfo.md : ld))
end
function Base.:-(qdt::QDate, m::Month)
    oqdinfo = QREF.qref(qdt)
    nqdinfo = QREF._check_qdinfo(QREF.addmonth(oqdinfo, -value(m)))
    ld = QREF.daysinmonth(nqdinfo)
    return jdn2qdate(nqdinfo.j - 1 + (oqdinfo.md <= ld ? oqdinfo.md : ld))
end

function Base.:+(qdt::QDate, d::Day)
    QDate(UTD(days(qdt) + value(d)))
end
function Base.:-(qdt::QDate, d::Day)
    QDate(UTD(days(qdt) - value(d)))
end
