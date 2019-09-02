var AdminBit     = 0x01
var SubmitterBit = 0x02

function stopTask(self,id) {
   $.ajax({ url : "/break?token="+id,
            success : function(data,status,jqXHR) { $(self).off("click"); $(self).attr("class","disabled-red button"); }
          })
}

function deleteTask(self,id) {
   $.ajax({ url : "/management/jobs/delete?token="+id,
            type : "HEAD",
            success : function(data,status,jqXHR) { $(self).off("click"); $(self).attr("class","disabled-red button"); },
          })
}

function makeStopButton(data,type,row,meta) {
  if (row["Status"] == "running")
  {
    return '<div class="red button" onClick="stopTask(this,\''+data+'\')">Stop</div>'
  }
  else
  {
    return '<div class="disabled-red button">Stop</div>'
  }
}

function makeDeleteButton(data,type,row,meta) {
  return '<div class="red button" onClick="deleteTask(this,\''+data+'\')">Delete</div>'
}


function secondsToTimestr(s)
{
    var years   = Math.floor(s / (365*24*3600)); s -= years * (365*24*3600);
    var days    = Math.floor(s / (24*3600));     s -= days  * (24*3600);
    var hours   = Math.floor(s / (3600));        s -= hours * (3600);
    var minutes = Math.floor(s / 60);            s -= minutes * 60;
    var seconds = Math.round(s)

    var r = [];
    if (years > 0) { r[0] = years + " years" };
    r[r.length] = days + " days";
    r[r.length] = (hours < 10 ? '0'+hours : hours) + ":" + (minutes < 10 ? '0'+minutes : minutes) + ":" + (seconds < 10 ? '0'+seconds : seconds);
    return r.join(", ");
}

function renderExpiry(data,type,row,meta) {
    if (type == 'display')
    {
        var expiry = row["Expires"] - new Date().getTime()/1000;
        var expired = false
        if (expiry < 0)
        {
            expiry = - expiry;
            expired = true;
        }

        timestr = secondsToTimestr(expiry);
        if (! expired)
            return timestr;
        else
            return '<span class="expired">'+timestr+' ago</span>';
    }
    else
        return row['Expires'];
}

function submitCreateAccessToken(years,months,days,hours)
{
    console.log("expires ",years,days,hours);
    var seconds = (((years*365+months*30)+days)*24+hours)*3600;
    console.log("seconds ",seconds);
    var req = "/users/api/token/create?expires="+seconds;
    $.getJSON(req, function(data) {
        
        console.log(data);
        $("#output-token").val(data["Name"]);
        location.reload();
    })
}

function accesstokenlist_onDocumentReady()
{
    $.getJSON( "/users/api/token/list", function(data) {
        $("#data-table").DataTable( { data : data,
                                      order : [ [2, "asc" ] ],
                                      columns : [ { title : "Owner",     data : "Owner" },
                                                  { title : "Token",     data : "Name" },
                                                  { title : "Expires",   render : renderExpiry }
                                                ] } );
        $("#data-table tbody").on('click','tr', function() {
            if ( $(this).hasClass('selected'))
                $(this).removeClass('selected');
            else
                $(this).addClass('selected');
        });
    } );

    $("#select-all-tokens").on("click",function() {
        $("#data-table tbody tr").addClass("selected");
    });

    $("#select-no-tokens").on("click",function() {
        $("#data-table tbody tr").removeClass("selected");
    });

    $("#select-expired-tokens").on("click",function() {
        var t = $('#data-table').DataTable();
        $("#data-table tbody tr").each(function(index) {
            if (t.row(this).data()["Expires"] < 0)
                $(this).addClass("selected");
        } );
    });

    $("#delete-selected-tokens").on("click",function() {
        var t = $('#data-table').DataTable();
        var querytokens = [];
        $("#data-table tbody tr.selected").each(function(index) {
            console.log(t.row(this).data())
            querytokens[querytokens.length] = "token="+t.row(this).data()["Name"];
        } );
        $.getJSON("/users/api/token/delete?"+querytokens.join('&'),function() { location.reload(); });

    });

}



function joblist_onDocumentReady()
{
  $.getJSON( "/users/api/jobs/list", function(data) {
      var table = $("#data-table").DataTable( { data : data,
                                                order : [ [3, "asc" ] ],
                                                columns : [ { title : "Token",     data : "Name" },
                                                            { title : "Submitter", data : "Owner" },
                                                            { title : "Source",    data : "SubmitAddr" },
                                                            { title : "Age",       render : function(d,t,r,m){ return t == 'display' ? secondsToTimestr(r["Age"]/1000) : r["Age"]; } },
                                                            { title : "Status",    data : "Status" },
                                                            { title : "Start",     render : function(d,t,r,m){ return t == 'display' ? new Date(r["Starttime"]).toString() : r["Starttime"]; } },
                                                            { title : "End",       render : function(d,t,r,m){ return t == 'display' ? new Date(r["Endtime"]).toString()   : r["Endtime"]; } },
                                                            { title : "Duration"  ,render : function(d,t,r,m){ return t == 'display' ? secondsToTimestr(r["Runningtime"]/1000) : r["Runningtime"]; } } ] } );
      $("#data-table tbody").on('click','tr', function() {
          if ( $(this).hasClass('selected'))
              $(this).removeClass('selected');
          else
              $(this).addClass('selected');
      });

    $("#select-all-jobs").on("click",function() {
        $("#data-table tbody tr").addClass("selected");
    });

    $("#select-no-jobs").on("click",function() {
        $("#data-table tbody tr").removeClass("selected");
    });

    $("#delete-selected-jobs").on("click",function() {
        var t = $('#data-table').DataTable();
        var querytokens = [];
        $("#data-table tbody tr.selected").each(function(index) {
            console.log(t.row(this).data())
            querytokens[querytokens.length] = "token="+t.row(this).data()["Name"];
        } );
        $.getJSON("/users/api/jobs/delete?"+querytokens.join('&'),function() { location.reload(); });

    });

    $("#delete-selected-jobs").on("click",function() {
        var t = $('#data-table').DataTable();
        var querytokens = [];
        $("#data-table tbody tr.selected").each(function(index) {
            console.log(t.row(this).data())
            querytokens[querytokens.length] = "token="+t.row(this).data()["Name"];
        } );
        $.getJSON("/users/api/jobs/delete?"+querytokens.join('&'),function() { location.reload(); });

    });

  });
}







