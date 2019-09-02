
/***********************************************************
 *  Initialization *****************************************
 ***********************************************************/



function matchAny(s,items)
{
    for (var i = 0; i < items.length; ++i)
        if (items[i].search(s) >= 0)
            return true;
    return false;
}

// return all[ any[ item.contains(s) for item in items ] for s in substrs ]
function substrMatchAny(substrs,items)
{
    for (var i = 0; i < substrs.length; ++i)
        if (! matchAny(substrs[i],items))
            return false;
    return true;
}


var search_delay = 500;
var last_ticked = -1;

    


function initializeContent_Buttons(user)
{
    $("#btn-delete-selected").click(function() { deleteSelected(user); });

    $("#btn-stop-selected").click(function() { stopSelected(user); });

    $("#tick-select-all").click(function (ev){
        var node = document.getElementById("jobs-table-body");
        var ticked = $(ev.target).prop("checked");
        for (var i = 0, n = node.firstElementChild; n != null; ++i, n = n.nextElementSibling)
            if (jobFltr(i))
                jobSelected(i,ticked);
        rerenderSelection(node);
    });


    //$("#input-problem-file").change(function(ev) {
    $("#btn-submit-tasks").click(function(ev) {
        var filesinput = document.getElementById("input-problem-file");
        readAndSubmitProblemFiles(filesinput.files,function(name,jobid) {
            addJob(jobid, user.Userid, "submitted",name);
            renderJobsTable();
            startJob(jobid, null);
        });
    });

    $("#input-search-text").on("input",function(ev) {
        var str = $(ev.target).val().trim();
        if (str.length == 0)
            for (var i = 0; i < globalJobList.length; ++i)
                jobFltrText(i,true);
        else
        {
            var strs = str.split(/\s+/);
            for (var i = 0; i < globalJobList.length; ++i)
            {
                jobFltrText(i, substrMatchAny(strs,[ globalJobList[i].Desc,
                                                     globalJobList[i].Ownerid,
                                                     globalJobList[i].Taskid,
                                                     globalJobList[i].Status,
                                                     globalJobList[i].ResCode,
                                                     globalJobList[i].TrmCode]));
            }
        }
        refilterJobTable();
    });

    $("#input-search-date").on("input",function(ev) {
        var str = $(ev.target).val();
        var range = str.split("..",2);

        var rstart = 0
        var rend = Date.now();

        if (range.length == 1) 
        {
            var r = dateRangeFromString(str);
            if (r) {
                rstart = r[0];
                rend = r[1];
            } else {
                return;
            }
            
            // if (range[0].trim().length == 0)
            // {
            //     for (var i = 0; i < globalJobList.length; ++i)
            //         jobFltrDate(i,true);
            // }
            // else // match on this time - this time plus 1 day
            // {
            //     rstart = new Date(range[0].trim()).getTime();
            //     console.log("Filter date = "+range[0], new Date(range[0].trim()),rstart);
            //     if (isNaN(rstart)) return; // return without applying filter
            //     rend = rstart + 24*60*60*1000; // start + 1 day
            // }
        }
        else
        {
            if (range[0].trim().length > 0)
            {
                var r = dateRangeFromString(range[0].trim());
                if (r)
                    rstart = new Date(r[0]);
                else
                    return;
            }
            if (range[1].trim().length > 0)
            {
                var r = dateRangeFromString(range[1].trim());
                if (r)
                    rend = new Date(r[1]);
                else
                    return;
            }
        }
        //console.log("time range : "+rstart+" = "+rend);
        var T0 = Date.now();
        for (var i = 0; i < globalJobList.length; ++i)
        {
            var jobtime = T0 - globalJobList[i].Age; //console.log(jobtime);
            jobFltrDate(i, jobtime >= rstart && jobtime <= rend);
        }
        refilterJobTable();
    });
}



/* Called during initialization to initialize the content area. */
function initializeContent(user)
{
    reloadJobsTable(user,function(data) { renderJobsTable(); });

    initializeContent_Buttons(user);
}

