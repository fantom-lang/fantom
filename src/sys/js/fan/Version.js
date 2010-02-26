//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Feb 10  Andy Frank  Creation
//

/**
 * Version.
 */
fan.sys.Version = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.Version.fromStr = function(s, checked)
{
  if (checked === undefined) checked = true;
  var segments = fan.sys.List.make(fan.sys.Int.$type);
  var seg = -1;
  var valid = true;
  var len = s.length;
  for (var i=0; i<len; ++i)
  {
    var c = s.charCodeAt(i);
    if (c == 46)
    {
      if (seg < 0 || i+1>=len) { valid = false; break; }
      segments.add(seg);
      seg = -1;
    }
    else
    {
      if (48 <= c && c <= 57)
      {
        if (seg < 0) seg = c-48;
        else seg = seg*10 + (c-48);
      }
      else
      {
        valid = false; break;
      }
    }
  }
  if (seg >= 0) segments.add(seg);

  if (!valid || segments.size() == 0)
  {
    if (checked)
      throw fan.sys.ParseErr.make("Version", s);
    else
      return null;
  }

  return new fan.sys.Version(segments);
}

fan.sys.Version.make = function(segments)
{
  var valid = segments.size() > 0;
  for (var i=0; i<segments.size(); ++i)
    if (segments.get(i) < 0) valid = false;
  if (!valid) throw fan.sys.ArgErr.make("Invalid Version: '" + segments + "'");
  return new fan.sys.Version(segments);
}

fan.sys.Version.prototype.$ctor = function(segments)
{
  this.m_segments = segments.ro();
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Version.prototype.equals = function(obj)
{
  if (obj instanceof fan.sys.Version)
    return this.toStr() == obj.toStr();
  else
    return false;
}

fan.sys.Version.prototype.compare = function(obj)
{
  var that = obj;
  var a = this.m_segments;
  var b = that.m_segments;
  for (var i=0; i<a.size() && i<b.size(); ++i)
  {
    var ai = a.get(i);
    var bi = b.get(i);
    if (ai < bi) return -1;
    if (ai > bi) return +1;
  }
  if (a.size() < b.size()) return -1;
  if (a.size() > b.size()) return +1;
  return 0;
}

fan.sys.Version.prototype.hash = function() { return fan.sys.Str.hash(this.toStr()); }
fan.sys.Version.prototype.$typeof = function() { return fan.sys.Version.$type; }
fan.sys.Version.prototype.toStr = function()
{
  if (this.m_str == null)
  {
    var s = "";
    for (var i=0; i<this.m_segments.size(); ++i)
    {
      if (i > 0) s += '.';
      s += this.m_segments.get(i);
    }
    this.m_s = s;
  }
  return this.m_s;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Version.prototype.segments = function() { return this.m_segments; }

fan.sys.Version.prototype.major = function() { return this.m_segments.get(0); }

fan.sys.Version.prototype.minor = function()
{
  if (this.m_segments.size() < 2) return null;
  return this.m_segments.get(1);
}

fan.sys.Version.prototype.build = function()
{
  if (this.m_segments.size() < 3) return null;
  return this.m_segments.get(2);
}

fan.sys.Version.prototype.patch = function()
{
  if (this.m_segments.size() < 4) return null;
  return this.m_segments.get(3);
}

