

function mkSidebarEntry(title,link)
{
    var div = document.createElement("div"); div.setAttribute("class","sidebar-entry");
    var a = document.createElement("a"); a.setAttribute("href",link);
    a.appendChild(document.createTextNode(title));
    div.appendChild(a);
    return div;
}

function buildSidebar(user,node)
{
    while (node.firstChild != null)
        node.removeChild(node.firstChild);

    node.appendChild(mkSidebarEntry("Start","index.html"));
    node.appendChild(mkSidebarEntry("Profile","profile.html"));
    if (user.Issubmitter)
    {
        node.appendChild(mkSidebarEntry("My Jobs","myjobs.html"));
        node.appendChild(mkSidebarEntry("My Access Tokens","mytokens.html"));
    }

    if (user.Isadmin)
    {
        node.appendChild(mkSidebarEntry("All jobs","alljobs.html"));
        node.appendChild(mkSidebarEntry("Users","userlist.html"));
    }
}


function initializeSidebar(user)
{
    buildSidebar(user,document.getElementById("sidebar-div"));
}
