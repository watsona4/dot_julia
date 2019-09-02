

function user_LogOut()
{
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4)
        {
            if (req.status == 200) // NoContent, got an identity
            {
                location.reload();
                window.location.href = "/static/web/index.html";
/*
                $('#sidebar-div').hide();
                $('#content-div').hide();
                $('#login-div').show();

                $('#form-userid').value = "";
                $('#form-password').value = "";
                $('#login-message').html("Logged out");
                $('#form-userid').focus();
*/
            }
        }
    };

    req.open("POST", "/users/api/request", true);
    req.send(JSON.stringify( { "reqstr" : "user-log-out", "reqdata" : {}}));
}

function onResize()
{
    var n = $("#sidebar-cell");
    n.height($(window).height() - n.position().top - 1);
}


function docReady_CheckLogin(renderSidebarFunc,renderContentFunc)
{
    onResize();
    $(window).resize(onResize);

    $('#login-form').submit( function (event) {
        var username = $('#form-userid').val();
        var password = $('#form-password').val();

        var req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState == 4)
            {
                if (req.status == 200) // Ok, got an identity
                {
                    var data = JSON.parse(req.responseText);

                    $('#form-password').val("");

                    if (renderSidebarFunc != null)
                        renderSidebarFunc(data);
                    if (renderContentFunc != null)
                        renderContentFunc(data);

                    $('#user-id').html(data.Userid);
                    $('#userid-and-logout').show();


                    $('#sidebar-div').show();
                    $('#content-div').show();
                    $('#login-div').hide();

                    window.location.href = "/static/web/index.html";

                }
                else
                {
                    $('#form-password').value = "";
                    $('#login-message').html("Log-in failed");
                    $('#form-password').val("");
                    $('#form-password').focus();
                }
            }

        };

        req.open("POST", "/users/api/login", true);
        req.send(JSON.stringify({"Username":username,"Password":password}));
        event.preventDefault();
    });

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4)
        {
            if (req.status == 200) // NoContent, got an identity
            {
                var data = JSON.parse(req.responseText);

                if (data.Loggedin)
                {
                    if (renderSidebarFunc != null)
                        renderSidebarFunc(data);
                    if (renderContentFunc != null)
                        renderContentFunc(data);

                    $('#user-id').html(data.Userid);
                    $('#userid-and-logout').show();


                    $('#sidebar-div').show();
                    $('#content-div').show();
                    $('#login-div').hide();
                }
                else // session not valid, username provided
                {
                    $('#form-userid').value = data.Userid;
                    $('#login-div').show();
                    $('#form-password').focus();
                }
            }
            else
            {
                $('#login-div').show();
                $('#form-userid').focus();
            }
        }
    };

    req.open("GET", "/users/api/whoami", true);
    req.send();
}


function globToRegex(s)
{
    var r = [];
    for (var i = 0; i < s.length; ++i)
    {
        if (s[i] == '*') r.push(".*");
        else if (s[i] == '?') r.push(".");
        else r.append(s[i]);
    }
    return r.join("");
}


/* Groups
 * 0  - full match
 * 1  - full date part
 * 2  - If not undefined, these groups define the match:
 *    3 - undefined or Month Name
 *    4 - undefined or number (if 4 is defined -> month, otherwise year)
 *    5 - undefined or number (year)
 * 6 - If not undefined, these groups define the match:
 *    7 - Month name
 *    8 - day
 *   OR
 *    10 - year
 *    11 - Month name (excludes 12)
 *    12 - month number (excludes 11)
 *    14 - undefined or day
 * 
*/
var dateregex1 = /^([a-zA-Z]+\b)?\s*(?:([0-9]+\b)\s*([0-9]+\b)?)?/;
var dateregex2 = /^([a-zA-Z]+)-([0-9]+)|(([0-9]+)-(([a-zA-Z]+)|([0-9]+))(-([0-9]+))?)/;
/*
  Date part:
   ([a-zA-Z]+\b)?\s*(?:([0-9]+\b)\s*([0-9]+\b)?)?
   ([a-zA-Z]+)-([0-9]+)|(([0-9]+)-([a-zA-Z]+)(?:-([0-9]+))?)
*/

var MontyDict_ = {
    "jan" : 0, "january"   : 0,
    "feb" : 1, "february"  : 1,
    "mar" : 2, "match"     : 2,
    "apr" : 3, "april"     : 3,
    "may" : 4, "may"       : 4,
    "jun" : 5, "june"      : 5,
    "jul" : 6, "july"      : 6,
    "aug" : 7, "august"    : 7,
    "sep" : 8, "september" : 8,
    "oct" : 9, "october"   : 9,
    "nov" : 10, "november" : 10,
    "dec" : 11, "december" : 11 }

function parseDateStr(s)
{

    if (s.search("-")) //
    var m1 = s.match(dateregex1);
    var m2 = s.match(dateregex2);

    var m = s.match(dateregex);
    var res = new Date();

    var rmonth = -1;
    var ryear  = -1;
    var rday   = -1;

    if (m)
    {
        if (m[1]) // December 21 2012
        {
            var month = res.getMonth();
            var year = res.getFullYear();
            var day = 0;
            if (m[3])
            {
                month = MontyDict_[m[3].toLowerCase()];
                if (!month) { console.log("invalid month"); return; }
            }

            if (m[5])
            {
                year = parseInt(m[5]);
                day  = parseInt(m[4])-1;

                if (day < 0 || day >= 31) { console.log("invalid month"); return; }
            }
            else if (m[4])
            {
                var v = parseInt(m[4])
                if (v < 1 || v > 31) // then it's a year
                    year = v;
                else
                    day = v-1;
            }

            ryear  = year
            rmonth = month+1;
            rday   = day+1;
        }
        else if (m[6]) // 2012-Dec-21
        {
            var month = -1;
            var year  = res.getYear();
            var day   = 0;

            if (m[7])
            {
                month = MontyDict_[m[7].toLowerCase()];
                if (!month) { console.log("invalid month"); return; }

                day = parseInt(m[8])-1;
                if (day < 0 || day >= 31) { console.log("invalid day"); return; }
            }
            else
            {
                year = parseInt(m[10]);
                if (m[11])
                {
                    month = MontyDict_[m[11].toLowerCase()];
                    if (month == undefined) return;
                }
                else
                {
                    month = parseInt(m[12]);
                    if (month == undefined) return;
                    month -= 1;
                }

                if (m[14])
                {
                    day = parseInt(m[14]);
                    if (day == undefined) return;
                    if (day < 1 || day > 31) return;
                }
            }

            ryear = year;
            rmonth = month+1;
            rday = day+1;
        }
    }

    console.log("END: ",ryear,rmonth,rday);

    var res = new Date(""+ryear+"-"+rmonth+"-"+rday);
    if (! isNaN(res.getTime())) return res;
}
