//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Str
 */
fan.sys.Str = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Str.prototype.$ctor = function() {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Str.prototype.type = function()
{
  return fan.sys.Type.find("sys::Str");
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Str.compareIgnoreCase = function(self, that)
{
  var a = self.toLowerCase();
  var b = that.toLowerCase();
  if (a < b) return -1;
  if (a == b) return 0;
  return 1;
}

fan.sys.Str.contains = function(self, arg)
{
  return self.indexOf(arg) != -1
}

fan.sys.Str.containsChar = function(self, arg)
{
  return self.indexOf(fan.sys.Int.toChar(arg)) != -1
}

fan.sys.Str.each = function(self, func)
{
  for (var i=0; i<self.length; i++)
    func(self.charCodeAt(i), i);
}

fan.sys.Str.endsWith = function(self, test)
{
  if (self.length < test.length) return false;
  for (var i=0; i<test.length; i++)
    if (self[self.length-i-1] != test[test.length-i-1])
      return false;
  return true;
}

fan.sys.Str.equalsIgnoreCase = function(self, that)
{
  return self.toLowerCase() == that.toLowerCase();
}

fan.sys.Str.get = function(self, index)
{
  if (index < 0) index += self.length;
  return self.charCodeAt(index);
}

fan.sys.Str.index = function(self, s, off)
{
  var i = 0;
  if (off != null) i = off;
  if (i < 0) i = self.length+i;
  var r = self.indexOf(s, i);
  if (r < 0) return null;
  return r;
}

fan.sys.Str.indexr = function(self, s, off)
{
  var i = -1;
  if (off != null) i = off;
  if (i < 0) i = self.length+i;
  var r = self.lastIndexOf(s, i);
  if (r < 0) return null;
  return r;
}

fan.sys.Str.indexIgnoreCase = function(self, s, off)
{
  return fan.sys.Str.index(self.toLowerCase(), s.toLowerCase(), off);
}

fan.sys.Str.indexrIgnoreCase = function(self, s, off)
{
  return fan.sys.Str.indexr(self.toLowerCase(), s.toLowerCase(), off);
}

fan.sys.Str.intern = function(self)
{
  return self;
}

fan.sys.Str.isAscii = function(self)
{
  for (var i=0; i<self.length; i++)
    if (self.charCodeAt(i) > 127)
      return false;
  return true;
}

fan.sys.Str.isEmpty = function(self)
{
  return self.length == 0;
}

fan.sys.Str.isLower = function(self)
{
  for (var i=0; i<self.length; i++)
  {
    var ch = self.charCodeAt(i);
    if (ch < 97 || ch > 122) return false;
  }
  return true;
}

fan.sys.Str.isSpace = function(self)
{
  for (var i=0; i<self.length; i++)
  {
    var ch = self.charCodeAt(i);
    if (ch != 32 && ch != 9 && ch != 10 && ch != 12 && ch != 13)
      return false;
  }
  return true;
}

fan.sys.Str.isUpper = function(self)
{
  for (var i=0; i<self.length; i++)
  {
    var ch = self.charCodeAt(i);
    if (ch < 65 || ch > 90) return false;
  }
  return true;
}

fan.sys.Str.lower = function(self)
{
  return self.toLowerCase();
}

fan.sys.Str.replace = function(self, oldstr, newstr)
{
  return self.replace(oldstr, newstr);
}

fan.sys.Str.justl = function(self, width)
{
  return fan.sys.Str.padr(self, width, 32);
}

fan.sys.Str.justr = function(self, width)
{
  return fan.sys.Str.padl(self, width, 32);
}

fan.sys.Str.padl = function(self, w, ch)
{
  if (ch == undefined) ch = 32;
  if (self.length >= w) return self;
  var c = String.fromCharCode(ch);
  var s = '';
  for (var i=self.length; i<w; ++i) s += c;
  s += self;
  return s;
}

fan.sys.Str.padr = function(self, w, ch)
{
  if (ch == undefined) ch = 32;
  if (self.length >= w) return self;
  var c = String.fromCharCode(ch);
  var s = '';
  s += self;
  for (var i=self.length; i<w; ++i) s += c;
  return s;
}

fan.sys.Str.reverse = function(self)
{
  var rev = "";
  for (var i=self.length-1; i>=0; i--)
    rev += self[i];
  return rev;
}

fan.sys.Str.size = function(self)
{
  return self.length;
}

fan.sys.Str.slice = function(self, range)
{
  var size = self.length;
  var s = range.start(size);
  var e = range.end(size);
  if (e+1 < s) throw new fan.sys.IndexErr(range);
  return self.substr(s, (e-s)+1);
}

fan.sys.Str.spaces = function(n)
{
  if (fan.sys.Str.$spaces == null)
  {
    fan.sys.Str.$spaces = new Array();
    var s = "";
    for (var i=0; i<20; i++)
    {
      fan.sys.Str.$spaces[i] = s;
      s += " ";
    }
  }
  if (n < 20) return fan.sys.Str.$spaces[n];
  var s = "";
  for (var i=0; i<n; i++) s += " ";
  return s;
}
fan.sys.Str.$spaces = null;

fan.sys.Str.capitalize = function(self)
{
  if (self.length > 0)
  {
    var ch = self.charCodeAt(0);
    if (97 <= ch && ch <= 122)
      return String.fromCharCode(ch & ~0x20) + self.substring(1);
  }
  return self;
}

fan.sys.Str.toDisplayName = function(self)
{
  if (self.length == 0) return "";
  var s = '';

  // capitalize first word
  var c = self.charCodeAt(0);
  if (97 <= c && c <= 122) c &= ~0x20;
  s += String.fromCharCode(c);

  // insert spaces before every capital
  var last = c;
  for (var i=1; i<self.length; ++i)
  {
    c = self.charCodeAt(i);
    if (65 <= c && c <= 90 && last != 95)
    {
      var next = i+1 < self.length ? self.charCodeAt(i+1) : 81;
      if (!(65 <= last && last <= 90) || !(65 <= next && next <= 90))
        s += ' ';
    }
    else if (97 <= c && c <= 122)
    {
      if ((48 <= last && last <= 57)) { s += ' '; c &= ~0x20; }
      else if (last == 95) c &= ~0x20;
    }
    else if (48 <= c && c <= 57)
    {
      if (!(48 <= last && last <= 57)) s += ' ';
    }
    else if (c == 95)
    {
      s += ' ';
      last = c;
      continue;
    }
    s += String.fromCharCode(c);
    last = c;
  }
  return s;
}

fan.sys.Str.startsWith = function(self, test)
{
  if (self.length < test.length) return false;
  for (var i=0; i<test.length; i++)
    if (self[i] != test[i])
      return false;
  return true;
}

fan.sys.Str.toBool = function(self, checked) { return fan.sys.Bool.fromStr(self, checked); }
fan.sys.Str.toFloat = function(self, checked) { return fan.sys.Float.fromStr(self, checked); }
fan.sys.Str.toInt = function(self, radix, checked) { return fan.sys.Int.fromStr(self, radix, checked); }

fan.sys.Str.trim = function(self, trimStart, trimEnd)
{
  if (self.length == 0) return self;
  if (trimStart == null) trimStart = true;
  if (trimEnd == null) trimEnd = true;
  var s = 0;
  var e = self.length-1;
  while (trimStart && s<self.length && self.charCodeAt(s) <= 32) s++;
  while (trimEnd && e>=s && self.charCodeAt(e) <= 32) e--;
  return self.substr(s, (e-s)+1);
}
fan.sys.Str.trimStart = function(self) { return fan.sys.Str.trim(self, true, false); }
fan.sys.Str.trimEnd   = function(self) { return fan.sys.Str.trim(self, false, true); }

fan.sys.Str.split = function(self, sep, trimmed)
{
  if (sep == null) return fan.sys.Str.splitws(self);
  var toks = new Array();
  var trim = (trimmed != null) ? trimmed : true;
  var len = self.length;
  var x = 0;
  for (var i=0; i<len; ++i)
  {
    if (self.charCodeAt(i) != sep) continue;
    if (x <= i) toks.push(fan.sys.Str.splitStr(self, x, i, trim));
    x = i+1;
  }
  if (x <= len) toks.push(fan.sys.Str.splitStr(self, x, len, trim));
  return toks;
}

fan.sys.Str.splitStr = function(val, s, e, trim)
{
  if (trim == true)
  {
    while (s < e && val.charCodeAt(s) <= 32) ++s;
    while (e > s && val.charCodeAt(e-1) <= 32) --e;
  }
  return val.substring(s, e);
}

fan.sys.Str.splitws = function(val)
{
  var toks = new Array();
  var len = val.length;
  while (len > 0 && val.charCodeAt(len-1) <= 32) --len;
  var x = 0;
  while (x < len && val.charCodeAt(x) <= 32) ++x;
  for (var i=x; i<len; ++i)
  {
    if (val.charCodeAt(i) > 32) continue;
    toks.push(val.substring(x, i));
    x = i + 1;
    while (x < len && val.charCodeAt(x) <= 32) ++x;
    i = x;
  }
  if (x <= len) toks.push(val.substring(x, len));
  if (toks.length == 0) toks.push("");
  return toks;
}

fan.sys.Str.splitLines = function(self)
{
  var lines = fan.sys.List.make(fan.sys.Type.find("sys::Str"), []);
  var len = self.length;
  var s = 0;
  for (var i=0; i<len; ++i)
  {
    var c = self.charAt(i);
    if (c == '\n' || c == '\r')
    {
      lines.push(self.substring(s, i));
      s = i+1;
      if (c == '\r' && s < len && self.charAt(s) == '\n') { i++; s++; }
    }
  }
  lines.push(self.substring(s, len));
  return lines;
}

fan.sys.Str.upper = function(self) { return self.toUpperCase(); }
fan.sys.Str.$in = function(self) { return fan.sys.InStream.makeForStr(self); }
fan.sys.Str.toUri = function(self) { return fan.sys.Uri.make(self); }

fan.sys.Str.toCode = function(self, quote, escu)
{
  if (quote == undefined) quote = 34;
  if (escu == undefined) escu = false;

  // opening quote
  var s = "";
  var q = 0;
  if (quote != null)
  {
    q = String.fromCharCode(quote);
    s += q;
  }

  // NOTE: these escape sequences are duplicated in ObjEncoder
  var len = self.length;
  for (var i=0; i<len; ++i)
  {
    var c = self.charAt(i);
    switch (c)
    {
      case '\n': s += '\\' + 'n'; break;
      case '\r': s += '\\' + 'r'; break;
      case '\f': s += '\\' + 'f'; break;
      case '\t': s += '\\' + 't'; break;
      case '\\': s += '\\' + '\\'; break;
      case '"':  if (q == '"')  s += '\\' + '"';  else s += c; break;
      case '`':  if (q == '`')  s += '\\' + '`';  else s += c; break;
      case '\'': if (q == '\'') s += '\\' + '\''; else s += c; break;
      case '$':  s += '\\' + '$'; break;
      default:
        var hex  = function(x) { return "0123456789abcdef".charAt(x); }
        var code = c.charCodeAt(0);
        if (escu && code > 127)
        {
          s += '\\' + 'u'
            + hex((code>>12)&0xf)
            + hex((code>>8)&0xf)
            + hex((code>>4)&0xf)
            + hex(code & 0xf);
        }
        else
        {
          s += c;
        }
    }
  }

  // closing quote
  if (q != 0) s += q;
  return s;
}