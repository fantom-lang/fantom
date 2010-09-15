//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 09  Andy Frank  Creation
//

/**
 * OutStream
 */
fan.sys.OutStream = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.OutStream.prototype.$ctor = function()
{
  this.out = null;
  this.m_charset=fan.sys.Charset.utf8();
  this.m_bigEndian = true;
}

fan.sys.OutStream.make$ = function(self, out) { self.out = out; }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.OutStream.prototype.$typeof = function() { return fan.sys.OutStream.$type; }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

fan.sys.OutStream.prototype.write = function(x)
{
  try
  {
    this.out.write(x);
    return this;
  }
  catch (err)
  {
    if (this.out == null)
      throw fan.sys.UnsupportedErr.make(this.$typeof().qname() + " wraps null OutStream");
    else
      throw err;
  }
}

fan.sys.OutStream.prototype.writeBuf = function(buf, n)
{
  if (n === undefined) n = buf.remaining();
  try
  {
    this.out.writeBuf(buf, n);
    return this;
  }
  catch (err)
  {
    if (this.out == null)
      throw fan.sys.UnsupportedErr.make(this.$typeof().qname() + " wraps null OutStream");
    else
      throw err;
  }
}

fan.sys.OutStream.prototype.endian = function()
{
  return this.m_bigEndian ? fan.sys.Endian.m_big : fan.sys.Endian.m_little;
}

fan.sys.OutStream.prototype.endian$ = function(endian)
{
  this.m_bigEndian = (endian == fan.sys.Endian.m_big);
}

fan.sys.OutStream.prototype.writeI2 = function(x)
{
  if (this.m_bigEndian)
    return this.write((x >>> 8) & 0xFF)
               .write((x >>> 0) & 0xFF);
  else
    return this.write((x >>> 0) & 0xFF)
               .write((x >>> 8) & 0xFF);
}

fan.sys.OutStream.prototype.writeI4 = function(x)
{
  if (this.m_bigEndian)
    return this.write((x >>> 24) & 0xFF)
               .write((x >>> 16) & 0xFF)
               .write((x >>> 8)  & 0xFF)
               .write((x >>> 0)  & 0xFF);
  else
    return this.write((x >>> 0)  & 0xFF)
               .write((x >>> 8)  & 0xFF)
               .write((x >>> 16) & 0xFF)
               .write((x >>> 24) & 0xFF);
}

fan.sys.OutStream.prototype.writeDecimal = function(x)
{
  return this.writeUtf(x.toString());
}

fan.sys.OutStream.prototype.writeBool = function(x)
{
  return this.write(x ? 1 : 0);
}

fan.sys.OutStream.prototype.writeUtf = function(s)
{
  var slen = s.length;
  var utflen = 0;
  var i = 0;

  // first we have to figure out the utf length
  for (i=0; i<slen; ++i)
  {
    var c = s.charCodeAt(i);
    if (c <= 0x007F)
      utflen +=1;
    else if (c > 0x07FF)
      utflen += 3;
    else
      utflen += 2;
  }

  // sanity check
  if (utflen > 65536) throw fan.sys.IOErr.make("String too big");

  // write length as 2 byte value
  this.write((utflen >>> 8) & 0xFF);
  this.write((utflen >>> 0) & 0xFF);

  // write characters
  for (i=0; i<slen; ++i)
  {
    var c = s.charCodeAt(i);
    if (c <= 0x007F)
    {
      this.write(c);
    }
    else if (c > 0x07FF)
    {
      this.write(0xE0 | ((c >> 12) & 0x0F));
      this.write(0x80 | ((c >>  6) & 0x3F));
      this.write(0x80 | ((c >>  0) & 0x3F));
    }
    else
    {
      this.write(0xC0 | ((c >>  6) & 0x1F));
      this.write(0x80 | ((c >>  0) & 0x3F));
    }
  }
  return this;
}

fan.sys.OutStream.prototype.charset = function() { return this.m_charset; }
fan.sys.OutStream.prototype.charset$ = function(charset) { this.m_charset = charset; }

