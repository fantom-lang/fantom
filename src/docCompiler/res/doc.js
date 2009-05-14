//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 07  Andy Frank  Creation
//

//////////////////////////////////////////////////////////////////////////
// TEMP?
//////////////////////////////////////////////////////////////////////////

/**
 *  Written by Jonathan Snook, http://www.snook.ca/jonathan
 *  Add-ons by Robert Nyman, http://www.robertnyman.com
 */
function getElementsByClassName(oElm, strTagName, strClassName)
{
  var arrElements = (strTagName == "*" && oElm.all)
    ? oElm.all : oElm.getElementsByTagName(strTagName);
  var arrReturnElements = new Array();
  strClassName = strClassName.replace(/\-/g, "\\-");
  var oRegExp = new RegExp("(^|\\s)" + strClassName + "(\\s|$)");
  var oElement;
  for (var i=0; i<arrElements.length; i++)
  {
    oElement = arrElements[i];
    if(oRegExp.test(oElement.className))
      arrReturnElements.push(oElement);
  }
  return arrReturnElements;
}

//////////////////////////////////////////////////////////////////////////
// Login
//////////////////////////////////////////////////////////////////////////

function Login()  {}

Login.check = function()
{
  // if not online, just bail
  if (window.location.href.indexOf("http://") == -1) return;

  var req;
  var ua = navigator.userAgent.toLowerCase();
  if (!window.ActiveXObject) req = new XMLHttpRequest();
  else if (ua.indexOf('msie 5') == -1) req = new ActiveXObject("Msxml2.XMLHTTP");
  else req = new ActiveXObject("Microsoft.XMLHTTP");

  req.open("POST", "/sidewalk/user/?view=sidewalk::UtilView&webappWidgetCall=sidewalk::UtilView.onCheckLogin");
  req.onreadystatechange = function ()
  {
    if (req.readyState == 4)
    {
      var p = document.getElementById("sidewalkLogin_");
      p.innerHTML = req.responseText;
    }
  }
  req.send("");
}

//////////////////////////////////////////////////////////////////////////
// Show Slots
//////////////////////////////////////////////////////////////////////////

function ShowSlots() {}

ShowSlots.toggle = function(evt)
{
  var target = evt.target ? evt.target : window.event.srcElement;
  var show = target.innerHTML == "Show All Slots";
  target.innerHTML = show ? "Hide Slots" : "Show All Slots";

  var elems = getElementsByClassName(document.body, "*", "hidden");
  for (var i=0; i<elems.length; i++)
    elems[i].style.display = show ? "block" : "none";
}

//////////////////////////////////////////////////////////////////////////
// SearchBox
//////////////////////////////////////////////////////////////////////////

function SearchBox() {}

SearchBox.search = function(evt)
{
  var box = document.getElementById("fandocSearchBox");
  var term = box.value.toLowerCase();
  var results = [];

  // clear input if 'esc' was pressed
  if (evt.keyCode == 27) box.value = term = "";

  // find results
  for (var i=0; i<searchIndex.length; i++)
  {
    var s = searchIndex[i];
    var test = s.substr(s.indexOf("::")+2).toLowerCase();
    if (test.indexOf(term) != -1) results.push(s);
  }

  // remove any old results
  var div = document.getElementById("fandocSearchResults");
  while (div.childNodes.length > 0) div.removeChild(div.firstChild);

  // skip if input string was empty
  if (term.length == 0) return;

  // display new results
  var ul = document.createElement("ul");

  if (results.length == 0)
  {
    var li = document.createElement("li");
    li.innerHTML = "'" + box.value + "' not found";
    ul.appendChild(li);
  }
  else
  {
    for (var i=0; i<results.length; i++)
    {
      var s = results[i];
      var colons = s.indexOf("::");
      var href = "../" + s.substr(0, colons) + "/" + s.substr(colons+2) + ".html";

      var a = document.createElement("a");
      a.href = href;
      a.innerHTML = results[i];

      var li = document.createElement("li");
      li.appendChild(a);
      ul.appendChild(li);
    }
  }
  div.appendChild(ul);
}

SearchBox.onfocus = function()
{
  var box = document.getElementById("fandocSearchBox");
  if (box.value == "Search...") box.value = "";
}

SearchBox.onblur = function()
{
  var box = document.getElementById("fandocSearchBox");
  if (box.value == "") box.value = "Search...";
}