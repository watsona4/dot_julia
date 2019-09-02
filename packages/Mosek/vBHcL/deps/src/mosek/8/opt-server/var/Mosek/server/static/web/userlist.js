var globalUserDict  = {}; // maps login -> index
var globalUserList  = [];
var globalUserMod   = [];
var globalUserFlags = [];

var bit_Name        = 0x01;
var bit_Email       = 0x02;
var bit_Password    = 0x04;
var bit_PermSubmit  = 0x08;
var bit_PermAdmin   = 0x10;
var bit_Delete      = 0x100;

function setUserName(i,value)         { globalUserMod[i].Name        = value; globalUserFlags[i] |= bit_Name; }
function setUserEmail(i,value)        { globalUserMod[i].Email       = value; globalUserFlags[i] |= bit_Email; }
function setUserPassword(i,value)     { globalUserMod[i].Password    = value; globalUserFlags[i] |= bit_Password; }
function setUserIsadmin(i,value)      { globalUserMod[i].Isadmin     = value; globalUserFlags[i] |= bit_PermAdmin; }
function setUserIssubmitter(i,value)  { globalUserMod[i].Issubmitter = value; globalUserFlags[i] |= bit_PermSubmit; }
function setUserDeletionMark(i,value) {
    if (value)
        globalUserFlags[i] |= bit_Delete;
    else
        globalUserFlags[i] &= ~bit_Delete;
}

function revertUserListChanges() {
    for (var i = 0; i < globalUserList.length; ++i) globalUserFlags[i] = 0;
}

function loadUserList(onload)
{
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200)
        {
            var data = JSON.parse(req.responseText);

            if (data)
            {
                globalUserList = data;
                globalUserFlags = [];
                globalUserMod = [];
                globalUserDict = [];
                for (var i = 0; i < globalUserList.length; ++i)
                {
                    globalUserFlags[i] = 0;
                    globalUserMod[i] = {};
                    globalUserDict[globalUserList[i].Userid] = i;
                }
            }

            if (onload)
                onload();
        }
    }
    req.open("POST","/users/api/request",true);
    req.send(JSON.stringify({'Reqstr' : 'user-info','Reqdata' : {}}));
}


function renderUserTable()
{
    var node = document.getElementById("users-table-body");
    var tablenode = node.parentNode;
    tablenode.removeChild(node);

    // clear table
    {
        var n = node.firstChild;
        while (n != null)
        {
            var cn = n.nextSibling;
            node.removeChild(n)
            n = cn;
        }
    }

    var data = globalUserList;

    if (data.length > 0)
    {
        for (var i = 0; i < data.length; ++i)
            addRow(node,i);
    }
    else
    {
        var tr = document.createElement("tr");
        var td = document.createElement("td"); td.setAttribute("colspan","5");
        var div = document.createElement("div"); div.setAttribute("style","margin : 10px 0px 10px 0px; text-align : center;");
        div.appendChild(document.createTextNode("No entries"));
        td.appendChild(div);
        tr.appendChild(td);
        node.appendChild(tr);

        //rerenderSelection(node);
    }


    tablenode.appendChild(node);
}


function mkEditableCell(type,text,onchange,ispassword)
{
    var td = document.createElement(type);
    var inputnode = document.createElement("input")
    inputnode.setAttribute("type",ispassword ? "password" : "text")
    if (! ispassword)
        inputnode.setAttribute("value",text)
    inputnode.setAttribute("class","editable-cell")
    $(inputnode).keyup(function(ev) {
        if (ev.keyCode == 13) {
            $(ev.target).unbind("focusout");
            var val = $(ev.target).val();
            if (val != text || (ispassword && val != ""))
                onchange($(ev.target).val());

            if (ispassword) { $(ev.target).val(""); }
            $(ev.target).blur();
        }
        else if (ev.keyCode == 27) {
            $(ev.target).unbind("focusout");
            $(ev.target).val(ispassword ? "" : text);
            $(ev.target).blur();
        }
    } );
    $(inputnode).keydown(function(ev) {
        if (ev.keyCode == 9) {
            $(ev.target).unbind("focusout");
            var val = $(ev.target).val();
            if (val != text || (ispassword && val != ""))
                onchange($(ev.target).val());
            if (ispassword) { $(ev.target).val(""); }
        }
    } );


    $(inputnode).focus(function(ev) {
        $(ev.target).focusout(function(ev) {
            /*onchange($(ev.target).val());*/
            $(ev.target).val(ispassword ? "" : text);
        } );
    } );

    td.appendChild(inputnode);
    return td
}



