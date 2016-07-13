//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Dec 2014  Andy Frank  Creation
//

fan.dom.StylePeer = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.dom.StylePeer.prototype.$ctor = function(self)
{
  // set in ElemPeer.style
  this.elem  = null;
  this.style = null;
}

fan.dom.StylePeer.prototype.classes  = function(self)
{
  var arr = this.elem.className.split(" ");
  return fan.sys.List.make(fan.sys.Str.$type, arr);
}

fan.dom.StylePeer.prototype.classes$ = function(self, val)
{
  this.elem.className = val.join(" ");
  return this.classes();
}

fan.dom.StylePeer.prototype.hasClass = function(self, className)
{
  var arr = this.elem.className.split(" ");
  for (var i=0; i<arr.length; i++)
    if (arr[i] == className)
      return true;
  return false;
}

fan.dom.StylePeer.prototype.addClass = function(self, className)
{
  if (!this.hasClass(self, className))
  {
    if (this.elem.className.length == 0) this.elem.className = className;
    else this.elem.className += " " + className;
  }
  return self;
}

fan.dom.StylePeer.prototype.removeClass = function(self, className)
{
  var arr = this.elem.className.split(" ");
  for (var i=0; i<arr.length; i++)
    if (arr[i] == className)
    {
      arr.splice(i, 1);
      break;
    }
  this.elem.className = arr.join(" ");
  return self;
}

fan.dom.StylePeer.prototype.clear = function(self)
{
  this.style.cssText = "";
  return self;
}

fan.dom.StylePeer.prototype.computed = function(self, name)
{
  if (!this.elem) return null;
  return window.getComputedStyle(this.elem).getPropertyValue(name);
}

fan.dom.StylePeer.prototype.effective = function(self, name)
{
  if (!this.elem) return null;

  // inline style rule always wins
  var val = this.get(self, name);
  if (val != null && val != "") return val;

  // else walk sheets
  var matches = [];
  for (var i=0; i<document.styleSheets.length; i++)
  {
    var sheet = document.styleSheets[i];
    var rules = sheet.rules || sheet.cssRules;
    for (var r=0; r<rules.length; r++)
    {
      var rule = rules[r];
      if (this.elem.matches(rule.selectorText))
        matches.push(rule);
    }
  }

  // walk backwards to find last val
  for (var m=matches.length-1; m>=0; m--)
  {
    val = matches[m].style.getPropertyValue(name);
    if (val != null && val != "") return val;
  }

  return null;
}

fan.dom.StylePeer.prototype.get = function(self, name)
{
  return this.style.getPropertyValue(name);
}

fan.dom.StylePeer.prototype.setProp = function(self, name, val)
{
  if (val == null) this.style.removeProperty(name);
  else this.style.setProperty(name, val);
}
