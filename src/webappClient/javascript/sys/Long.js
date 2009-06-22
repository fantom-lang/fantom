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

Long.Zero   = new Long(0, 0);
Long.One    = new Long(0, 1);
Long.NegOne = new Long(0xffffffff, 0xffffffff);
Long.Pow32  = Math.pow(2, 32);

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
// Bitwise operators
//////////////////////////////////////////////////////////////////////////

/*
Long.and = function(a, b)
{
  var high = a.high & b.high; if (high < 0) high = 0xffffffff + 1;
  var low  = a.low  & b.low;  if (low < 0)  low  = 0xffffffff + 1;
  return new Long(high, low);
}

Long.or = function(a, b)
{
  var high = a.high | b.high; if (high < 0) high = 0xffffffff + 1;
  var low  = a.low  | b.low;  if (low < 0)  low  = 0xffffffff + 1;
  return new Long(high, low);
}

Long.shl = function(a, n)
{
  var a4 = (a.high >> 16) & 0xffff;
  var a3 = (a.high & 0xffff);
  var a2 = (a.low >> 16) & 0xffff;
  var a1 = (a.low & 0xffff);

  a4 = a4 << n;
  a3 = a3 << n;
  a2 = a2 << n;
  a1 = a1 << n;

  var hi = (a4 << 16) | a3 | ((a2 & 0xffff0000) >> 16);
  var lo = (a2 << 16) | a1;  if (lo < 0) lo += 0xffffffff+1;

  return new Long(hi, lo);
}

Long.shr = function(a, n)
{
  // TODO
  var x = a.low >> n;
  if (x < 0) x += 0xffffffff+1;
  return new Long(0, x);
}
*/

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

Long.prototype.toString = function(radix)
{
  if (this.str == null)
  {
    if (radix == undefined) radix = 10;

    var s = "";
    var val = this;
    var rad = Long.fromNumber(radix);

    // negative
    var neg = (val.high & 0x80000000) != 0 && radix != 16;

    // write chars backwards
    while (true)
    {
      s = "0123456789abcdef".charAt(Long.mod(val, rad)) + s;
      val = Long.div(val, rad);
      if (val.equals(Long.Zero)) break
    }

    if (neg) s = '-' + s;
    this.str = s;
  }
  return this.str;
}

Long.fromStr = function(s, radix)
{
  if (radix == 10) return Long.fromStr10(s);
  if (radix == 16) return Long.fromStr16(s);
  throw new Error("Unsupported radix " + radix);
}

Long.fromStr10 = function(s)
{
  var neg = false;
  if (s.charAt(0) == '-')
  {
    s = s.substring(1);
    neg = true;
  }

  var num = Long.Zero;
  var ten = 0;
  for (var i=s.length-1; i>=0; --i)
  {
    var ch = s.charCodeAt(i);
    if (ch < 48 || ch > 57) throw new Error("Illegal decimal character " + s.charAt(i));
    num = Long.add(num, lookup[ten][ch - 48]);
    ten += 1
  }

  //if (neg) num = Long.mul(num, Long.NegOne);
  return num;
}

Long.fromStr16 = function(s)
{
  if (s.length <= 8)
  {
    var lo = Long.parseHex(s);
    return new Long(0, lo);
  }
  else
  {
    var i  = s.length - 8;
    var hi = Long.parseHex(s.substring(0, i));
    var lo = Long.parseHex(s.substring(i));
    return new Long(hi, lo);
  }

}

Long.parseHex = function(s)
{
  for (var i=0; i<s.length; i++)
  {
    ch = s.charCodeAt(i);
    if (ch >= 48 && ch <= 57) continue;
    if (ch >= 65 && ch <= 70) continue;
    if (ch >= 97 && ch <= 102) continue;
    throw new Error("Illegal hex char " + s.charAt(i));
  }
  return parseInt(s, 16);
}

//////////////////////////////////////////////////////////////////////////
// fromStr Lookup Table
//////////////////////////////////////////////////////////////////////////