function initializeContentAllJobs(user)
{
    reloadJobsTableAll(user,function(data) { renderJobsTable(); });

    initializeContent_Buttons(user);
}










/***********************************************************
 *  Server communication ***********************************
 ***********************************************************/

function deleteSelected(user)
{
    var jobids = [];
    for (var i = 0; i < globalJobList.length; ++i)
    {
        if (jobSelected(i))
            jobids.push(globalJobList[i].Taskid);
    }

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200)
        {
            var data = JSON.parse(req.responseText);
            if (data)
                jobRemove(user,data);
        }
    }
    req.open("POST","/users/api/request",true);
    req.send(JSON.stringify({'Reqstr' : 'delete-jobs', 'Reqdata' : { 'Jobids' : jobids }}));
}

function stopSelected(user)
{
    var jobids = [];
    for (var i = 0; i < globalJobList.length; ++i)
    {
        if (jobSelected(i))
            jobids.push(globalJobList[i].Taskid);
    }

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200)
        {
            var data = JSON.parse(req.responseText);
            var jobset = {};
            for (var i = 0; i < jobids.length; ++i) jobset[data[i]] = true;

            for (var i = 0; i < globalJobList.length; ++i)
            {
                if (jobset[i])
                {
                    globalJobList[i].Status = "Stopped";
                    jobSelected(i,false);
                }
            }

            rerenderSelection();

        }
    }
    req.open("POST","/users/api/request",true);
    req.send(JSON.stringify({'Reqstr' : 'stop-jobs', 'Reqdata' : { 'Jobids' : jobids }}));
}



/* Send a request to the server to start a job.
 *
 * jobid Is the jobid token.
 * onstarted If this is not null, we call `onstarted(jobid)` when the
 *           start-request has been sent and we have gotten an OK back.
 **/
function startJob(jobid,onstarted)
{
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200)
        {
            if (onstarted != null)
            {
                onstarted(jobid);
            }
        }
    }
    req.open("GET","/api/solve-background?token="+jobid,true);
    req.send();
}

/* Send a problem to the server.
 *
 * data The problem file data as a string or byte array.
 * name A string description for the problem
 * onsubmit Call `onsubmit(jobid)` when the task has been successfully created on the server
 */
function submitProblemFile(data,name,onsubmit)
{
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200)
        {
            var jobid = req.responseText;

            if (onsubmit != null)
            {
                onsubmit(name,jobid);
            }
        }
    }
    req.open("POST","/api/submit?jobname="+name,true);
    req.send(data);
}

/* Read a list of problem files and submit them to the server.
 *
 * files A list of files as produced by an `<input type="files">` element.
 * onsubmit Called for each task to be successfully submitted.
 */

function _create_OnLoadCB(file,onsubmit)
{
    return function(ev) {
        submitProblemFile(ev.target.result,file.name,onsubmit);
    };
}

function readAndSubmitProblemFiles(files,onsubmit)
{
    for (var i = 0; i < files.length; ++i)
    {
        var file = files[i];
        if (file != null)
        {
            var reader = new FileReader();
            reader.onload = _create_OnLoadCB(file,onsubmit);
            reader.readAsArrayBuffer(file);
        }
    }
}



/* Reload the jobs table from the server
 *
 * user A structure defining the user
 * onloaded Call `onloaded(joblist)` upon success. */
function reloadJobsTable(user, onloaded)
{
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200) // NoContent, got an identity
        {
            var data = JSON.parse(req.responseText);
            data.sort(function(a,b) { return a.Age < b.Age ? 1 : (a.Age > b.Age ? -1 : 0); } );
            globalJobList = data;

            if (onloaded != null)
            {
                onloaded(data);
            }
            globalJobBits = new Array(data.length);
            for (var i = 0; i < data.length; ++i)
                globalJobBits[i] = jobDefaultBits;
        }
    }

    req.open("POST", "/users/api/request", true);
    req.send(JSON.stringify({"Reqstr" : "job-info", "Reqdata" : { "Userid" : user.Userid } }));
}

