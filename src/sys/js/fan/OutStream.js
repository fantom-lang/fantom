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

fan.sys.OutStream.prototype.$ctor = function() { this.out = null; }
fan.sys.OutStream.make$ = function(self, out) { self.out = out; }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.OutStream.prototype.$typeof = function() { return fan.sys.OutStream.$type; }

//////////////////////////////////////////////////////////////////////////
// Java OutputStream
//////////////////////////////////////////////////////////////////////////

/**
 * Write a byte using a Java primitive int.  Most
 * writes route to this method for efficient mapping to
 * a java.io.OutputStream.  If we aren't overriding this
 * method, then route back to write(Int) for the
 * subclass to handle.
 */
fan.sys.OutStream.prototype.w = function(b) // int
{
  return this.write(b);
}

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

fan.sys.OutStream.prototype.write = function(x) // long
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
  if (n === undefined) b = buf.remaining();
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

/*
fan.sys.OutStream.prototype.writeI2(long x)
{
  int v = (int)x;
  return this.w((v >>> 8) & 0xFF)
             .w((v >>> 0) & 0xFF);
}

fan.sys.OutStream.prototype.writeI4(long x)
{
  int v = (int)x;
  return this.w((v >>> 24) & 0xFF)
             .w((v >>> 16) & 0xFF)
             .w((v >>> 8)  & 0xFF)
             .w((v >>> 0)  & 0xFF);
}

fan.sys.OutStream.prototype.writeI8(long v)
{
  return this.w((int)(v >>> 56) & 0xFF)
             .w((int)(v >>> 48) & 0xFF)
             .w((int)(v >>> 40) & 0xFF)
             .w((int)(v >>> 32) & 0xFF)
             .w((int)(v >>> 24) & 0xFF)
             .w((int)(v >>> 16) & 0xFF)
             .w((int)(v >>> 8)  & 0xFF)
             .w((int)(v >>> 0)  & 0xFF);
}

fan.sys.OutStream.prototype.writeF4(double x)
{
  return writeI4(Float.floatToIntBits((float)x));
}

fan.sys.OutStream.prototype.writeF8(double x)
{
  return writeI8(Double.doubleToLongBits(x));
}

fan.sys.OutStream.prototype.writeDecimal(BigDecimal x)
{
  return writeUtf(x.toString());
}

fan.sys.OutStream.prototype.writeBool(boolean x)
{
  return w(x ? 1 : 0);
}

fan.sys.OutStream.prototype.writeUtf(String s)
{
  int slen = s.length();
  int utflen = 0;

  // first we have to figure out the utf length
  for (int i=0; i<slen; ++i)
  {
    int c = s.charAt(i);
    if (c <= 0x007F)
      utflen +=1;
    else if (c > 0x07FF)
      utflen += 3;
    else
      utflen += 2;
  }

  // sanity check
  if (utflen > 65536) throw IOErr.make("String too big").val;

  // write length as 2 byte value
  w((utflen >>> 8) & 0xFF);
  w((utflen >>> 0) & 0xFF);

  // write characters
  for (int i=0; i<slen; ++i)
  {
    int c = s.charAt(i);
    if (c <= 0x007F)
    {
      w(c);
    }
    else if (c > 0x07FF)
    {
      w(0xE0 | ((c >> 12) & 0x0F));
      w(0x80 | ((c >>  6) & 0x3F));
      w(0x80 | ((c >>  0) & 0x3F));
    }
    else
    {
      w(0xC0 | ((c >>  6) & 0x1F));
      w(0x80 | ((c >>  0) & 0x3F));
    }
  }
  return this;
}

fan.sys.OutStream.prototype.charset()
{
  return charset;
}

fan.sys.OutStream.prototype.charset(Charset charset)
{
  this.charsetEncoder = charset.newEncoder();
  this.charset = charset;
}
*/

fan.sys.OutStream.prototype.writeChar = function(c)
{
  return this.w(c);
}

/*
fan.sys.OutStream.prototype.writeChar(char c)
{
  charsetEncoder.encode(c, this);
  return this;
}
*/

fan.sys.OutStream.prototype.writeChars = function(s, off, len)
{
  if (off === undefined) off = 0;
  if (len === undefined) len = s.length-off;
  var end = off+len;
  for (var i=off; i<end; i++)
    this.w(s.charCodeAt(i));
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
  return this.writeChar('\n');
}

fan.sys.OutStream.prototype.writeObj = function(obj, options)
{
  if (options === undefined) options = null;
  new fanx_ObjEncoder(this, options).writeObj(obj);
  return this;
}