function editUserSubmitPerm(i,ev) { setUserIssubmitter(i,$(ev.target).prop("checked"));  }
function editUserAdminPerm(i,ev) { setUserIsadmin(i,$(ev.target).prop("checked")); }
function markChanged(i,node)
{
    if (globalUserFlags[i] != 0) 
        $(node.parentNode).addClass("changed");
    else
        $(node.parentNode).removeClass("changed");
}

function addRow(node,i)
{
    var user = globalUserList[i];
    var usermod = globalUserMod[i];
    var userflags = globalUserFlags[i];

    var tr = document.createElement("tr");

    var td = document.createElement("td");
    tr.appendChild(td);

    var td = document.createElement("td");
    td.appendChild(document.createTextNode(user.Userid));
    tr.appendChild(td);

    var td = mkEditableCell("td", userflags & bit_Name > 0 ? usermod.Name : user.Name, function(value) { setUserName(i,value); markChanged(i,td); });
    tr.appendChild(td);

    var td = mkEditableCell("td",userflags & bit_Email > 0 ? usermod.Email : user.Email, function(value) { setUserEmail(i,value);  markChanged(i,td); });
    tr.appendChild(td);

    var td = mkEditableCell("td", "", function(value) { setUserPassword(i,value); markChanged(i,td); }, true);
    tr.appendChild(td);

    var td = document.createElement("td");
    var tickbox = document.createElement("input");
    $(tickbox).click(function(ev) { editUserSubmitPerm(i,ev); markChanged(i,td); });
    tickbox.setAttribute('type','checkbox');
    if (userflags & bit_PermSubmit ? usermod.Issubmitter : user.Issubmitter) tickbox.setAttribute('checked',"true");
    td.appendChild(tickbox);
    tr.appendChild(td);

    var td = document.createElement("td");
    var tickbox = document.createElement("input");
    $(tickbox).click(function(ev) { editUserAdminPerm(i,ev); markChanged(i,td); });
    tickbox.setAttribute('type','checkbox');
    if (userflags & bit_PermAdmin ? usermod.Isadmin : user.Isadmin) tickbox.setAttribute('checked',"true");
    td.appendChild(tickbox);
    tr.appendChild(td);

    var td = document.createElement("td");
    var tickbox = document.createElement("input");
    $(tickbox).click(function(ev) {
        var val = $(ev.target).prop("checked");
        setUserDeletionMark(i,val);
        if (val)
            $(ev.target.parentNode.parentNode).addClass("marked-for-deletion");
        else
            $(ev.target.parentNode.parentNode).removeClass("marked-for-deletion");
    });
    tickbox.setAttribute('type','checkbox');

    td.appendChild(tickbox);
    tr.appendChild(td);


    node.appendChild(tr);
}

function setUserMessage(msg) { var n = document.getElementById("span-user-message"); n.replaceChild(document.createTextNode(msg),n.firstChild); }
function clearUserMessage() { var n = document.getElementById("span-user-message"); if (n.firstChild) n.removeChild(n.firstChild); }

function clearCreateUserForm()
{
    $("#new-user-login").val("");
    $("#new-user-name").val("");
    $("#new-user-email").val("");
    $("#new-user-pwd1").val("");
    $("#new-user-pwd2").val("");
    $("#new-user-isadmin").prop("checked",false);
    $("#new-user-issubmitter").prop("checked",false);
    clearUserMessage();
}

