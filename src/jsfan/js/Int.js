//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Dec 08  Andy Frank  Creation
//

/**
 * Int
 */
var sys_Int = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function() {},

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  type: function()
  {
    return sys_Type.find("sys::Int");
  },

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Int.fromStr = function(s, radix, checked)
{
  var num = parseInt(s, radix);
  if (isNaN(num))
  {
    if (checked != null && !checked) return null;
    throw ParseErr.make("Int", s).val;
  }
  return num;
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

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

sys_Int.maxValue = { val: 9223372036854775807 };
sys_Int.minValue = { val: -9223372036854775808 };