fan.sys.OutStream.prototype.writeChar = function(c)
{
  if (this.out != null)
  {
    this.out.writeChar(c)
    return this;
  }
  else return this.m_charset.m_encoder.encodeOut(c, this);
}


fan.sys.OutStream.prototype.writeChars = function(s, off, len)
{
  if (off === undefined) off = 0;
  if (len === undefined) len = s.length-off;
  var end = off+len;
  for (var i=off; i<end; i++)
    this.writeChar(s.charCodeAt(i));
  return this;
}

fan.sys.OutStream.prototype.print = function(obj)
{
  var s = obj == null ? "null" : fan.sys.ObjUtil.toStr(obj);
  return this.writeChars(s, 0, s.length);
}

fan.sys.OutStream.prototype.printLine = function(obj)
{
  if (obj === undefined) obj = "";
  var s = obj == null ? "null" : fan.sys.ObjUtil.toStr(obj);
  this.writeChars(s, 0, s.length);
  return this.writeChars('\n', 0, 1);
}

fan.sys.OutStream.prototype.writeObj = function(obj, options)
{
  if (options === undefined) options = null;
  new fanx_ObjEncoder(this, options).writeObj(obj);
  return this;
}

fan.sys.OutStream.prototype.flush = function()
{
  if (this.out != null) this.out.flush();
  return this;
}

fan.sys.OutStream.prototype.writeProps = function(props, close)
{
  if (close === undefined) close = true;
  var origCharset = this.charset();
  this.charset$(fan.sys.Charset.utf8());
  try
  {
    var keys = props.keys().sort();
    var size = keys.size();
    for (var i=0; i<size; ++i)
    {
      var key = keys.get(i);
      var val = props.get(key);
      this.writePropStr(key);
      this.writeChar(61);
      this.writePropStr(val);
      this.writeChar(10);
    }
    return this;
  }
  finally
  {
    try { if (close) this.close(); } catch (err) { fan.sys.ObjUtil.echo(err); }
    this.charset$(origCharset);
  }
}

fan.sys.OutStream.prototype.writePropStr = function(s)
{
  var len = s.length;
  for (var i=0; i<len; ++i)
  {
    var ch = s.charCodeAt(i);
    var peek = i+1<len ? s.charCodeAt(i+1) : -1;

    // escape special chars
    switch (ch)
    {
      case 10: this.writeChar(92).writeChar(110); continue;
      case 13: this.writeChar(92).writeChar(114); continue;
      case 09: this.writeChar(92).writeChar(116); continue;
      case 92: this.writeChar(92).writeChar(92); continue;
    }

     // escape control chars, comments, and =
    if ((ch < 32) || (ch == 47 && (peek == 47 || peek == 42)) || (ch == 61))
    {
      var nib1 = fan.sys.Int.toDigit((ch >>> 4) & 0xf, 16);
      var nib2 = fan.sys.Int.toDigit((ch >>> 0) & 0xf, 16);

      this.writeChar(92).writeChar(117)
          .writeChar(48).writeChar(48)
          .writeChar(nib1).writeChar(nib2);
      continue;
    }

    // normal character
    this.writeChar(ch);
  }
}

