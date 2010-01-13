//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Int
 */
fan.sys.Int = fan.sys.Obj.$extend(fan.sys.Num);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Int.prototype.$ctor = function() {}
fan.sys.Int.prototype.type = function() { return fan.sys.Int.$type; }

fan.sys.Int.make = function(val) { return val; }

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Int.fromStr = function(s, radix, checked)
{
  if (radix === undefined) radix = 10;
  if (checked === undefined) checked = true;
  try
  {
    if (s == null || s.length == 0) throw Error();
    var num = Long.fromStr(s, radix);
    return num;
  }
  catch (err) {}
  if (checked) throw fan.sys.ParseErr.make("Int", s);
  return null;
}

fan.sys.Int.toStr = function(self)
{
  return ""+self;
}

fan.sys.Int.equals = function(self, obj)
{
  var sis = self instanceof Long;
  var ois = obj instanceof Long;
  if (sis || ois)
  {
    if (!sis) self = Long.fromNumber(self);
    if (!ois) obj = Long.fromNumber(obj);
    return self.equals(obj);
  }
  else return self == obj;
}

fan.sys.Int.abs = function(self) { return self < 0 ? -self : self; }
fan.sys.Int.min = function(self, val) { return self < val ? self : val; }
fan.sys.Int.max = function(self, val) { return self > val ? self : val; }

fan.sys.Int.isEven  = function(self) { return self % 2 == 0; }
fan.sys.Int.isOdd   = function(self) { return self % 2 != 0; }
fan.sys.Int.isSpace = function(self) { return self == 32 || self == 9 || self == 10 || self == 13; }

fan.sys.Int.isDigit = function(self, radix)
{
  if (radix == null || radix == 10) return self >= 48 && self <= 57;
  if (radix == 16)
  {
    if (self >= 48 && self <= 57) return true;
    if (self >= 65 && self <= 70) return true;
    if (self >= 97 && self <= 102) return true;
    return false;
  }
  if (radix <= 10) return 48 <= self && self <= (48+radix);
  var x = self-10;
  if (97 <= self && self <= 97+x) return true;
  if (65 <= self && self <= 65+x) return true;
  return false;
}

fan.sys.Int.toDigit = function(self, radix)
{
  if (radix == null || radix == 10) return 0 <= self && self <= 9 ? 48+self : null;
  if (self < 0 || self >= radix) return null;
  if (self < 10) return 48+self;
  return self-10+97;
}

fan.sys.Int.fromDigit = function(self, radix)
{
  if (self < 0 || self >= 128) return null;
  var ten = radix < 10 ? radix : 10;
  if (48 <= self && self < 48+ten) return self-48;
  if (radix > 10)
  {
    var alpha = radix-10;
    if (97 <= self && self < 97+alpha) return self+10-97;
    if (65 <= self && self < 65+alpha) return self+10-65;
  }
  return null;
}

fan.sys.Int.random = function(r)
{
  if (r === undefined) return Math.floor(Math.random() * Math.pow(2, 64));
  else
  {
    var start = r.start();
    var end   = r.end();
    if (r.inclusive()) ++end;
    if (end <= start) throw fan.sys.ArgErr.make("Range end < start: " + r);
    r = end-start;
    if (r < 0) r = -r;
    return Math.floor(Math.random()*r) + start;
  }
}

fan.sys.Int.isUpper    = function(self) { return self >= 65 && self <= 90; }
fan.sys.Int.isLower    = function(self) { return self >= 97 && self <= 122; }
fan.sys.Int.upper      = function(self) { return fan.sys.Int.isLower(self) ? self-32 : self; }
fan.sys.Int.lower      = function(self) { return fan.sys.Int.isUpper(self) ? self+32 : self; }
fan.sys.Int.isAlpha    = function(self) { return fan.sys.Int.isUpper(self) || fan.sys.Int.isLower(self); }
fan.sys.Int.isAlphaNum = function(self) { return fan.sys.Int.isAlpha(self) || fan.sys.Int.isDigit(self); }
fan.sys.Int.equalsIgnoreCase = function(self, ch) { return (self|0x20) == (ch|0x20); }


//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

fan.sys.Int.times = function(self, f)
{
  for (var i=0; i<self; i++)
    f.call(i);
}

//////////////////////////////////////////////////////////////////////////
// Arithmetic
//////////////////////////////////////////////////////////////////////////

fan.sys.Int.negate    = function(self) { return -self; }
fan.sys.Int.increment = function(self) { return self+1; }
fan.sys.Int.decrement = function(self) { return self-1; }

fan.sys.Int.plus = function(a, b)
{
  // always wrap with Long to make sure we retain precision
  if (!(a instanceof Long)) a = Long.fromNumber(a);
  if (!(b instanceof Long)) b = Long.fromNumber(b);
  return Long.add(a, b);
}

fan.sys.Int.minus = function(a, b)
{
  // always wrap with Long to make sure we retain precision
  if (!(a instanceof Long)) a = Long.fromNumber(a);
  if (!(b instanceof Long)) b = Long.fromNumber(b);
  return Long.sub(a, b);
}

