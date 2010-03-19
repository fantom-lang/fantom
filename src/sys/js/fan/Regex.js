//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 10  Andy Frank  Creation
//

/**
 * Regex.
 */
fan.sys.Regex = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Regex.fromStr = function(pattern)
{
  return new fan.sys.Regex(pattern);
}

fan.sys.Regex.glob = function(pattern)
{
  var s = "";
  for (var i=0; i<pattern.length; ++i)
  {
    var c = pattern.charCodeAt(i);
    if (fan.sys.Int.isAlphaNum(c)) s += String.fromCharCode(c);
    else if (c == 63) s += '.';
    else if (c == 42) s += '.*';
    else s += '\\' + String.fromCharCode(c);
  }
  return new fan.sys.Regex(s);
}

fan.sys.Regex.prototype.$ctor = function(source)
{
  this.m_source = source;
  this.m_regexp = new RegExp(source);
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Regex.prototype.equals = function(obj)
{
  if (obj instanceof fan.sys.Regex)
    return obj.m_source == this.m_source;
  else
    return false;
}

fan.sys.Regex.prototype.hash = function() { return fan.sys.Str.hash(this.m_source); }

fan.sys.Regex.prototype.toStr = function() { return this.m_source; }

fan.sys.Regex.prototype.$typeof = function() { return fan.sys.Regex.$type; }

//////////////////////////////////////////////////////////////////////////
// Regular expression
//////////////////////////////////////////////////////////////////////////

fan.sys.Regex.prototype.matches = function(s)
{
  return this.m_regexp.test(s);
}

//fan.sys.Regex.prototype.matcher = function(s)
//{
//  return new RegexMatcher(pattern.matcher(s));
//}

fan.sys.Regex.prototype.split = function(s, limit)
{
  if (limit === undefined) limit = 0;

  // TODO FIXIT: limit works very differently in Java
  var re = this.m_regexp;
  var array = (limit === 0) ? s.split(re) : s.split(re, limit);
  return fan.sys.List.make(fan.sys.Str.$type, array);
}