/*
public OutStream writeProps(Map props) { return writeProps(props, true); }
public OutStream writeProps(Map props, boolean close)
{
  Charset origCharset = charset();
  charset(Charset.utf8());
  try
  {
    List keys = props.keys().sort();
    int size = keys.sz();
    for (int i=0; i<size; ++i)
    {
      String key = (String)keys.get(i);
      String val = (String)props.get(key);
      writePropStr(key);
      writeChar('=');
      writePropStr(val);
      writeChar('\n');
    }
    return this;
  }
  finally
  {
    try { if (close) close(); } catch (Exception e) { e.printStackTrace(); }
    charset(origCharset);
  }
}

private void writePropStr(String s)
{
  int len = s.length();
  for (int i=0; i<len; ++i)
  {
    int ch = s.charAt(i);
    int peek = i+1<len ? s.charAt(i+1) : -1;

    // escape special chars
    switch (ch)
    {
      case '\n': writeChar('\\').writeChar('n'); continue;
      case '\r': writeChar('\\').writeChar('r'); continue;
      case '\t': writeChar('\\').writeChar('t'); continue;
      case '\\': writeChar('\\').writeChar('\\'); continue;
    }

    // escape control chars, comments, and =
    if ((ch < ' ') || (ch == '/' && (peek == '/' || peek == '*')) || (ch == '='))
    {
      long nib1 = FanInt.toDigit((ch>>4)&0xf, 16);
      long nib2 = FanInt.toDigit((ch>>0)&0xf, 16);

      this.writeChar('\\').writeChar('u')
          .writeChar('0').writeChar('0')
          .writeChar(nib1).writeChar(nib2);
      continue;
    }

    // normal character
    writeChar(ch);
  }
}

public OutStream writeXml(String s) { return writeXml(s, 0); }
public OutStream writeXml(String s, long mask)
{
  boolean escNewlines  = (mask & xmlEscNewlines) != 0;
  boolean escQuotes    = (mask & xmlEscQuotes) != 0;
  boolean escUnicode   = (mask & xmlEscUnicode) != 0;
  Charset.Encoder enc  = charsetEncoder;
  int len = s.length();
  String hex = "0123456789abcdef";

  for (int i=0; i<len; ++i)
  {
    int ch = s.charAt(i);
    switch (ch)
    {
      // table switch on control chars
      case  0: case  1: case  2: case  3: case  4: case  5: case  6:
*/
//      case  7: case  8: /*case  9: case 10:*/ case 11: case 12: /*case 13:*/
/*
      case 14: case 15: case 16: case 17: case 18: case 19: case 20:
      case 21: case 22: case 23: case 24: case 25: case 26: case 27:
      case 28: case 29: case 30: case 31:
        writeXmlEsc(ch);
        break;

      // newlines
      case '\n': case '\r':
        if (!escNewlines)
          enc.encode((char)ch, this);
        else
          writeXmlEsc(ch);
        break;

      // space
      case ' ':
        enc.encode(' ', this);
        break;

      // table switch on common ASCII chars
      case '!': case '#': case '$': case '%': case '(': case ')': case '*':
      case '+': case ',': case '-': case '.': case '/': case '0': case '1':
      case '2': case '3': case '4': case '5': case '6': case '7': case '8':
      case '9': case ':': case ';': case '=': case '?': case '@': case 'A':
      case 'B': case 'C': case 'D': case 'E': case 'F': case 'G': case 'H':
      case 'I': case 'J': case 'K': case 'L': case 'M': case 'N': case 'O':
      case 'P': case 'Q': case 'R': case 'S': case 'T': case 'U': case 'V':
      case 'W': case 'X': case 'Y': case 'Z': case '[': case '\\': case ']':
      case '^': case '_': case '`': case 'a': case 'b': case 'c': case 'd':
      case 'e': case 'f': case 'g': case 'h': case 'i': case 'j': case 'k':
      case 'l': case 'm': case 'n': case 'o': case 'p': case 'q': case 'r':
      case 's': case 't': case 'u': case 'v': case 'w': case 'x': case 'y':
      case 'z': case '{': case '|': case '}': case '~':
        enc.encode((char)ch, this);
        break;

      // XML control characters
      case '<':
        enc.encode('&', this);
        enc.encode('l', this);
        enc.encode('t', this);
        enc.encode(';', this);
        break;
      case '>':
        if (i > 0 && s.charAt(i-1) != ']') enc.encode('>', this);
        else
        {
          enc.encode('&', this);
          enc.encode('g', this);
          enc.encode('t', this);
          enc.encode(';', this);
        }
        break;
      case '&':
        enc.encode('&', this);
        enc.encode('a', this);
        enc.encode('m', this);
        enc.encode('p', this);
        enc.encode(';', this);
        break;
      case '"':
        if (!escQuotes) enc.encode((char)ch, this);
        else
        {
          enc.encode('&', this);
          enc.encode('q', this);
          enc.encode('u', this);
          enc.encode('o', this);
          enc.encode('t', this);
          enc.encode(';', this);
        }
        break;
      case '\'':
        if (!escQuotes) enc.encode((char)ch, this);
        else
        {
          enc.encode('&', this);
          enc.encode('a', this);
          enc.encode('p', this);
          enc.encode('o', this);
          enc.encode('s', this);
          enc.encode(';', this);
        }
        break;

      // default
      default:
        if (ch <= 0xf7 || !escUnicode)
          enc.encode((char)ch, this);
        else
          writeXmlEsc(ch);
    }
  }
  return this;
}

private void writeXmlEsc(int ch)
{
  Charset.Encoder enc = charsetEncoder;
  String hex = "0123456789abcdef";

  enc.encode('&', this);
  enc.encode('#', this);
  enc.encode('x', this);
  if (ch > 0xff)
  {
    enc.encode(hex.charAt((ch >> 12) & 0xf), this);
    enc.encode(hex.charAt((ch >> 8)  & 0xf), this);
  }
  enc.encode(hex.charAt((ch >> 4) & 0xf), this);
  enc.encode(hex.charAt((ch >> 0) & 0xf), this);
  enc.encode(';', this);
}

public static final long xmlEscNewlines = 0x01;
public static final long xmlEscQuotes   = 0x02;
public static final long xmlEscUnicode  = 0x04;

public OutStream flush()
{
  if (out != null) out.flush();
  return this;
}

public OutStream sync()
{
  if (out != null) out.sync();
  return this;
}
*/

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

