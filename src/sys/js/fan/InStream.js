//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 May 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * InStream
 */
fan.sys.InStream = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.InStream.prototype.$ctor = function()
{
  this.$in = null;
  this.m_charset = fan.sys.Charset.utf8();
  this.m_bigEndian = true;
}
fan.sys.InStream.make$ = function(self, $in) { self.$in = $in; }

//////////////////////////////////////////////////////////////////////////
// InputStream
//////////////////////////////////////////////////////////////////////////

fan.sys.InStream.prototype.rChar = function()
{
  if (this.$in != null)
    return this.$in.rChar();
  else
    return this.m_charset.m_encoder.decode(this);
}

fan.sys.InStream.prototype.read = function()
{
  try
  {
    return this.$in.read();
  }
  catch (err)
  {
    if (this.$in == null)
      throw fan.sys.UnsupportedErr.make(this.$typeof().qname() + " wraps null InStream");
    else
      throw fan.sys.Err.make(err);
  }
}

fan.sys.InStream.prototype.readBuf = function(buf, n)
{
  try
  {
    return this.$in.readBuf(buf, n);
  }
  catch (err)
  {
    if (this.$in == null)
      throw fan.sys.UnsupportedErr.make(this.$typeof().qname() + " wraps null InStream");
    else
      throw fan.sys.Err.make(err);
  }
}

fan.sys.InStream.prototype.unread = function(n)
{
  try
  {
    return this.$in.unread(n);
  }
  catch (err)
  {
    if (this.$in == null)
      throw fan.sys.UnsupportedErr.make(this.$typeof().qname() + " wraps null InStream");
    else
      throw fan.sys.Err.make(err);
  }
}

fan.sys.InStream.prototype.skip = function(n)
{
  if (this.$in != null) return this.$in.skip(n);

  for (var i=0; i<n; ++i)
    if (this.read() == 0) return i;
  return n;
}

fan.sys.InStream.prototype.readAllBuf = function()
{
  try
  {
    var size = fan.sys.Int.Chunk;
    var buf = fan.sys.Buf.make(size);
    while (this.readBuf(buf, size) != null);
    buf.flip();
    return buf;
  }
  finally
  {
    try { this.close(); } catch (e) { fan.sys.ObjUtil.echo("InStream.readAllBuf: " + e); }
  }
}

fan.sys.InStream.prototype.readBufFully = function(buf, n)
{
  if (buf == null) buf = fan.sys.Buf.make(n);

  var total = n;
  var got = 0;
  while (got < total)
  {
    var r = this.readBuf(buf, total-got);
    if (r == null || r == 0) throw fan.sys.IOErr.make("Unexpected end of stream");
    got += r;
  }

  buf.flip();
  return buf;
}

fan.sys.InStream.prototype.endian = function()
{
  return this.m_bigEndian ? fan.sys.Endian.m_big : fan.sys.Endian.m_little;
}

fan.sys.InStream.prototype.endian$ = function(endian)
{
  this.m_bigEndian = (endian == fan.sys.Endian.m_big);
}

fan.sys.InStream.prototype.peek = function()
{
  var x = this.read();
  if (x != null) this.unread(x);
  return x;
}

fan.sys.InStream.prototype.readU1 = function()
{
  var c = this.read();
  if (c == null) throw fan.sys.IOErr.make("Unexpected end of stream");
  return c;
}

fan.sys.InStream.prototype.readS1 = function()
{
  var c = this.read();
  if (c == null) throw fan.sys.IOErr.make("Unexpected end of stream");
  return c <= 0x7F ? c : (0xFFFFFF00 | c);
}

fan.sys.InStream.prototype.readU2 = function()
{
  var c1 = this.read();
  var c2 = this.read();
  if (c1 == null || c2 == null) throw fan.sys.IOErr.make("Unexpected end of stream");
  if (this.m_bigEndian)
    return c1 << 8 | c2;
  else
    return c2 << 8 | c1;
}

fan.sys.InStream.prototype.readS2 = function()
{
  var c1 = this.read();
  var c2 = this.read();
  if (c1 == null || c2 == null) throw fan.sys.IOErr.make("Unexpected end of stream");
  var c;
  if (this.m_bigEndian)
    c = c1 << 8 | c2;
  else
    c = c2 << 8 | c1;
  return c <= 0x7FFF ? c : (0xFFFF0000 | c);
}

