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
  return fan.sys.List.make(fan.sys.Str.$type, this.elem.classList);
}

fan.dom.StylePeer.prototype.classes$ = function(self, val)
{
  this.elem.className = val.join(" ");
  return this.classes();
}

fan.dom.StylePeer.prototype.hasClass = function(self, className)
{
  return this.elem.classList.contains(className);
}

fan.dom.StylePeer.prototype.addClass = function(self, className)
{
  // split for legacy support for addClass("x y z")
  var arr = className.split(" ");
  for (var i=0; i<arr.length; i++) this.elem.classList.add(arr[i]);
  return self;
}

fan.dom.StylePeer.prototype.removeClass = function(self, className)
{
  // split for legacy support for removeClass("x y z")
  var arr = className.split(" ");
  for (var i=0; i<arr.length; i++) this.elem.classList.remove(arr[i]);
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
    // it is a security exception to introspect the rules of a
    // stylesheet that was loaded from a different domain than
    // the current document; so just silently ignore those rules

    var sheet = document.styleSheets[i];
    var rules;
    try { rules = sheet.rules || sheet.cssRules || []; }
    catch (err) { rules = []; }

    for (var r=0; r<rules.length; r++)
    {
      var rule = rules[r];
      if (this.elem.msMatchesSelector)
      {
        if (this.elem.msMatchesSelector(rule.selectorText))
          matches.push(rule);
      }
      else
      {
        // Safari 10 (at least) throws an err during matches() if it doesn't
        // understand the CSS selector; silently ignore these errs
        try
        {
          if (this.elem.matches(rule.selectorText))
            matches.push(rule);
        }
        catch (err) {}
      }
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
