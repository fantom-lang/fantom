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

fan.sys.Regex.quote = function(pattern)
{
  var s = "";
  for (var i=0; i<pattern.length; ++i)
  {
    var c = pattern.charCodeAt(i);
    if (fan.sys.Int.isAlphaNum(c)) s += String.fromCharCode(c);
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
    return obj.m_source === this.m_source;
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
  return this.matcher(s).matches();
}

fan.sys.Regex.prototype.matcher = function(s)
{
  return new fan.sys.RegexMatcher(this.m_regexp, this.m_source, s);
}

fan.sys.Regex.prototype.split = function(s, limit)
{
  if (limit === undefined) limit = 0;

  if (limit === 1)
    return fan.sys.List.make(fan.sys.Str.$type, [s]);

  var array = [];
  var re = this.m_regexp;
  while (true)
  {
    var m = s.match(re);
    if (m == null || (limit != 0 && array.length == limit -1))
    {
      array.push(s);
      break;
    }
    array.push(s.substring(0, m.index));
    s = s.substring(m.index + m[0].length);
  }
  // remove trailing empty strings
  if (limit == 0)
  {
    while (array[array.length-1] == "") { array.pop(); }
  }
  return fan.sys.List.make(fan.sys.Str.$type, array);
}