function loadJobsData(offset,onloaded)
{
    //console.log("Load jobs at " +offset+" / "+globalJobList.length)
    if (offset < globalJobList.length)
    {
        var req = new XMLHttpRequest();
        var taskids = [];
        for (var i = offset; i < globalJobList.length && i < offset+30; ++i)
            taskids.push(globalJobList[i].Taskid);

        req.onreadystatechange = function() {
            if (req.readyState == 4 && req.status == 200)
            {
                var data = JSON.parse(req.responseText);
                //console.log(taskids,data)
                for (var i = 0, j = 0; i < taskids.length && j < data.length; ++i)
                {
                    if (taskids[i] == data[j].Taskid)
                    {
                        globalJobList[i+offset].Ownerid    = data[j].Ownerid;
                        globalJobList[i+offset].Desc       = data[j].Desc;
                        globalJobList[i+offset].Submitaddr = data[j].Submitaddr;
                        globalJobList[i+offset].Status     = data[j].Status;
                        globalJobList[i+offset].Age        = data[j].Age;
                        globalJobList[i+offset].Starttime  = data[j].Starttime;
                        globalJobList[i+offset].Endtime    = data[j].Endtime;
                        globalJobList[i+offset].ResCode    = data[j].ResCode;
                        globalJobList[i+offset].TrmCode    = data[j].TrmCode;
                        ++j;
                    }
                }

                renderJobsTableFrom(offset);

                loadJobsData(offset+30,onloaded);
            }
        }

        req.open("POST","/users/api/request",true);
        req.send(JSON.stringify({"Reqstr" : "job-info", "Reqdata" : { "Taskids" : taskids }}));
        //console.log("POST /users/api/request send");
    }
    else if (onloaded)
        onloaded();
}

function reloadJobsTableAll(user, onloaded)
{
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200) // NoContent, got an identity
        {
            var data = JSON.parse(req.responseText); // list of task IDs

            globalJobList = [];
            for (var i = 0; i < data.length; ++i)
                globalJobList.push({ "Taskid" : data[i] });

            globalJobBits = new Array(data.length);
            for (var i = 0; i < data.length; ++i)
                globalJobBits[i] = jobDefaultBits;

            clearJobsTable();
            loadJobsData(0,onloaded);
        }
    }

    req.open("POST", "/users/api/request", true);
    req.send(JSON.stringify({"Reqstr" : "job-list", "Reqdata" : { } }));
}






/***********************************************************
 *  Jobs table manipulation ********************************
 ***********************************************************/


/* Create and return an anchor-button */
function mkLinkButton(title,href,target)
{
    var linknode = document.createElement("a");
    linknode.setAttribute("href",href);
    if (target != null)
        linknode.setAttribute("target",target);
    linknode.setAttribute("class","link-button");
    linknode.appendChild(document.createTextNode(title));
    return linknode;
}

/* Add a row at the end of the jobs table*/
function addJobRow(data)
{
    var node = document.getElementById("jobs-table-body");
    addJobRowAt(node,data);
}

/* Render row i in the data table.
 *
 * node The `tbody` node
 * i The index of the data row to add.
 */