fan.sys.Int.mult = function(a, b)
{
return a.valueOf() * b.valueOf();
/*
TODO - FIXIT
  // always wrap with Long to make sure we retain precision
  if (!(a instanceof Long)) a = Long.fromNumber(a);
  if (!(b instanceof Long)) b = Long.fromNumber(b);
  return Long.mul(a, b);
*/
}

fan.sys.Int.div = function(a, b)
{
return Math.floor(a / b);
/*
TODO - FIXIT
  // always wrap with Long to make sure we retain precision
  if (!(a instanceof Long)) a = Long.fromNumber(a);
  if (!(b instanceof Long)) b = Long.fromNumber(b);
  return Long.div(a, b);
*/
}

fan.sys.Int.mod = function(a, b)
{
return a % b;
/*
TODO - FIXIT
  // always wrap with Long to make sure we retain precision
  if (!(a instanceof Long)) a = Long.fromNumber(a);
  if (!(b instanceof Long)) b = Long.fromNumber(b);
  return Long.mod(a, b);
*/
}

fan.sys.Int.pow = function(a, b)
{
if (b < 0) throw fan.sys.ArgErr.make("pow < 0");
return Math.pow(a, b);
// TODO - FIXIT
}

//////////////////////////////////////////////////////////////////////////
// Bitwise operators
//////////////////////////////////////////////////////////////////////////

// NOTE: these methods only operate on the lowest 32 bits of the integer

fan.sys.Int.not    = function(a)    { return ~a; }
fan.sys.Int.and    = function(a, b) { var x = a & b;  if (x<0) x += 0xffffffff+1; return x; }
fan.sys.Int.or     = function(a, b) { var x = a | b;  if (x<0) x += 0xffffffff+1; return x; }
fan.sys.Int.xor    = function(a, b) { var x = a ^ b;  if (x<0) x += 0xffffffff+1; return x; }
fan.sys.Int.shiftl = function(a, b) { var x = a << b; if (x<0) x += 0xffffffff+1; return x; }
fan.sys.Int.shiftr = function(a, b) { var x = a >> b; if (x<0) x += 0xffffffff+1; return x; }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

fan.sys.Int.toChar = function(self)
{
  if (self < 0 || self > 0xFFFF) throw new Err("Invalid unicode char: " + self);
  return String.fromCharCode(self);
}

fan.sys.Int.toHex = function(self, width)
{
  var x = (self instanceof Long) ? self : Long.fromNumber(self);
  var s = Long.fromNumber(self).toString(16);
  if (width != null && s.length < width)
  {
    if (fan.sys.Int.$zeros == null)
    {
      fan.sys.Int.$zeros = [""];
      for (var i=1; i<16; i++)
        fan.sys.Int.$zeros[i] = fan.sys.Int.$zeros[i-1] + "0";
    }
    s = fan.sys.Int.$zeros[width-s.length] + s;
  }
  return s;
}
fan.sys.Int.$zeros = null;

fan.sys.Int.toCode = function(self, base)
{
  if (base === undefined) base = 10;
  if (base == 10) return self.toString();
  if (base == 16) return "0x" + fan.sys.Int.toHex(self);
  throw fan.sys.ArgErr.make("Invalid base " + base);
}

//////////////////////////////////////////////////////////////////////////
// CharMap
//////////////////////////////////////////////////////////////////////////

fan.sys.Int.charMap = [];
fan.sys.Int.SPACE    = 0x01;
fan.sys.Int.UPPER    = 0x02;
fan.sys.Int.LOWER    = 0x04;
fan.sys.Int.DIGIT    = 0x08;
fan.sys.Int.HEX      = 0x10;
fan.sys.Int.ALPHA    = fan.sys.Int.UPPER | fan.sys.Int.LOWER;
fan.sys.Int.ALPHANUM = fan.sys.Int.UPPER | fan.sys.Int.LOWER | fan.sys.Int.DIGIT;

fan.sys.Int.charMap[32] |= fan.sys.Int.SPACE;
fan.sys.Int.charMap[10] |= fan.sys.Int.SPACE;
fan.sys.Int.charMap[13] |= fan.sys.Int.SPACE;
fan.sys.Int.charMap[9]  |= fan.sys.Int.SPACE;
fan.sys.Int.charMap[12] |= fan.sys.Int.SPACE;

// alpha characters
for (var i=97; i<=122; ++i) fan.sys.Int.charMap[i] |= fan.sys.Int.LOWER;
for (var i=65; i<=90;  ++i) fan.sys.Int.charMap[i] |= fan.sys.Int.UPPER;

// digit characters
for (var i=48; i<=57; ++i) fan.sys.Int.charMap[i] |= fan.sys.Int.DIGIT;

// hex characters
for (var i=48; i<=57;  ++i) fan.sys.Int.charMap[i] |= fan.sys.Int.HEX;
for (var i=97; i<=102; ++i) fan.sys.Int.charMap[i] |= fan.sys.Int.HEX;
for (var i=65; i<=70;  ++i) fan.sys.Int.charMap[i] |= fan.sys.Int.HEX;