// auto-generated from webappClient/genLong.fan script
var lookup =
[
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0x1),
    new Long(0x0, 0x2),
    new Long(0x0, 0x3),
    new Long(0x0, 0x4),
    new Long(0x0, 0x5),
    new Long(0x0, 0x6),
    new Long(0x0, 0x7),
    new Long(0x0, 0x8),
    new Long(0x0, 0x9),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0xa),
    new Long(0x0, 0x14),
    new Long(0x0, 0x1e),
    new Long(0x0, 0x28),
    new Long(0x0, 0x32),
    new Long(0x0, 0x3c),
    new Long(0x0, 0x46),
    new Long(0x0, 0x50),
    new Long(0x0, 0x5a),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0x64),
    new Long(0x0, 0xc8),
    new Long(0x0, 0x12c),
    new Long(0x0, 0x190),
    new Long(0x0, 0x1f4),
    new Long(0x0, 0x258),
    new Long(0x0, 0x2bc),
    new Long(0x0, 0x320),
    new Long(0x0, 0x384),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0x3e8),
    new Long(0x0, 0x7d0),
    new Long(0x0, 0xbb8),
    new Long(0x0, 0xfa0),
    new Long(0x0, 0x1388),
    new Long(0x0, 0x1770),
    new Long(0x0, 0x1b58),
    new Long(0x0, 0x1f40),
    new Long(0x0, 0x2328),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0x2710),
    new Long(0x0, 0x4e20),
    new Long(0x0, 0x7530),
    new Long(0x0, 0x9c40),
    new Long(0x0, 0xc350),
    new Long(0x0, 0xea60),
    new Long(0x0, 0x11170),
    new Long(0x0, 0x13880),
    new Long(0x0, 0x15f90),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0x186a0),
    new Long(0x0, 0x30d40),
    new Long(0x0, 0x493e0),
    new Long(0x0, 0x61a80),
    new Long(0x0, 0x7a120),
    new Long(0x0, 0x927c0),
    new Long(0x0, 0xaae60),
    new Long(0x0, 0xc3500),
    new Long(0x0, 0xdbba0),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0xf4240),
    new Long(0x0, 0x1e8480),
    new Long(0x0, 0x2dc6c0),
    new Long(0x0, 0x3d0900),
    new Long(0x0, 0x4c4b40),
    new Long(0x0, 0x5b8d80),
    new Long(0x0, 0x6acfc0),
    new Long(0x0, 0x7a1200),
    new Long(0x0, 0x895440),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0x989680),
    new Long(0x0, 0x1312d00),
    new Long(0x0, 0x1c9c380),
    new Long(0x0, 0x2625a00),
    new Long(0x0, 0x2faf080),
    new Long(0x0, 0x3938700),
    new Long(0x0, 0x42c1d80),
    new Long(0x0, 0x4c4b400),
    new Long(0x0, 0x55d4a80),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0x5f5e100),
    new Long(0x0, 0xbebc200),
    new Long(0x0, 0x11e1a300),
    new Long(0x0, 0x17d78400),
    new Long(0x0, 0x1dcd6500),
    new Long(0x0, 0x23c34600),
    new Long(0x0, 0x29b92700),
    new Long(0x0, 0x2faf0800),
    new Long(0x0, 0x35a4e900),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x0, 0x3b9aca00),
    new Long(0x0, 0x77359400),
    new Long(0x0, 0xb2d05e00),
    new Long(0x0, 0xee6b2800),
    new Long(0x1, 0x2a05f200),
    new Long(0x1, 0x65a0bc00),
    new Long(0x1, 0xa13b8600),
    new Long(0x1, 0xdcd65000),
    new Long(0x2, 0x18711a00),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x2, 0x540be400),
    new Long(0x4, 0xa817c800),
    new Long(0x6, 0xfc23ac00),
    new Long(0x9, 0x502f9000),
    new Long(0xb, 0xa43b7400),
    new Long(0xd, 0xf8475800),
    new Long(0x10, 0x4c533c00),
    new Long(0x12, 0xa05f2000),
    new Long(0x14, 0xf46b0400),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x17, 0x4876e800),
    new Long(0x2e, 0x90edd000),
    new Long(0x45, 0xd964b800),
    new Long(0x5d, 0x21dba000),
    new Long(0x74, 0x6a528800),
    new Long(0x8b, 0xb2c97000),
    new Long(0xa2, 0xfb405800),
    new Long(0xba, 0x43b74000),
    new Long(0xd1, 0x8c2e2800),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0xe8, 0xd4a51000),
    new Long(0x1d1, 0xa94a2000),
    new Long(0x2ba, 0x7def3000),
    new Long(0x3a3, 0x52944000),
    new Long(0x48c, 0x27395000),
    new Long(0x574, 0xfbde6000),
    new Long(0x65d, 0xd0837000),
    new Long(0x746, 0xa5288000),
    new Long(0x82f, 0x79cd9000),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x918, 0x4e72a000),
    new Long(0x1230, 0x9ce54000),
    new Long(0x1b48, 0xeb57e000),
    new Long(0x2461, 0x39ca8000),
    new Long(0x2d79, 0x883d2000),
    new Long(0x3691, 0xd6afc000),
    new Long(0x3faa, 0x25226000),
    new Long(0x48c2, 0x73950000),
    new Long(0x51da, 0xc207a000),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x5af3, 0x107a4000),
    new Long(0xb5e6, 0x20f48000),
    new Long(0x110d9, 0x316ec000),
    new Long(0x16bcc, 0x41e90000),
    new Long(0x1c6bf, 0x52634000),
    new Long(0x221b2, 0x62dd8000),
    new Long(0x27ca5, 0x7357c000),
    new Long(0x2d798, 0x83d20000),
    new Long(0x3328b, 0x944c4000),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x38d7e, 0xa4c68000),
    new Long(0x71afd, 0x498d0000),
    new Long(0xaa87b, 0xee538000),
    new Long(0xe35fa, 0x931a0000),
    new Long(0x11c379, 0x37e08000),
    new Long(0x1550f7, 0xdca70000),
    new Long(0x18de76, 0x816d8000),
    new Long(0x1c6bf5, 0x26340000),
    new Long(0x1ff973, 0xcafa8000),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x2386f2, 0x6fc10000),
    new Long(0x470de4, 0xdf820000),
    new Long(0x6a94d7, 0x4f430000),
    new Long(0x8e1bc9, 0xbf040000),
    new Long(0xb1a2bc, 0x2ec50000),
    new Long(0xd529ae, 0x9e860000),
    new Long(0xf8b0a1, 0xe470000),
    new Long(0x11c3793, 0x7e080000),
    new Long(0x13fbe85, 0xedc90000),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x1634578, 0x5d8a0000),
    new Long(0x2c68af0, 0xbb140000),
    new Long(0x429d069, 0x189e0000),
    new Long(0x58d15e1, 0x76280000),
    new Long(0x6f05b59, 0xd3b20000),
    new Long(0x853a0d2, 0x313c0000),
    new Long(0x9b6e64a, 0x8ec60000),
    new Long(0xb1a2bc2, 0xec500000),
    new Long(0xc7d713b, 0x49da0000),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0xde0b6b3, 0xa7640000),
    new Long(0x1bc16d67, 0x4ec80000),
    new Long(0x29a2241a, 0xf62c0000),
    new Long(0x3782dace, 0x9d900000),
    new Long(0x45639182, 0x44f40000),
    new Long(0x53444835, 0xec580000),
    new Long(0x6124fee9, 0x93bc0000),
    new Long(0x6f05b59d, 0x3b200000),
    new Long(0x7ce66c50, 0xe2840000),
  ],
  [
    new Long(0x0, 0x0),
    new Long(0x8ac72304, 0x89e80000),
    new Long(0x158e4609, 0x13d00000),
    new Long(0xa055690d, 0x9db80000),
    new Long(0x2b1c8c12, 0x27a00000),
    new Long(0xb5e3af16, 0xb1880000),
    new Long(0x40aad21b, 0x3b700000),
    new Long(0xcb71f51f, 0xc5580000),
    new Long(0x56391824, 0x4f400000),
    new Long(0xe1003b28, 0xd9280000),
  ]
];