fan.sys.InStream.prototype.readU4 = function()
{
  var c1 = this.read();
  var c2 = this.read();
  var c3 = this.read();
  var c4 = this.read();
  if (c1 == null || c2 == null || c3 == null || c4 == null) throw fan.sys.IOErr.make("Unexpected end of stream");
  var c;
  if (this.m_bigEndian)
    c = (c1 << 24) + (c2 << 16) + (c3 << 8) + c4;
  else
    c = (c4 << 24) + (c3 << 16) + (c2 << 8) + c1;
  if (c >= 0)
    return c;
  else
    return (c & 0x7FFFFFFF) + Math.pow(2, 31);
}

fan.sys.InStream.prototype.readS4 = function()
{
  var c1 = this.read();
  var c2 = this.read();
  var c3 = this.read();
  var c4 = this.read();
  if (c1 == null || c2 == null || c3 == null || c4 == null) throw fan.sys.IOErr.make("Unexpected end of stream");
  if (this.m_bigEndian)
    return (c1 << 24) + (c2 << 16) + (c3 << 8) + c4;
  else
    return (c4 << 24) + (c3 << 16) + (c2 << 8) + c1;
}

//fan.sys.InStream.prototype.readS8 = function() {}
//fan.sys.InStream.prototype.readF4 = function() {}
//fan.sys.InStream.prototype.readF8 = function() {}

fan.sys.InStream.prototype.readDecimal = function()
{
  var inp = this.readUtf()
  return fan.sys.Decimal.fromStr(inp);
}

fan.sys.InStream.prototype.readBool = function()
{
  var c = this.read();
  if (c == null) throw IOErr.make("Unexpected end of stream");
  return c != 0;
}