function modifyUser(rowidx)
{
    var t = $("#data-table").DataTable();
    displayUserData(t.row(rowidx).data())
}

function displayUserData(data)
{
    var t = $("#data-table").DataTable();
    $("#input-user-name").val(data["Name"]);
    $("#input-user-login").val(data["Login"]);
    $("#input-user-email").val(data["Email"]);
    $("#input-user-password").val("");
    $("#input-user-isadmin").prop('checked',(data["Permissions"] & AdminBit) != 0);
    $("#input-user-issubmitter").prop('checked',((data["Permissions"] & SubmitterBit ) != 0));
}

function clearForm()
{
    $("#input-user-name").val("");
    $("#input-user-login").val("");
    $("#input-user-email").val("");
    $("#input-user-password").val("");
    $("#input-user-isadmin").prop('checked',false);
    $("#input-user-issubmitter").prop('checked',false);
}


function submitAddOrModUser(op)
{
    var name    = $("#input-user-name").val();
    var login   = $("#input-user-login").val();
    var email   = $("#input-user-email").val();
    var pwd     = $("#input-user-new-password").val();
    var isadmin = $("#input-user-isadmin").prop('checked');
    var issmit  = $("#input-user-issubmitter").prop('checked');

    if (login.length == 0)
        return;

    var reqparams = [ "login="+login, "op="+op ];
    if (name.length     > 0) reqparams[reqparams.length] = "name="+encodeURIComponent(name);
    if (email.length    > 0) reqparams[reqparams.length] = "email="+encodeURIComponent(email);
    if (pwd.length      > 0) {
        reqparams[reqparams.length] = "newpassword1="+encodeURIComponent(pwd);
        reqparams[reqparams.length] = "newpassword2="+encodeURIComponent(pwd);
    }
    reqparams[reqparams.length] = "isadmin="    +(isadmin ? "yes" : "no");
    reqparams[reqparams.length] = "issubmitter="+(issmit  ? "yes" : "no");

    console.log("op = ",op)
    var req = "/management/api/userupdate?" + reqparams.join("&")

    $.getJSON(req, function(data) { clearForm(); location.reload(); })
}

function submitUpdateSelf(op)
{
    var login      = $("#input-user-login").val();
    var name       = $("#input-user-name").val();
    var email      = $("#input-user-email").val();
    var oldpwd     = $("#input-user-password").val();
    var newpwd     = $("#input-user-new-password1").val();
    var newpwd2    = $("#input-user-new-password2").val();

    if (login.length == 0)
        return;

    var reqparams = [ "login="+login, "op=update" ];
    if (login.length       > 0) reqparams[reqparams.length] = "login="+encodeURIComponent(login);
    if (name.length        > 0) reqparams[reqparams.length] = "name="+encodeURIComponent(name);
    if (email.length       > 0) reqparams[reqparams.length] = "email="+encodeURIComponent(email);
    if (oldpwd.length      > 0) reqparams[reqparams.length] = "password"+encodeURIComponent(oldpwd);
    if (newpwd.length      > 0) reqparams[reqparams.length] = "newpassword"+encodeURIComponent(newpwd);
    if (newpwd2.length     > 0) reqparams[reqparams.length] = "newpassword2"+encodeURIComponent(newpwd2);

   var req = "/management/api/userupdate?" + reqparams.join("&")

    $.getJSON(req, function(data) { clearForm(); location.reload(); })
}


function renderRoles(data,type,row,meta)
{
    var perms = row["Permissions"] & 0xff;
    var r = [];
    if ((perms & AdminBit)     != 0) r[r.length] = "admin";
    if ((perms & SubmitterBit) != 0) r[r.length] = "submit";
    return r.join(", ");
}

function userlist_onDocumentReady()
{
    $.getJSON( "/management/api/userlist", function(data) {
        var table = $("#data-table").DataTable( { data : data,
                                                  paging : false,
                                                  order : [ [0, "asc" ] ],
                                                  columns : [ { title : "Login",  data : "Login" },
                                                              { title : "Name",   data : "Name"  },
                                                              { title : "Email",  data : "Email" },
                                                              { title : "Roles",  render : renderRoles }] } );
        $("#data-table tbody").on('click','tr', function() {
            displayUserData(table.row(this).data());
        });
    } );
}
