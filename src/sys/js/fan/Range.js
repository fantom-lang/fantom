//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Range represents a contiguous range of integers from start to end.
 */
fan.sys.Range = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Range.prototype.$ctor = function(start, end, exclusive)
{
  this.m_start = start;
  this.m_end = end;
  this.m_exclusive = (exclusive === undefined) ? false : exclusive;
}

fan.sys.Range.makeInclusive = function(start, end)
{
  return new fan.sys.Range(start, end, false);
}

fan.sys.Range.makeExclusive = function(start, end)
{
  return new fan.sys.Range(start, end, true);
}

fan.sys.Range.make = function(start, end, exclusive)
{
  return new fan.sys.Range(start, end, exclusive);
}

fan.sys.Range.fromStr = function(s, checked)
{
  if (checked === undefined) checked = true;
  try
  {
    var dot = s.indexOf('.');
    if (s.charAt(dot+1) != '.') throw new Error();
    var exclusive = s.charAt(dot+2) == '<';
    var start = fan.sys.Int.fromStr(s.substr(0, dot));
    var end   = fan.sys.Int.fromStr(s.substr(dot + (exclusive?3:2)));
    return new fan.sys.Range(start, end, exclusive);
  }
  catch (err) {}
  if (!checked) return null;
  throw fan.sys.ParseErr.make("Range", s);
}

//////////////////////////////////////////////////////////////////////////
// Range
//////////////////////////////////////////////////////////////////////////

fan.sys.Range.prototype.start = function() { return this.m_start; }
fan.sys.Range.prototype.end   = function() { return this.m_end; }
fan.sys.Range.prototype.inclusive = function() { return !this.m_exclusive; }
fan.sys.Range.prototype.exclusive = function() { return this.m_exclusive; }

fan.sys.Range.prototype.isEmpty = function()
{
  return this.m_exclusive && this.m_start == this.m_end;
}

fan.sys.Range.prototype.min = function()
{
  if (this.isEmpty()) return null;
  if (this.m_end < this.m_start) return this.m_exclusive ? this.m_end+1 : this.m_end;
  return this.m_start;
}

fan.sys.Range.prototype.max = function()
{
  if (this.isEmpty()) return null;
  if (this.m_end < this.m_start) return this.m_start;
  return this.m_exclusive ? this.m_end-1 : this.m_end;
}

fan.sys.Range.prototype.first = function()
{
  if (this.isEmpty()) return null;
  return this.m_start;
}

fan.sys.Range.prototype.last = function()
{
  if (this.isEmpty()) return null;
  if (!this.m_exclusive) return this.m_end;
  if (this.m_start < this.m_end) return this.m_end-1;
  return this.m_end+1;
}

fan.sys.Range.prototype.contains = function(i)
{
  if (this.m_start < this.m_end)
  {
    if (this.m_exclusive)
      return this.m_start <= i && i < this.m_end;
    else
      return this.m_start <= i && i <= this.m_end;
  }
  else
  {
    if (this.m_exclusive)
      return this.m_end < i && i <= this.m_start;
    else
      return this.m_end <= i && i <= this.m_start;
  }
}

fan.sys.Range.prototype.offset = function(offset)
{
  if (offset == 0) return this;
  return fan.sys.Range.make(this.m_start+offset, this.m_end+offset, this.m_exclusive);
}

fan.sys.Range.prototype.each = function(func)
{
  var start = this.m_start;
  var end   = this.m_end;
  if (start < end)
  {
    if (this.m_exclusive) --end;
    for (var i=start; i<=end; ++i) func.call(i);
  }
  else
  {
    if (this.m_exclusive) ++end;
    for (var i=start; i>=end; --i) func.call(i);
  }
}

fan.sys.Range.prototype.map = function(func)
{
  var r = func.returns();
  if (r === fan.sys.Void.$type) r = fan.sys.Obj.$type.toNullable();
  var acc   = fan.sys.List.make(r);
  var start = this.m_start;
  var end   = this.m_end;
  if (start < end)
  {
    if (this.m_exclusive) --end;
    for (var i=start; i<=end; ++i) acc.add(func.call(i));
  }
  else
  {
    if (this.m_exclusive) ++end;
    for (var i=start; i>=end; --i) acc.add(func.call(i));
  }
  return acc;
}

fan.sys.Range.prototype.toList = function()
{
  var start = this.m_start;
  var end = this.m_end;
  var acc = fan.sys.List.make(fan.sys.Int.$type);
  if (start < end)
  {
    if (this.m_exclusive) --end;
    for (var i=start; i<=end; ++i) acc.push(i);
  }
  else
  {
    if (this.m_exclusive) ++end;
    for (var i=start; i>=end; --i) acc.push(i);
  }
  return acc;
}

fan.sys.Range.prototype.random = function() { return fan.sys.Int.random(this); }

fan.sys.Range.prototype.equals = function(that)
{
  if (that instanceof fan.sys.Range)
  {
    return this.m_start == that.m_start &&
           this.m_end == that.m_end &&
           this.m_exclusive == that.m_exclusive;
  }
  return false;
}

fan.sys.Range.prototype.hash = function() { return (this.m_start << 24) ^ this.m_end; }

fan.sys.Range.prototype.toStr = function()
{
  if (this.m_exclusive)
    return this.m_start + "..<" + this.m_end;
  else
    return this.m_start + ".." + this.m_end;
}

fan.sys.Range.prototype.$typeof = function() { return fan.sys.Range.$type;}

fan.sys.Range.prototype.$start = function(size)
{
  if (size == null) return this.m_start;

  var x = this.m_start;
  if (x < 0) x = size + x;
  if (x > size) throw fan.sys.IndexErr.make(this);
  return x;
}

fan.sys.Range.prototype.$end = function(size)
{
  if (size == null) return this.m_end;

  var x = this.m_end;
  if (x < 0) x = size + x;
  if (this.m_exclusive) x--;
  if (x >= size) throw fan.sys.IndexErr.make(this);
  return x;
}

