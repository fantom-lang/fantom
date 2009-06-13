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
var sys_InStream = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_InStream.prototype.$ctor = function() { this.$in = null; }
sys_InStream.prototype.$make = function($in) { this.$in = $in; }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

sys_InStream.prototype.read = function()
{
  try
  {
    return this.$in.read();
  }
  catch (err)
  {
    if (this.$in == null)
      throw sys_UnsupportedErr.make(this.type().qname() + " wraps null InStream");
    else
      throw sys_Err.make(err);
  }
}

// readBuf = function(buf, n)
// unread = function(n)

sys_InStream.prototype.skip = function(n)
{
  if (this.$in != null) return this.$in.skip(n);

  for (var i=0; i<n; ++i)
    if (this.read() == 0) return i;
  return n;
}

// readAllBuf = function()
// readBufFully = function(buf, n)
// peek = function()
// readU1 = function()
// readS1 = function()
// readU2 = function()
// readS2 = function()
// readU4 = function()
// readS4 = function()
// readS8 = function()
// readF4 = function()
// readF8 = function()
// readDecimal = function()
// readBool = function()
// readUtf = function()
// charset = function(charset)

sys_InStream.prototype.readChar = function()
{
  try
  {
    return this.$in.readChar();
  }
  catch (err)
  {
    if (this.$in == null)
      throw sys_UnsupportedErr.make(this.type().qname() + " wraps null InStream");
    else
      throw sys_Err.make(err);
  }
}

sys_InStream.prototype.unreadChar = function(c)
{
  try
  {
    return this.$in.unreadChar(c);
  }
  catch (err)
  {
    if (this.$in == null)
      throw sys_UnsupportedErr.make(this.type().qname() + " wraps null InStream");
    else
      throw sys_Err.make(err);
  }
}

// peekChar = function()

sys_InStream.prototype.readLine = function(max)
{
  if (max == undefined) max = sys_Int.Chunk;

  // max limit
  var maxChars = (max != null) ? max.valueOf() : sys_Int.maxVal;
  if (maxChars <= 0) return "";

  // read first char, if at end of file bail
  var c = this.readChar();
  if (c == null) return null;

  // loop reading chars until we hit newline
  // combo or end of stream
  var buf = "";
  while (true)
  {
    // check for \n, \r\n, or \r
    if (c == 10) break;
    if (c == 13)
    {
      c = this.readChar();
      if (c >= 0 && c != 10) this.unreadChar(c);
      break;
    }

    // append to working buffer
    buf += String.fromCharCode(c);
    if (buf.length >= maxChars) break;

    // read next char
    c = this.readChar();
    if (c == null) break;
  }
  return buf;
}

sys_InStream.prototype.readAllLines = function()
{
  try
  {
    var list = sys_List.make(sys_Type.find("sys::Str"), []);
    var line = "";
    while ((line = this.readLine()) != null)
      list.push(line);
    return list;
  }
  catch (err) { sys_Obj.echo(err); }
  finally
  {
    try { this.close(); } catch (err) { sys_Obj.echo(err); }
  }
}

sys_InStream.prototype.readAllStr = function(normalizeNewlines)
{
  if (normalizeNewlines == undefined) normalizeNewlines = true;
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
        if (c == 13) buf[n++] = 10;
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
    try { this.close(); } catch (err) { sys_Obj.echo(err); }
  }
}

sys_InStream.prototype.readObj = function(options)
{
  if (options == undefined) options = null;
  return new fanx_ObjDecoder(this, options).readObj();
}

sys_InStream.prototype.close = function()
{
  if (this.$in != null) return this.$in.close();
  return true;
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

sys_InStream.prototype.type = function()
{
  return sys_Type.find("sys::InStream");
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

sys_InStream.make = function($in)
{
  var s = new sys_InStream();
  s.$make($in);
  return s;
}

sys_InStream.makeForStr = function(s)
{
  return new sys_StrInStream(s);
}