function submitCreateUser()
{
    var usr_login       = $("#new-user-login").val();
    var usr_name        = $("#new-user-name").val();
    var usr_email       = $("#new-user-email").val();
    var usr_pwd1        = $("#new-user-pwd1").val();
    var usr_pwd2        = $("#new-user-pwd2").val();
    var usr_isadmin     = $("#new-user-isadmin").prop("checked");
    var usr_issubmitter = $("#new-user-issubmitter").prop("checked");

    if (usr_pwd1 != usr_pwd2)
    {
        setUserMessage("Mismatching passwords");
        document.getElementById("new-user-pwd1").focus();
        return;
    }

    clearCreateUserForm();

    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200)
        {
            var data = JSON.parse(req.responseText);
            if (data) // data for user created
            {
                var i = globalUserList.length
                globalUserDict[data.Userid] = i;
                globalUserList.push(data);
                globalUserFlags.push(0);
                globalUserMod.push({});

                var node = document.getElementById("users-table-body");
                addRow(node,i);

            }
        }
    }
    var userdata = { "Userid"      : usr_login,
                     "Name"        : usr_name,
                     "Email"       : usr_email,
                     "Password"    : usr_pwd1,
                     "Isadmin"     : usr_isadmin,
                     "Issubmitter" : usr_issubmitter };

    req.open("POST","/users/api/request",true);
    req.send(JSON.stringify({'Reqstr' : 'create-user','Reqdata' : userdata}));
}


function submitUserChanges()
{
    var users = [];
    var delusrs = [];

    for (var i = 0; i < globalUserList.length; ++i)
    {
        if ((globalUserFlags[i] & bit_Delete) != 0)
            delusrs.push(globalUserList[i].Userid);
        else if (globalUserFlags[i] != 0)
        {
            var moduser = { "Userid" : globalUserList[i].Userid };
            if ((globalUserFlags[i] & bit_Name)       != 0) moduser["Name"]        = globalUserMod[i].Name;
            if ((globalUserFlags[i] & bit_Email)      != 0) moduser["Email"]       = globalUserMod[i].Email;
            if ((globalUserFlags[i] & bit_Password)   != 0) moduser["Newpassword"] = globalUserMod[i].Password;
            if ((globalUserFlags[i] & bit_PermAdmin)  != 0) moduser["Isadmin"]     = globalUserMod[i].Isadministrator;
            if ((globalUserFlags[i] & bit_PermSubmit) != 0) moduser["Issubmitter"] = globalUserMod[i].Issubmitter;
            console.log("Modify user: " + globalUserList[i].Userid, moduser );
            users.push(moduser);
        }
    }

    if (delusrs.length > 0)
    {
        var req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState == 4)
            {
                if (users.length > 0)
                {
                    var req2 = new XMLHttpRequest();
                    req2.onreadystatechange = function() {
                        if (req2.readyState == 4)
                        {
                            loadUserList(function () { renderUserTable(); });
                        }
                    };
                    req2.open("POST", "/users/api/request", true);
                    req2.send(JSON.stringify({"Reqstr" : "update-users", "Reqdata" : { "Userlist" : users } }));
                }
                else
                {
                    loadUserList(function () { renderUserTable(); });
                }
            }
        };

        req.open("POST", "/users/api/request", true);
        req.send(JSON.stringify({"Reqstr" : "delete-users", "Reqdata" : { "Userids" : delusrs } }));
    }
    else if (users.length > 0)
    {
        var req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState == 4)
            {
                loadUserList(function () { renderUserTable(); });
            }
        };
        console.log(users);
        req.open("POST", "/users/api/request", true);
        req.send(JSON.stringify({"Reqstr" : "update-users", "Reqdata" : { "Userlist" : users } }));
    }
}


function initializeContent(user)
{
    loadUserList(function () { renderUserTable(); });
    $("#btn-revert-changes").click(function () { revertUserListChanges(); renderUserTable(); });
    $("#btn-submit-changes").click(submitUserChanges);
    $("#btn-create-user").click(submitCreateUser);
}