function addJobRowAt(node,i)
{
    var data = globalJobList[i];
    var tr = document.createElement("tr");
    {
        var td = document.createElement("td");
        var tickbox = document.createElement("input");
        tickbox.setAttribute("type","checkbox");
        if (jobSelected(i)) tickbox.setAttribute("checked","true")
        td.appendChild(tickbox);
        tr.appendChild(td);

        $(tickbox).click(function(ev) {
            last_clicked_jobid = i;
            if ($(tickbox).prop("checked"))
            {
                jobSelected(i,true);
                $(tr).addClass("selected");
            }
            else
            {
                jobSelected(i,false);
                $(tr).removeClass("selected");
            }
        });
    }
    var td = document.createElement("td"); td.appendChild(document.createTextNode(data.Taskid));    tr.appendChild(td);
    var td = document.createElement("td"); td.appendChild(document.createTextNode(data.Desc ? data.Desc : "-"));      tr.appendChild(td);
    var td = document.createElement("td"); td.appendChild(document.createTextNode(data.Ownerid && (data.Ownerid.length > 0) ? data.Ownerid : "anonymous" ));   tr.appendChild(td);
    var statustext = data.ResCode && data.ResCode.length > 0 ? data.Status + " / " + data.ResCode : data.Status;
    var td = document.createElement("td"); td.appendChild(document.createTextNode(statustext));    tr.appendChild(td);
    var td = document.createElement("td"); td.appendChild(document.createTextNode(new Date(Date.now() - data.Age*1000))); tr.appendChild(td);
    var td = document.createElement("td");

    td.appendChild(document.createTextNode(data.Endtime >= data.Starttime ? secondsToTimestr((data.Endtime-data.Starttime)/1000) : "-"));
    tr.appendChild(td);

    var td = document.createElement("td");
    td.appendChild(mkLinkButton("Log","/api/log?token="+data.Taskid,"log-window"));
    tr.appendChild(td);

    var td = document.createElement("td");
    if (data.Status == 'finished' || data.Status != 'succeeded')
        td.appendChild(mkLinkButton("Solution","/api/solution?token="+data.Taskid,"sol-window"));
    tr.appendChild(td);

    tr.jobIndex = i;

    node.appendChild(tr);
}







/* Walk the job table and set the `selected` flags according to the indicators in the global job list. */
function rerenderSelection(node)
{
    if (! node)
        node = document.getElementById("jobs-table-body");

    for (var i = 0, n = node.firstElementChild; n != null; ++i, n = n.nextElementSibling)
    {
        if (jobSelected(i)) $(n).addClass("selected");
        else                $(n).removeClass("selected");
        var tickbox = n.firstChild.firstChild;
        $(tickbox).prop("checked",jobSelected(i));
    }
}


/* Walk the job table and set an indicator for each row whether it is filtered out or not */
function refilterJobTable()
{
    var node = document.getElementById("jobs-table-body");
    for (var i = 0, n = node.firstElementChild; n != null; ++i, n = n.nextElementSibling)
    {
        if (jobFltr(i)) $(n).removeClass("filtered-out");
        else            $(n).addClass("filtered-out");
    }
}






function clearJobsTable()
{
    var node = document.getElementById("jobs-table-body");
    var tablenode = node.parentNode;
    tablenode.removeChild(node);

    // clear table
    {
        var n = node.firstElementChild;
        while (n != null)
        {
            var cn = n.nextElementSibling;
            node.removeChild(n)
            n = cn;
        }
    }

    tablenode.appendChild(node);
}

function renderJobsTableFrom(offset)
{
    var data = globalJobList;
    var node = document.getElementById("jobs-table-body");
    var tablenode = node.parentNode;

    if (data.length > offset)
    {
        for (var i = offset; i < data.length; ++i)
            addJobRowAt(node,i);
    }
}

/* Clear and re-render the jobs table according the the global jobs list */
function renderJobsTable()
{
    var data = globalJobList;
    var node = document.getElementById("jobs-table-body");
    var tablenode = node.parentNode;
    tablenode.removeChild(node);

    // clear table
    {
        var n = node.firstElementChild;
        while (n != null)
        {
            var cn = n.nextElementSibling;
            node.removeChild(n)
            n = cn;
        }
    }

    if (data.length > 0)
    {
        for (var i = 0; i < data.length; ++i)
        {
            addJobRowAt(node,i);
        }
    }
    else
    {
        var tr = document.createElement("tr");
        var td = document.createElement("td"); td.setAttribute("colspan","8");
        var div = document.createElement("div"); div.setAttribute("style","margin : 10px 0px 10px 0px; text-align : center;");
        div.appendChild(document.createTextNode("No entries"));
        td.appendChild(div);
        tr.appendChild(td);
        node.appendChild(tr);

        rerenderSelection(node);
    }

    tablenode.appendChild(node);
}