fan.sys.OutStream.prototype.writeXml = function(s, mask)
{
  if (mask === undefined) mask = 0;

  var escNewlines  = (mask & fan.sys.OutStream.m_xmlEscNewlines) != 0;
  var escQuotes    = (mask & fan.sys.OutStream.m_xmlEscQuotes) != 0;
  var escUnicode   = (mask & fan.sys.OutStream.m_xmlEscUnicode) != 0;

  for (var i=0; i<s.length; ++i)
  {
    var ch = s.charCodeAt(i);
    switch (ch)
    {
      // table switch on control chars
      case  0: case  1: case  2: case  3: case  4: case  5: case  6:
      case  7: case  8: case 11: case 12:
      case 14: case 15: case 16: case 17: case 18: case 19: case 20:
      case 21: case 22: case 23: case 24: case 25: case 26: case 27:
      case 28: case 29: case 30: case 31:
        this.writeXmlEsc(ch);
        break;

      // newlines
      case 10: case 13:
        if (!escNewlines)
          this.writeChar(ch);
        else
          this.writeXmlEsc(ch);
        break;

      // space
      case 32:
        this.writeChar(32);
        break;

      // table switch on common ASCII chars
      case 33: case 35: case 36: case 37: case 40: case 41: case 42:
      case 43: case 44: case 45: case 46: case 47: case 48: case 49:
      case 50: case 51: case 52: case 53: case 54: case 55: case 56:
      case 57: case 58: case 59: case 61: case 63: case 64: case 65:
      case 66: case 67: case 68: case 69: case 70: case 71: case 72:
      case 73: case 74: case 75: case 76: case 77: case 78: case 79:
      case 80: case 81: case 82: case 83: case 84: case 85: case 86:
      case 87: case 88: case 89: case 90: case 91: case 92: case 93:
      case 94: case 95: case 96: case 97: case 98: case 99: case 100:
      case 101: case 102: case 103: case 104: case 105: case 106: case 107:
      case 108: case 109: case 110: case 111: case 112: case 113: case 114:
      case 115: case 116: case 117: case 118: case 119: case 120: case 121:
      case 122: case 123: case 124: case 125: case 126:
        this.writeChar(ch);
        break;

      // XML control characters
      case 60:
        this.writeChar(38);
        this.writeChar(108);
        this.writeChar(116);
        this.writeChar(59);
        break;
      case 62:
        if (i > 0 && s.charCodeAt(i-1) != 93)
          this.writeChar(62);
        else
        {
          this.writeChar(38);
          this.writeChar(103);
          this.writeChar(116);
          this.writeChar(59);
        }
        break;
      case 38:
        this.writeChar(38);
        this.writeChar(97);
        this.writeChar(109);
        this.writeChar(112);
        this.writeChar(59);
        break;
      case 34:
        if (!escQuotes)
          this.writeChar(34);
        else
        {
          this.writeChar(38);
          this.writeChar(113);
          this.writeChar(117);
          this.writeChar(111);
          this.writeChar(116);
          this.writeChar(59);
        }
        break;
      case 39:
        if (!escQuotes)
          this.writeChar(39);
        else
        {
          this.writeChar(38);
          this.writeChar(97);
          this.writeChar(112);
          this.writeChar(111);
          this.writeChar(115);
          this.writeChar(59);
        }
        break;

      // default
      default:
        if (ch <= 0xf7 || !escUnicode)
          this.writeChar(ch);
        else
          this.writeXmlEsc(ch);
    }
  }
  return this;
}

fan.sys.OutStream.prototype.writeXmlEsc = function(ch)
{
  var enc =  this.m_charset.m_encoder;
  var hex = "0123456789abcdef";

  this.writeChar(38);
  this.writeChar(35);
  this.writeChar(120);
  if (ch > 0xff)
  {
    this.writeChar(hex.charCodeAt((ch >>> 12) & 0xf));
    this.writeChar(hex.charCodeAt((ch >>> 8)  & 0xf));
  }
  this.writeChar(hex.charCodeAt((ch >>> 4) & 0xf));
  this.writeChar(hex.charCodeAt((ch >>> 0) & 0xf));
  this.writeChar(59);
}

fan.sys.OutStream.prototype.sync = function()
{
  if (this.out != null) this.out.sync();
  return this;
}

fan.sys.OutStream.prototype.close = function()
{
  if (this.out != null) return this.out.close();
  return true;
}

fan.sys.OutStream.prototype.close = function()
{
  if (this.out != null) return this.out.close();
  return true;
}

/*

//////////////////////////////////////////////////////////////////////////
// Java Utils
//////////////////////////////////////////////////////////////////////////

public OutStream indent(int num)
{
  for (int i=0; i<num; ++i)
    charsetEncoder.encode(' ', this);
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

OutStream out;
Charset charset = Charset.utf8();
Charset.Encoder charsetEncoder = charset.newEncoder();
*/

