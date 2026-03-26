//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Dec 2014  Andy Frank  Creation
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class StylePeer extends sys.Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(self)
  {
    // set in ElemPeer.style
    super();
    this.elem  = null;
    this.style = null;
  }

  classes(self, it)
  {
    if (it === undefined)
      return sys.List.make(sys.Str.type$, this.elem.classList);
    else
      this.elem.className = it.join(" ");
  }

  hasClass(self, className)
  {
    return this.elem.classList.contains(className);
  }

  addClass(self, className)
  {
    // split for legacy support for addClass("x y z")
    const arr = className.split(" ");
    for (let i=0; i<arr.length; i++) this.elem.classList.add(arr[i]);
    return self;
  }

  removeClass(self, className)
  {
    // split for legacy support for removeClass("x y z")
    const arr = className.split(" ");
    for (let i=0; i<arr.length; i++) this.elem.classList.remove(arr[i]);
    return self;
  }

  clear(self)
  {
    this.style.cssText = "";
    return self;
  }

  computed(self, name)
  {
    if (!this.elem) return null;
    return window.getComputedStyle(this.elem).getPropertyValue(name);
  }

  effective(self, name)
  {
    if (!this.elem) return null;

    // inline style rule always wins
    let val = this.get(self, name);
    if (val != null && val != "") return val;

    // else walk sheets
    const matches = [];
    for (let i=0; i<document.styleSheets.length; i++)
    {
      // it is a security exception to introspect the rules of a
      // stylesheet that was loaded from a different domain than
      // the current document; so just silently ignore those rules

      const sheet = document.styleSheets[i];
      let rules;
      try { rules = sheet.rules || sheet.cssRules || []; }
      catch (err) { rules = []; }

      for (let r=0; r<rules.length; r++)
      {
        const rule = rules[r];
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
    for (let m=matches.length-1; m>=0; m--)
    {
      val = matches[m].style.getPropertyValue(name);
      if (val != null && val != "") return val;
    }

    return null;
  }

  get(self, name)
  {
    return this.style.getPropertyValue(name);
  }

  setProp(self, name, val)
  {
    if (val == null) this.style.removeProperty(name);
    else this.style.setProperty(name, val);
  }

//////////////////////////////////////////////////////////////////////////
// Polyfill for classList (see ElemPeer.style)
//////////////////////////////////////////////////////////////////////////

  static polyfillClassList(e)
  {
    const elem = e;
    function list()
    {
      const attr = elem.getAttribute("class")
      return attr ? attr.split(" ") : [];
    }

    this.add = function(name)
    {
      const x = list();
      x.push(name);
      elem.setAttribute("class", x.join(" "));
    }

    this.remove = function(name)
    {
      const x = list();
      const i = x.indexOf(name);
      if (i >= 0)
      {
        x.splice(i, 1);
        elem.setAttribute("class", x.join(" "));
      }
    }

    this.contains = function(name)
    {
      return list().indexOf(name) >= 0;
    }
  }
}