fan.sys.InStream.prototype.readUtf = function()
{
  // read two-byte length
  var len1 = this.read();
  var len2 = this.read();
  if (len1 == null || len2 == null) throw fan.sys.IOErr.make("Unexpected end of stream");
  var utflen = len1 << 8 | len2;

  var buf = ""; // char buffer we read into
  var bnum = 0; // byte count

  // read the chars
  var c1, c2, c3;
  while (bnum < utflen)
  {
    var c1 = this.read(); bnum++;
    if (c1 == null) throw IOErr.make("Unexpected end of stream");
    switch (c1 >> 4) {
      case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
        /* 0xxxxxxx*/
        buf += String.fromCharCode(c1);
        break;
      case 12: case 13:
        /* 110x xxxx   10xx xxxx*/
        if (bnum >= utflen) throw fan.sys.IOErr.make("UTF encoding error");
        c2 = this.read(); bnum++;
        if (c2 == null) throw fan.sys.IOErr.make("Unexpected end of stream");
        if ((c2 & 0xC0) != 0x80) throw fan.sys.IOErr.make("UTF encoding error");
        buf += String.fromCharCode(((c1 & 0x1F) << 6) | (c2 & 0x3F));
        break;
      case 14:
        /* 1110 xxxx  10xx xxxx  10xx xxxx */
        if (bnum+1 >= utflen) throw fan.sys.IOErr.make("UTF encoding error");
        c2 = this.read(); bnum++;
        c3 = this.read(); bnum++;
        if (c2 == null || c3 == null) throw fan.sys.IOErr.make("Unexpected end of stream");
        if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80))  throw fan.sys.IOErr.make("UTF encoding error");
        buf += String.fromCharCode(((c1 & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
        break;
      default:
        /* 10xx xxxx,  1111 xxxx */
        throw fan.sys.IOErr.make("UTF encoding error");
    }
  }
  return buf;
}

fan.sys.InStream.prototype.charset = function() { return this.m_charset; }
fan.sys.InStream.prototype.charset$ = function(charset) { this.m_charset = charset; }


fan.sys.InStream.prototype.readChar = function()
{
  var ch = this.rChar();
  return ch < 0 ? null : ch;
}

fan.sys.InStream.prototype.unreadChar = function(c)
{
  var ch = this.m_charset.m_encoder.encodeIn(c, this);
  return ch < 0 ? null : ch;
}

fan.sys.InStream.prototype.peekChar = function()
{
  var x = this.readChar();
  if (x != null) this.unreadChar(x);
  return x;
}

fan.sys.InStream.prototype.readChars = function(n)
{
  if (n === undefined || n < 0) throw fan.sys.ArgErr.make("readChars n < 0: " + n);
  if (n == 0) return "";
  var buf = "";
  for (i=n; i>0; --i)
  {
    var ch = this.rChar();
    if (ch < 0) throw fan.sys.IOErr.make("Unexpected end of stream");
    buf += String.fromCharCode(ch);
  }
  return buf;
}

fan.sys.InStream.prototype.readLine = function(max)
{
  if (max === undefined) max = fan.sys.Int.Chunk;

  // max limit
  var maxChars = (max != null) ? max.valueOf() : fan.sys.Int.m_maxVal;
  if (maxChars <= 0) return "";

  // read first char, if at end of file bail
  var c = this.rChar();
  if (c < 0) return null;

  // loop reading char until we hit newline
  // combo or end of stream
  var buf = "";
  while (true)
  {
    // check for \n, \r\n, or \r
    if (c == 10) break;
    if (c == 13)
    {
      c = this.rChar();
      if (c >= 0 && c != 10) this.unreadChar(c);
      break;
    }

    // append to working buffer
    buf += String.fromCharCode(c);
    if (buf.length >= maxChars) break;

    // read next char
    c = this.rChar();
    if (c < 0) break;
  }
  return buf;
}

fan.sys.InStream.prototype.readStrToken = function(max, f)
{
  if (max === undefined) max = fan.sys.Int.Chunk;

  // max limit
  var maxChars = (max != null) ? max.valueOf() : fan.sys.Int.m_maxVal;
  if (maxChars <= 0) return "";

  // read first char, if at end of file bail
  var c = this.rChar();
  if (c < 0) return null;

  // loop reading chars until our closure returns false
  buf = "";
  while (true)
  {
    // check for \n, \r\n, or \r
    var terminate;
    if (f == null)
      terminate = fan.sys.Int.isSpace(c);
    else
      terminate = f.call(c);
    if (terminate)
    {
      this.unreadChar(c);
      break;
    }

    // append to working buffer
    buf += String.fromCharCode(c);
    if (buf.length >= maxChars) break;

    // read next char
    c = this.rChar();
    if (c < 0) break;
  }
  return buf;
}

fan.sys.InStream.prototype.readAllLines = function()
{
  try
  {
    var list = fan.sys.List.make(fan.sys.Str.$type, []);
    var line = "";
    while ((line = this.readLine()) != null)
      list.push(line);
    return list;
  }
  catch (err) { fan.sys.Err.make(err).trace(); }
  finally
  {
    try { this.close(); } catch (err) { fan.sys.Err.make(err).trace(); }
  }
}

fan.sys.InStream.prototype.eachLine = function(f)
{
  try
  {
    var line;
    while ((line = this.readLine()) != null)
      f.call(line);
  }
  finally
  {
    try { this.close(); } catch (err) { fan.sys.Err.make(err).trace(); }
  }
}

fan.sys.InStream.prototype.readAllStr = function(normalizeNewlines)
{
  if (normalizeNewlines === undefined) normalizeNewlines = true;
  try
  {
    var s = "";
    var normalize = normalizeNewlines;

    // read characters
    var last = -1;
    while (true)
    {
      var c = this.rChar();
      if (c < 0) break;

      // normalize newlines and add to buffer
      if (normalize)
      {
        if (c == 13) s += String.fromCharCode(10);
        else if (last == 13 && c == 10) {}
        else s += String.fromCharCode(c);
        last = c;
      }
      else
      {
        s += String.fromCharCode(c);
      }
    }
    return s;
  }
  finally
  {
    try { this.close(); } catch (err) { fan.sys.Err.make(err).trace(); }
  }
}

fan.sys.InStream.prototype.readObj = function(options)
{
  if (options === undefined) options = null;
  return new fanx_ObjDecoder(this, options).readObj();
}

fan.sys.InStream.prototype.readProps = function()
{
  var origCharset = this.charset();
  this.charset$(fan.sys.Charset.utf8());
  try
  {
    var props = fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Str.$type);

    var name = "";
    var v = null;
    var inBlockComment = 0;
    var inEndOfLineComment = false;
    var c =  32, last = 32;
    var lineNum = 1;

    while (true)
    {
      last = c;
      c = this.rChar();
      if (c < 0) break;

      // end of line
      if (c == 10 || c == 13)
      {
        inEndOfLineComment = false;
        if (last == 13 && c == 10) continue;
        var n = fan.sys.Str.trim(name);
        if (v !== null)
        {
          props.add(n, fan.sys.Str.trim(v));
          name = "";
          v = null;
        }
        else if (n.length > 0)
          throw fan.sys.IOErr.make("Invalid name/value pair [Line " + lineNum + "]");
        lineNum++;
        continue;
      }

      // if in comment
      if (inEndOfLineComment) continue;

      // block comment
      if (inBlockComment > 0)
      {
        if (last == 47 && c == 42) inBlockComment++;
        if (last == 42 && c == 47) inBlockComment--;
        continue;
      }

      // equal
      if (c == 61 && v === null)
      {
        v = "";
        continue;
      }

      // comment
      if (c == 47 && fan.sys.Int.isSpace(last))
      {
        var peek = this.rChar();
        if (peek < 0) break;
        if (peek == 47) { inEndOfLineComment = true; continue; }
        if (peek == 42) { inBlockComment++; continue; }
        this.unreadChar(peek);
      }

      // escape or line continuation
      if (c == 92)
      {
        var peek = this.rChar();
        if (peek < 0) break;
        else if (peek == 110) c = 10;
        else if (peek == 114) c = 13;
        else if (peek == 116) c = 9;
        else if (peek == 92)  c = 92;
        else if (peek == 13 || peek == 10)
        {
          // line continuation
          lineNum++;
          if (peek == 13)
          {
            peek = this.rChar();
            if (peek != 10) this.unreadChar(peek);
          }
          while (true)
          {
            peek = this.rChar();
            if (peek == 32 || peek == 09) continue;
            this.unreadChar(peek);
            break;
          }
          continue;
        }
        else if (peek == 117)
        {
          var n3 = fan.sys.InStream.hex(this.rChar());
          var n2 = fan.sys.InStream.hex(this.rChar());
          var n1 = fan.sys.InStream.hex(this.rChar());
          var n0 = fan.sys.InStream.hex(this.rChar());
          if (n3 < 0 || n2 < 0 || n1 < 0 || n0 < 0) throw fan.sys.IOErr.make("Invalid hex value for \\uxxxx [Line " +  lineNum + "]");
          c = ((n3 << 12) | (n2 << 8) | (n1 << 4) | n0);
        }
        else throw fan.sys.IOErr.make("Invalid escape sequence [Line " + lineNum + "]");
      }

      // normal character
      if (v === null)
        name += String.fromCharCode(c);
      else
        v += String.fromCharCode(c);
    }

    var n = fan.sys.Str.trim(name);
    if (v !== null)
      props.add(n, fan.sys.Str.trim(v));
    else if (n.length > 0)
      throw fan.sys.IOErr.make("Invalid name/value pair [Line " + lineNum + "]");

    return props;
  }
  finally
  {
    try { this.close(); } catch (err) { fan.sys.Err.make(err).trace(); }
    this.charset$(origCharset);
  }
}

