//
// Copyright (c) 2011 Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jan 11  Andy Frank  Creation
//

/**
 * Depend.
 */
fan.sys.Depend = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Depend.prototype.$ctor = function(name, constraints)
{
  this.m_$name = name;
  this.m_constraints = constraints;
  this.m_str = null;
}

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.Depend.fromStr = function(str, checked)
{
  if (checked === undefined) checked = true;
  try
  {
    // allow try-block to capture errs
    var d = new fan.sys.DependParser(str).parse();
    return d;
  }
  catch (err)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.makeStr("Depend", str);
  }
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Depend.prototype.equals = function(obj)
{
  if (obj instanceof fan.sys.Depend)
    return this.toStr().equals(obj.toStr());
  else
    return false;
}

fan.sys.Depend.prototype.hash = function()
{
  return fan.sys.Str.hash(this.toStr());
}

fan.sys.Depend.prototype.$typeof = function()
{
  return fan.sys.Depend.$type;
}

fan.sys.Depend.prototype.toStr = function()
{
  if (this.m_str == null)
  {
    var s = "";
    s += this.m_$name + " ";
    for (var i=0; i<this.m_constraints.length; ++i)
    {
      if (i > 0) s += ",";
      var c = this.m_constraints[i];
      s += c.m_version;
      if (c.m_isPlus) s += "+";
      if (c.m_endVersion != null) s += "-" + c.m_endVersion;
    }
    this.m_str = s.toString();
  }
  return this.m_str;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Depend.prototype.$name = function()
{
  return this.m_$name;
}

fan.sys.Depend.prototype.size = function()
{
  return this.m_constraints.length;
}

fan.sys.Depend.prototype.version = function( index)
{
  if (index === undefined) index = 0;
  return this.m_constraints[index].m_version;
}

fan.sys.Depend.prototype.isPlus = function(index)
{
  if (index === undefined) index = 0;
  return this.m_constraints[index].m_isPlus;
}

fan.sys.Depend.prototype.isRange = function(index)
{
  if (index === undefined) index = 0;
  return this.m_constraints[index].m_endVersion != null;
}

fan.sys.Depend.prototype.endVersion = function(index)
{
  if (index === undefined) index = 0;
  return this.m_constraints[index].m_endVersion;
}

fan.sys.Depend.prototype.match = function(v)
{
  for (var i=0; i<this.m_constraints.length; ++i)
  {
    var c = this.m_constraints[i];
    if (c.m_isPlus)
    {
      // versionPlus
      if (c.m_version.compare(v) <= 0)
        return true;
    }
    else if (c.m_endVersion != null)
    {
      // versionRange
      if (c.m_version.compare(v) <= 0 &&
          (c.m_endVersion.compare(v) >= 0 || fan.sys.Depend.doMatch(c.m_endVersion, v)))
        return true;
    }
    else
    {
      // versionSimple
      if (fan.sys.Depend.doMatch(c.m_version, v))
        return true;
    }
  }
  return false;
}

fan.sys.Depend.doMatch = function(a, b)
{
  if (a.segments().size() > b.segments().size()) return false;
  for (var i=0; i<a.segments().size(); ++i)
    if (a.segment(i) != b.segment(i))
      return false;
  return true;
}

//////////////////////////////////////////////////////////////////////////
// DependConstraint
//////////////////////////////////////////////////////////////////////////

fan.sys.DependConstraint = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.DependConstraint.prototype.$ctor = function()
{
  this.m_version = null;
  this.m_isPlus  = false;
  this.m_endVersion = null;
}

//////////////////////////////////////////////////////////////////////////
// DependParser
//////////////////////////////////////////////////////////////////////////

fan.sys.DependParser = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.DependParser.prototype.$ctor = function(str)
{
  this.m_cur = 0;
  this.m_pos = 0;
  this.m_str = str;
  this.m_len = str.length;
  this.m_$name;
  this.m_constraints = [];
  this.consume();
}

fan.sys.DependParser.prototype.parse = function()
{
  this.m_$name = this.$name();
  this.m_constraints.push(this.constraint());
  while (this.m_cur == 44)
  {
    this.consume();
    this.consumeSpaces();
    this.m_constraints.push(this.constraint());
  }
  if (this.m_pos <= this.m_len) throw new Error();
  return new fan.sys.Depend(this.m_$name, this.m_constraints);
}

fan.sys.DependParser.prototype.$name = function()
{
  var s = ""
  while (this.m_cur != 32)
  {
    if (this.m_cur < 0) throw new Error();
    s += String.fromCharCode(this.m_cur);
    this.consume();
  }
  this.consumeSpaces();
  if (s.length == 0) throw new Error();
  return s;
}

fan.sys.DependParser.prototype.constraint = function()
{
  var c = new fan.sys.DependConstraint();
  c.m_version = this.version();
  this.consumeSpaces();
  if (this.m_cur == 43)
  {
    c.m_isPlus = true;
    this.consume();
    this.consumeSpaces();
  }
  else if (this.m_cur == 45)
  {
    this.consume();
    this.consumeSpaces();
    c.m_endVersion = this.version();
    this.consumeSpaces();
  }
  return c;
}

fan.sys.DependParser.prototype.version = function()
{
  var segs = fan.sys.List.make(fan.sys.Int.$type);
  var seg = this.consumeDigit();
  while (true)
  {
    if (48 <= this.m_cur && this.m_cur <= 57)
    {
      seg = seg*10 + this.consumeDigit();
    }
    else
    {
      segs.add(seg);
      seg = 0;
      if (this.m_cur != 46) break;
      else this.consume();
    }
  }
  return fan.sys.Version.make(segs);
}

fan.sys.DependParser.prototype.consumeDigit = function()
{
  if (48 <= this.m_cur && this.m_cur <= 57)
  {
    var digit = this.m_cur - 48;
    this.consume();
    return digit;
  }
  throw new Error();
}

fan.sys.DependParser.prototype.consumeSpaces = function()
{
  while (this.m_cur == 32) this.consume();
}

fan.sys.DependParser.prototype.consume = function()
{
  if (this.m_pos < this.m_len)
  {
    this.m_cur = this.m_str.charCodeAt(this.m_pos++);
  }
  else
  {
    this.m_cur = -1;
    this.m_pos = this.m_len+1;
  }
}

