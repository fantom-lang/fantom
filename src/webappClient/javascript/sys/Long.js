//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 09  Andy Frank  Creation
//

/**
 * Long provides 64-bit integer support, but "gracefully" degrades
 * to interop with native Number objects (with loss of precision).
 */
function Long(high, low)
{
  // roll low bits into high if out of range
  if (low > 0xffffffff)
  {
    var diff = (low % Long.Pow32);
    high += Math.floor(low / Long.Pow32);
    low = diff;
  }
  else if (low < 0)
  {
    high--;
    low = 0xffffffff + low + 1;
  }

  // always cap to 64-bits
  if (high > 0xffffffff) high = 0xffffffff;

  this.high = high;
  this.low  = low;
  this.str  = null;
}

//////////////////////////////////////////////////////////////////////////
// Interop
//////////////////////////////////////////////////////////////////////////

// Extend Number and override valueOf to make Long interop
// with normal js Numbers.  Note that val will not be precise
// so large numbers will be incorrect.  You must wrap native
// numbers using Long.fromNumber and use the Long.add,sub,etc
// functions to retain precision.

Long.prototype = new Number;
Long.prototype.constructor = Number.constructor;

Long.prototype.valueOf = function()
{
  if (this.val == null) this.val = (this.high * Long.Pow32) + this.low;
  return this.val;
}

Long.fromNumber = function(num)
{
  var high = Math.floor(num / Long.Pow32);
  var low  = num & 0xffffffff; if (low < 0) low += 0xffffffff+1;
  return new Long(high, low);
}

Long.Zero  = new Long(0, 0);
Long.One   = new Long(0, 1);
Long.Pow32 = Math.pow(2, 32);

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

Long.prototype.equals = function(that)
{
  return this.high == that.high && this.low == that.low;
}

Long.prototype.compare = function(that)
{
  if (this.equals(that)) return 0;

  if (this.high > that.high) return 1;
  if (this.high < that.high) return -1;

  if (this.low > that.low) return 1;
  if (this.low < that.low) return -1;
}

//////////////////////////////////////////////////////////////////////////
// Arithemtic
//////////////////////////////////////////////////////////////////////////

Long.add = function(a, b)
{
  var high = a.high + b.high;
  var low  = a.low + b.low;
  return new Long(high, low);
}

Long.sub = function(a, b)
{
  var high = a.high - b.high;
  var low  = a.low - b.low;
  return new Long(high, low);
}

Long.mul = function(a, b)
{
  //
  // Multipy code modified from GWT LongLib
  // com.google.gwt.lang.LongLib
  //
  // Copyright 2008 Google Inc.
  // Used under Apache 2.0 License
  //
  // http://code.google.com/webtoolkit/
  //

  if (a.high === 0 && a.low === 0) return Long.Zero;
  if (b.high === 0 && b.low === 0) return Long.Zero;

  // TODO: optimize cases where we can multipy w/ native operator

  var a4 = a.high & 0xffff0000; if (a4 < 0) a4 += 0xffffffff+1;
  var a3 = a.high & 0xffff;
  var a2 = a.low  & 0xffff0000; if (a2 < 0) a2 += 0xffffffff+1;
  var a1 = a.low  & 0xffff;

  var b4 = b.high & 0xffff0000; if (b4 < 0) b4 += 0xffffffff+1;
  var b3 = b.high & 0xffff;
  var b2 = b.low  & 0xffff0000; if (b2 < 0) b2 += 0xffffffff+1;
  var b1 = b.low  & 0xffff;

  a4 = a4 * Long.Pow32;
  a3 = a3 * Long.Pow32;
  b4 = b4 * Long.Pow32;
  b3 = b3 * Long.Pow32;

  var res = Long.Zero;

  res = this.addTimes(res, a4, b1);
  res = this.addTimes(res, a3, b2);
  res = this.addTimes(res, a3, b1);
  res = this.addTimes(res, a2, b3);
  res = this.addTimes(res, a2, b2);
  res = this.addTimes(res, a2, b1);
  res = this.addTimes(res, a1, b4);
  res = this.addTimes(res, a1, b3);
  res = this.addTimes(res, a1, b2);
  res = this.addTimes(res, a1, b1);

  return res;
}

Long.addTimes = function(acc, a, b)
{
  if (a === 0) return acc;
  if (b === 0) return acc;
  return Long.add(acc, Long.fromNumber(a*b));
}

Long.div = function(a, b)
{
  //
  // Division code modified from GWT LongLib
  // com.google.gwt.lang.LongLib
  //
  // Copyright 2008 Google Inc.
  // Used under Apache 2.0 License
  //
  // http://code.google.com/webtoolkit/
  //

  if (a === 0) return acc;
  if (b === 0) throw sys_Err.make("/ by zero");

  // TODO - handle negative

  var res = Long.Zero;
  var rem = a;
  var bup = Long.roundUp(b);
  while (rem.compare(b) >= 0)
  {
    // approximate using float division
    var num = Math.floor(Long.roundDown(rem) / bup);
    var deltaRes = Long.fromNumber(num);
    if (deltaRes.high === 0 && deltaRes.low === 0) deltaRes = Long.One;
    var deltaRem = Long.mul(deltaRes, b);

    //if (deltaRes.compare(Long.One) < 0) throw sys_Err.make("assert failed: deltaRes < 1");
    //if (deltaRem.compare(rem) > 0) throw sys_Err.make("assert failed: deltaRem > rem");

    res = Long.add(res, deltaRes);
    rem = Long.sub(rem, deltaRem);
  }

  return res;
}

Long.roundDown = function(a)
{
  var high = a.high * Long.Pow32;
  var mag = Math.floor(Math.log(high) / Long.Ln2);
  if (mag <= Long.PrecisionBits)
  {
    return high + a.low;
  }
  else
  {
    var diff  = mag - Long.PrecisionBits;
    var toSub = (1 << diff) - 1;
    return high + (a.low - toSub);
  }
}

Long.roundUp = function(a)
{
  var high = a.high * Long.Pow32;
  var mag = Math.floor(Math.log(high) / Long.Ln2);
  if (mag <= Long.PrecisionBits)
  {
    return high + a.low;
  }
  else
  {
    var diff  = mag - Long.PrecisionBits;
    var toAdd = (1 << diff) - 1;
    return high + (a.low + toAdd);
  }
}

Long.PrecisionBits = 48;  // num bits we except Number can represent for large ints
Long.Ln2 = Math.log(2);

Long.mod = function(a, b)
{
  return Long.sub(a, Long.mul(Long.div(a, b), b));
}

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

Long.prototype.toString = function()
{
  if (this.str == null)
  {
    var s = "";
    var val = this;
    var radix = Long.fromNumber(10);

    // negative
    var neg = (val.high & 0x80000000) != 0 && radix != 16;

    // write chars backwards
    while (true)
    {
      s = "0123456789abcdef".charAt(Long.mod(val, radix)) + s;
      val = Long.div(val, radix);
      if (val.equals(Long.Zero)) break
    }

    if (neg) s = '-' + s;
    this.str = s;
  }
  return this.str;
}

