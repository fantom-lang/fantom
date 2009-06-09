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
var sys_Int = sys_Obj.$extend(sys_Num);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Int.prototype.$ctor = function() {}
sys_Int.prototype.type = function() { return sys_Type.find("sys::Int"); }

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

sys_Int.make = function(val)
{
  var x = new Number(val);
  x.$fanType = sys_Type.find("sys::Int");
  return x;
}

sys_Int.fromStr = function(s, radix, checked)
{
  if (radix == undefined) radix = 10;
  if (checked == undefined) checked = true;
  try
  {
    if (s == "") throw new sys_Err();
    var num = 0;
    var pos = true;

    if (s.charCodeAt(0) == 45)
    {
      s = s.substring(1);
      pos = false;
    }

    // radix 10
    if (radix == 10)
    {
      var len = s.length-1;
      for (var i=len; i>=0; i--)
      {
        ch = s.charCodeAt(i);
        if (ch < 48 || ch > 57) throw new sys_Err();
        val = ch-48;
        if (len-i > 0) val *= Math.pow(10, (len-i));
        num += val;
      }
    }
    // radix 16
    else if (radix == 16)
    {
      var len = s.length-1;
      for (var i=0; i<s.length; i++)
      {
        ch = s.charCodeAt(i);
        if (ch >= 48 && ch <= 57) { val = ch-48; }
        else if (ch >= 65 && ch <= 70) { val = ch-65+10; }
        else if (ch >= 97 && ch <= 102) { val = ch-97+10; }
        else throw new sys_Err();
        num = sys_Int.or(num, (val << ((len-i)*4)));
      }
    }
    else throw new sys_Err();
    return pos ? num : -num;
  }
  catch (err) {}
  if (checked) throw new sys_ParseErr("Int", s);
  return null;
}
sys_Int.toStr = function(self)
{
  return ""+self;
}

sys_Int.equals = function(self, obj)
{
  if (obj != null && self.$fanType == obj.$fanType)
    return self.valueOf() == obj.valueOf();
  else
    return false;
}

sys_Int.abs = function(self) { return self < 0 ? -self : self; }
sys_Int.min = function(self, val) { return self < val ? self : val; }
sys_Int.max = function(self, val) { return self > val ? self : val; }

sys_Int.isEven  = function(self) { return self % 2 == 0; }
sys_Int.isOdd   = function(self) { return self % 2 != 0; }
sys_Int.isSpace = function(self) { return self == 32 || self == 9 || self == 10 || self == 13; }

sys_Int.isDigit = function(self, radix)
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

sys_Int.toDigit = function(self, radix)
{
  if (radix == null || radix == 10) return 0 <= self && self <= 9 ? 48+self : null;
  if (self < 0 || self >= radix) return null;
  if (self < 10) return 48+self;
  return self-10+97;
}

sys_Int.fromDigit = function(self, radix)
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

sys_Int.toChar = function(self)
{
  if (self < 0 || self > 0xFFFF) throw new Err("Invalid unicode char: " + self);
  return String.fromCharCode(self);
}

sys_Int.toHex = function(self, width)
{
  var s = self.toString(16);
  if (width != null && s.length < width)
  {
    if (sys_Int.$zeros == null)
    {
      sys_Int.$zeros = [""];
      for (var i=1; i<16; i++)
        sys_Int.$zeros[i] = sys_Int.$zeros[i-1] + "0";
    }
    s = sys_Int.$zeros[width-s.length] + s;
  }
  return s;
}
sys_Int.$zeros = null;

sys_Int.isUpper    = function(self) { return self >= 65 && self <= 90; }
sys_Int.isLower    = function(self) { return self >= 97 && self <= 122; }
sys_Int.upper      = function(self) { return sys_Int.isLower(self) ? self-32 : self; }
sys_Int.lower      = function(self) { return sys_Int.isUpper(self) ? self+32 : self; }
sys_Int.isAlpha    = function(self) { return sys_Int.isUpper(self) || sys_Int.isLower(self); }
sys_Int.isAlphaNum = function(self) { return sys_Int.isAlpha(self) || sys_Int.isDigit(self); }
sys_Int.equalsIgnoreCase = function(self, ch) { return (self|0x20) == (ch|0x20); }

// Iterators
sys_Int.times = function(self, func)
{
  for (var i=0; i<self; i++)
    func(i);
}

// Arithmetic
sys_Int.div = function(a, b) { return Math.floor(a/b); }

// Bitwise
// TODO - these impls only work upto 32 bits!!!
sys_Int.and    = function(a, b) { var x = a & b;  if (x<0) x += 0xffffffff+1; return sys_Int.make(x); }
sys_Int.or     = function(a, b) { var x = a | b;  if (x<0) x += 0xffffffff+1; return sys_Int.make(x); }
sys_Int.lshift = function(a, b) { var x = a << b; if (x<0) x += 0xffffffff+1; return sys_Int.make(x); }
sys_Int.rshift = function(a, b) { var x = a >> b; if (x<0) x += 0xffffffff+1; return sys_Int.make(x); }

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

sys_Int.maxVal = 9223372036854775807;
sys_Int.minVal = -9223372036854775808;
sys_Int.defVal = 0;
sys_Int.Chunk  = 4096;