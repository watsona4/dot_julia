function addTokenRow(tbody,name,owner,expires,perm)
{
  var node = tbody;
  var tr = document.createElement("tr");
  var td = document.createElement("td"); td.appendChild(document.createTextNode(name)); tr.appendChild(td);
  var td = document.createElement("td"); td.appendChild(document.createTextNode(owner)); tr.appendChild(td);
  var td = document.createElement("td"); td.appendChild(document.createTextNode(secondsToTimestr(expires - Date.now()))); tr.appendChild(td);

  var cbn = document.createElement("input"); cbn.setAttribute("type","checkbox"); cbn.setAttribute("disabled","true"); cbn.setAttribute("checked", 0 < (perm & 0x02));
  var td = document.createElement("td"); td.appendChild(cbn); tr.appendChild(td);

  var cbn = document.createElement("input"); cbn.setAttribute("type","checkbox"); cbn.setAttribute("disabled","true"); cbn.setAttribute("checked", 0 < (perm & 0x01));
  var td = document.createElement("td"); td.appendChild(cbn); tr.appendChild(td);

  $(tr).click(function(ev) { $(tr).toggleClass("selected"); ev.preventDefault(); });

  node.appendChild(tr);
}

function initializeCreateToken(user)
{
  $("#button-delete-selected").click(function(ev) { deleteSelected(user); ev.preventDefault(); });
  $("#button-select-all").click(function() { $("#tokens-table-body").children().addClass("selected"); });
  $("#button-select-none").click(function() { $("#tokens-table-body").children().removeClass("selected"); });


  $("#button-create-token").click(function () {
      var expirydatestr = document.getElementById("input-expiry").value

      if (expirydatestr && expirydatestr.length > 0)
      {
          //var d0 = new Date(expirydatestr);
          //var d1 = new Date();
          var millisecs = (new Date(expirydatestr)).getTime() - (Date.now());
          var seconds = Math.round(millisecs/1000);
          //console.log("Seconds = ",seconds,millisecs,d0,d1);
          if (seconds > 0)
          {

              var req = new XMLHttpRequest();
              req.onreadystatechange = function() {
                  if (req.readyState == 4 && req.status == 200)
                  {
                      var data = JSON.parse(req.responseText);
                      var node = document.getElementById("tokens-table-body");

                      addTokenRow(node,data.Name,data.Owner,data.Expires,data.PermBits);

                      $("#output-token").val(data.Name);
                  }
              };

              req.open("POST", "/users/api/request", true);
              req.send(JSON.stringify({"reqstr" : "create-access-token", "reqdata" : { "Userid" : user.Userid, "Seconds" : seconds } }));
          }
      }
  });
}

function initializeJobsTable(user)
{
    initializeCreateToken(user);
    renderTokensTable(user);
}

function renderTokensTable(user)
{
    var req = new XMLHttpRequest();
    req.onreadystatechange = function() {
        if (req.readyState == 4 && req.status == 200) // NoContent, got an identity
        {
            var data = JSON.parse(req.responseText);
            var node = document.getElementById("tokens-table-body");
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

            if (data && data.length > 0)
            {
                for (var i = 0; i < data.length; ++i)
                {
                    addTokenRow(node,data[i].Name,data[i].Owner,data[i].Expires,data[i].PermBits);
                }
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
            }

            tablenode.appendChild(node);
        }
    }

    req.open("POST", "/users/api/request", true);
    req.send(JSON.stringify({"reqstr" : "access-token-list", "reqdata" : { "userids" : [ user.Userid ] } }));
}

function deleteSelected(user)
{
    var tokens = $("#tokens-table-body tr.selected td:nth-child(1)").map( function (i,n) { return n.innerHTML; }).toArray();
    var req = new XMLHttpRequest();

    req.onreadystatechange = function() {
        if (req.readyState == 4) // NoContent, got an identity
        {
            renderTokensTable(user);
        }
    };

    req.open("POST", "/users/api/request", true);
    var body = JSON.stringify({"reqstr" : "delete-access-tokens", "reqdata" : { "Tokens" : tokens } });
    console.log(body);
    req.send(body);
}

