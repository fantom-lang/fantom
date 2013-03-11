//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 08  Brian Frank  Creation
//   08 Feb 13  Ivo Smid     Conversion of Java class to JS
//

/**
 * Uuid
 */
fan.sys.Uuid = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Uuid.prototype.$ctor = function ()
{
  this.m_value = "";
}

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.Uuid.make = function()
{
  throw fan.sys.UnsupportedErr.make("Uuid.make not implemented in Js env");
}

fan.sys.Uuid.makeStr = function(a, b, c, d, e)
{
  var self = new fan.sys.Uuid();
  self.m_value = fan.sys.Int.toHex(a, 8) + "-" +
    fan.sys.Int.toHex(b, 4) + "-" +
    fan.sys.Int.toHex(c, 4) + "-" +
    fan.sys.Int.toHex(d, 4) + "-" +
    fan.sys.Int.toHex(e, 12);
  return self;
}

fan.sys.Uuid.makeBits = function(hi, lo)
{
  throw fan.sys.UnsupportedErr.make("Uuid.makeBits not implemented in Js env");
}

fan.sys.Uuid.fromStr = function (s, checked)
{
  if (checked === undefined) checked = true;

  try
  {
    var len = s.length;

    // sanity check
    if (len != 36 ||
      s.charAt(8) != '-' || s.charAt(13) != '-' || s.charAt(18) != '-' || s.charAt(23) != '-')
    {
      throw new Error();
    }

    // parse hex components
    var a = fan.sys.Int.fromStr(s.substring(0, 8), 16);
    var b = fan.sys.Int.fromStr(s.substring(9, 13), 16);
    var c = fan.sys.Int.fromStr(s.substring(14, 18), 16);
    var d = fan.sys.Int.fromStr(s.substring(19, 23), 16);
    var e = fan.sys.Int.fromStr(s.substring(24), 16);

    return fan.sys.Uuid.makeStr(a, b, c, d, e);
  }
  catch (err)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.make("Uuid", s);
  }

}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Uuid.prototype.$typeof = function () {
  return fan.sys.Uuid.$type;
}

fan.sys.Uuid.prototype.bitsHi = function()
{
  throw fan.sys.UnsupportedErr.make("Uuid.bitsHi not implemented in Js env");
}

fan.sys.Uuid.prototype.bitsLo = function()
{
  throw fan.sys.UnsupportedErr.make("Uuid.bitsLo not implemented in Js env");
}

fan.sys.Uuid.prototype.equals = function(that)
{
  if (that instanceof fan.sys.Uuid)
    return this.m_value == that.m_value;
  else
    return false;
}

fan.sys.Uuid.prototype.hash = function()
{
  return fan.sys.Str.hash(this.m_value);
}
fan.sys.Uuid.prototype.compare = function(that)
{
  return fan.sys.ObjUtil.compare(this.m_value, that.m_value)
}

fan.sys.Uuid.prototype.toStr = function()
{
  return this.m_value;
}