/* Add a job to the global job list (this does not modify the HTML table) */
function addJob(jobid, userid, status, desc)
{
    globalJobList.push({ "Ownerid"    : userid,
                         "SubmitAddr" : "-",
                         "Desc"       : desc,
                         "Taskid"     : jobid,
                         "Status"    : status,
                         "Age"       : 0,
                         "Starttime" : Date.now(),
                         "Endtime"   : 0,
                         "ResCode"   : "",
                         "TrmCode"   : "",
                       });
    globalJobBits.push(jobDefaultBits);
}









var JobSelected_ = 0x01; // means: this item is selected
var JobFltrText_ = 0x02; // means: this item was selected by text search filter
var JobFltrDate_ = 0x04; // means: this item was selected by date search filter

var globalJobList     = [];
var globalJobBits     = [];
var last_clicked_jobid = -1;

function jobSelected(i,val)
{
    if (val == undefined) return (globalJobBits[i] & JobSelected_) != 0;
    else if (val) globalJobBits[i] |= JobSelected_;
    else          globalJobBits[i] &= (~JobSelected_);
}

function jobFltrText(i,val)
{
    if (val == undefined) return (globalJobBits[i] & JobFltrText_) != 0;
    else if (val) globalJobBits[i] |= JobFltrText_;
    else          globalJobBits[i] &= (~JobFltrText_);
}

function jobFltrDate(i,val)
{
    if (val == undefined) return (globalJobBits[i] & JobFltrDate_) != 0;
    else if (val) globalJobBits[i] |= JobFltrDate_;
    else          globalJobBits[i] &= (~JobFltrDate_);
}

function jobFltr(i,val)
{
    if (val == undefined) return (globalJobBits[i] & (JobFltrDate_ | JobFltrText_)) == (JobFltrDate_ | JobFltrText_);
    else if (val) globalJobBits[i] |= (JobFltrDate_ | JobFltrText_);
    else          globalJobBits[i] &= ~(JobFltrDate_ | JobFltrText_);
}

function jobRemove(user,jobids)
{
    var jobset = {};
    for (var i = 0; i < jobids.length; ++i) jobset[jobids[i]] = true;
    var base = 0;
    for (var i = 0; i < globalJobList.length; ++i)
    {
        if (jobset[globalJobList[i].Taskid] != undefined ) // job to be deleted
        {
        }
        else // keep job
        {
            if (i > base) { globalJobList[base] = globalJobList[i]; globalJobBits[base] = globalJobBits[i];}
            ++base;
        }
    }
    globalJobList.length = base;
    globalJobBits.length = base;
    renderJobsTable();
}

var jobDefaultBits = 0x06;



