//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 10  Andy Frank  Creation
//

/**
 * RegexMatcher.
 */
fan.sys.RegexMatcher = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.RegexMatcher.prototype.$ctor = function(regexp, source, str)
{
  this.m_regexp = regexp;
  this.m_source = source;
  this.m_str = str + "";
  this.m_match = null;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.RegexMatcher.prototype.equals = function(that) { return this === that; }

fan.sys.RegexMatcher.prototype.toStr = function() { return this.m_source; }

fan.sys.RegexMatcher.prototype.$typeof = function() { return fan.sys.RegexMatcher.$type; }

//////////////////////////////////////////////////////////////////////////
// Matching
//////////////////////////////////////////////////////////////////////////

fan.sys.RegexMatcher.prototype.matches = function()
{
  if (!this.m_regexpForMatching)
    this.m_regexpForMatching = fan.sys.RegexMatcher.recompile(this.m_regexp, true);
  this.m_match = this.m_regexpForMatching.exec(this.m_str);
  return this.m_match != null && this.m_match[0].length === this.m_str.length;
}

fan.sys.RegexMatcher.prototype.find = function()
{
  if (!this.m_regexpForMatching)
    this.m_regexpForMatching = fan.sys.RegexMatcher.recompile(this.m_regexp, true);
  this.m_match = this.m_regexpForMatching.exec(this.m_str);
  return this.m_match != null;
}

//////////////////////////////////////////////////////////////////////////
// Replace
//////////////////////////////////////////////////////////////////////////

fan.sys.RegexMatcher.prototype.replaceFirst = function(replacement)
{
  return this.m_str.replace(fan.sys.RegexMatcher.recompile(this.m_regexp, false), replacement);
}

fan.sys.RegexMatcher.prototype.replaceAll = function(replacement)
{
  return this.m_str.replace(fan.sys.RegexMatcher.recompile(this.m_regexp, true), replacement);
}

//////////////////////////////////////////////////////////////////////////
// Group
//////////////////////////////////////////////////////////////////////////

fan.sys.RegexMatcher.prototype.groupCount = function()
{
  if (!this.m_match)
    return 0;
  return this.m_match.length - 1;
}

fan.sys.RegexMatcher.prototype.group = function(group)
{
  if (group === undefined) group = 0;
  if (!this.m_match)
    throw fan.sys.Err.make("No match found");
  if (group < 0 || group > this.groupCount())
    throw fan.sys.IndexErr.make(group);
  return this.m_match[group];
}

fan.sys.RegexMatcher.prototype.start = function(group)
{
  if (!this.m_match)
    throw fan.sys.Err.make("No match found");
  if (group === undefined) group = 0;
  if (group < 0 || group > this.groupCount())
    throw fan.sys.IndexErr.make(group);
  if (group === 0)
    return this.m_match.index;
  throw fan.sys.UnsupportedErr.make("Not implemented in javascript");
}

fan.sys.RegexMatcher.prototype.end = function(group)
{
  if (!this.m_match)
    throw fan.sys.Err.make("No match found");
  if (group === undefined) group = 0;
  if (group < 0 || group > this.groupCount())
    throw fan.sys.IndexErr.make(group);
  if (group === 0)
    return this.m_match.index + this.m_match[group].length;
  throw fan.sys.UnsupportedErr.make("Not implemented in javascript");
}

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

fan.sys.RegexMatcher.recompile = function(regexp, global)
{
  var flags = global ? "g" : "";
  if (regexp.ignoreCase) flags += "i";
  if (regexp.multiline)  flags += "m";
  if (regexp.unicode)    flags += "u";
  return new RegExp(regexp.source, flags);
}