fan.sys.InStream.hex = function(c)
{
  if (48 <= c && c <= 57) return c - 48;
  if (97 <= c && c <= 102) return c - 97 + 10;
  if (65 <= c && c <= 70) return c - 65 + 10;
  return -1;
}

fan.sys.InStream.prototype.pipe = function(out, toPipe, close)
{
  if (toPipe === undefined) toPipe = null;
  if (close === undefined) close = true;

  try
  {
    var bufSize = fan.sys.Int.Chunk;
    var buf = fan.sys.Buf.make(bufSize);
    var total = 0;
    if (toPipe == null)
    {
      while (true)
      {
        var n = this.readBuf(buf.clear(), bufSize);
        if (n == null) break;
        out.writeBuf(buf.flip(), buf.remaining());
        total += n;
      }
    }
    else
    {
      var toPipeVal = toPipe;
      while (total < toPipeVal)
      {
        if (toPipeVal - total < bufSize) bufSize = toPipeVal - total;
        var n = this.readBuf(buf.clear(), bufSize);
        if (n == null) throw fan.sys.IOErr.make("Unexpected end of stream");
        out.writeBuf(buf.flip(), buf.remaining());
        total += n;
      }
    }
    return total;
  }
  finally
  {
    if (close) this.close();
  }
}

fan.sys.InStream.prototype.close = function()
{
  if (this.$in != null) return this.$in.close();
  return true;
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.InStream.prototype.$typeof = function()
{
  return fan.sys.InStream.$type;
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.InStream.make = function($in)
{
  var s = new fan.sys.InStream();
  s.make$($in);
  return s;
}

fan.sys.InStream.makeForStr = function(s)
{
  return new fan.sys.StrInStream(s);
}