/* Interpret string as a date range. Accepted formats:
   
   2017-12-24 - one day starting at this date
   12-24 - one day starting at this date (previous december)
   2017 jun 4 - one day starting at this date
   jan 4 2017 - one day starting at this date
   2017 jun - one monty starting jan 1 2017
   2017  - the entire year 2017
   jun 7 - one day starting last june 7
   4 days ago - match one day starting 4 days ago
   1 week ago  - match one week starting two weeks ago
   2 months ago - match one month starting two months ago

   Months can be upper and lower case, full names or three letters.
*/
function dateRangeFromString(s) {
    var now = new Date();
    var regex = '^(?:' + ['(([0-9]{4})(?:-([0-9]{1,2})(?:-([0-9]{1,2}))?)?)', // year-month-day
                          '(([0-9]{1,2})-([0-9]{1,2}))', // month-day
                          '(([0-9]{4})?(?:[ ]*([a-zA-Z]{3})[ ]*([0-9]{1,2})?)?)', // month name day? year?
                          '([1-9]+)[ ]+(day[s]?|week[s]?|month[s]?)[ ]+ago'
                         ].join('|') + ')[ ]*$';
    var res = s.match(regex);
    if (res == null) return null;

    var start = new Date(now);
    var delta = 0;
    
    if (res[1]) {
        var year  = parseInt(res[2]);
        var month = res[3] ? parseInt(res[3]) : null;
        var day   = res[4] ? parseInt(res[4]) : null

        if (month && ( monty < 1 || month > 12)) return null;
        if (month && day && ( day < 1 || day > 31)) return null;
        
        var d0 = start
        d0.setFullYear(year);
        d0.setMonth(0);
        d0.setDate(1);
        d0.setHours(0);
        d0.setMinutes(0);
        d0.setSeconds(0);
        
        if (month && day) {
            start
            d0.setMonth(month-1);
            d0.setDate(day);
            delta = 24*60*60;
        } else if (month) {
            d0.setMonth(now.getMonth());
            delta = 31*24*60*60;
        } else {
            delta = 365*24*60*60;
        }
    } else if (res[5]) {
        var month = parseInt(res[6]);
        var day   = parseInt(res[7]);

        if (monty < 1 || month > 12) return null;
        if (day   < 1 || day   > 31) return null;

        var d0 = start;
        d0.setMonth(month-1);
        d0.setDate(day);
        if (month-1 > now.getMonth() || (month-1 == now.getMonth() && day-1 == now.getDate())) {
            d0.setFullYear(now.getFullYear()-1)
        } else {
            d0.setFullYear(now.getFullYear())
        }
        delta = 24*60*60;
    } else if (res[8]) {
        var monthname = res[10] ? res[10].toLowerCase() : null;
        var month = 0;
        var day = res[11] ? parseInt(res[11]) : null;
        var year = res[9] ? parseInt(res[9]) : (res[12] ? parseInt(res[12]) : null);
        
        if (monthname) {
            if      (monthname == "jan" || monthname == 'january')   month = 0;
            else if (monthname == "feb" || monthname == 'february')  month = 1;
            else if (monthname == "mar" || monthname == 'march')     month = 2;
            else if (monthname == "apr" || monthname == 'april')     month = 3;
            else if (monthname == "may" || monthname == 'may')       month = 4;
            else if (monthname == "jun" || monthname == 'june')      month = 5;
            else if (monthname == "jul" || monthname == 'july')      month = 6;
            else if (monthname == "aug" || monthname == 'august')    month = 7;
            else if (monthname == "sep" || monthname == 'september') month = 8;
            else if (monthname == "oct" || monthname == 'october')   month = 9;
            else if (monthname == "nov" || monthname == 'november')  month = 10;
            else if (monthname == "dec" || monthname == 'december')  month = 11;
            else
                return null;
        }


        if (year != null) {
            start.setFullYear(year);
            if (month != null) {
                start.setMonth(month);
                if (day != null) {
                    start.setDate(day);
                    delta = 24*60*60;
                } else {
                    start.setDate(1);
                    delta = 31*24*60*60;
                }
            } else {
                start.setMonth(0);
                delta = 365*24*60*60;
            }
        } else if (month != null) {
            if (now.getMonth() < month || (now.getMonth() == month && day != null && now.getDate() < day))
                start.setFullYear(now.getFullYear()-1);
            else
                start.setFullYear(now.getFullYear());
            start.setMonth(month);
            if (day != null) {
                start.setDate(day);
                delta = 24*60*60;
            } else {
                start.setDate(1);
                delta = 31*24*60*60;
            }
        } else {
            return null;
        }
        
    } else if (res[12]) {
        var diff = parseInt(res[12]);
        var kind = res[13].toLowerCase();

        if (kind == 'day' || kind == 'days') {
            delta = 24*60*60;
            start = new Date(now.getTime() - (diff*24*60*60 + delta/2)*1000);
        } else if (kind == 'week' || kind == 'weeks') {
            delta = 7*24*60*60;
            start = new Date(now.getTime() - (diff*delta + delta/2)*1000);
        } else { //if (kind == 'month' || kind == 'months') {
            delta = 31*24*60*60;
            start = new Date(now.getTime() - (diff*24*60*60*31 + delta/2)*1000);
        }
    } else
        return null;

    return [ start.getTime(), start.getTime()+delta*1000 ];
}
