//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Dec 08  Andy Frank  Creation
//

/**
 * Str
 */
var sys_Str = sys_Obj.extend(
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
    return sys_Type.find("sys::Str");
  },

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Str.compareIgnoreCase = function(self, that)
{
  var a = self.toLowerCase();
  var b = that.toLowerCase();
  if (a < b) return -1;
  if (a == b) return 0;
  return 1;
}

sys_Str.contains = function(self, arg)
{
  return self.indexOf(arg) != -1
}

sys_Str.containsChar = function(self, arg)
{
  return self.indexOf(sys_Int.toChar(arg)) != -1
}

sys_Str.each = function(self, func)
{
  for (var i=0; i<self.length; i++)
    func(self.charAt(i), i);
}

sys_Str.endsWith = function(self, test)
{
  if (self.length < test.length) return false;
  for (var i=0; i<test.length; i++)
    if (self[self.length-i-1] != test[test.length-i-1])
      return false;
  return true;
}

sys_Str.equalsIgnoreCase = function(self, that)
{
  return self.toLowerCase() == that.toLowerCase();
}

sys_Str.get = function(self, index)
{
  if (index < 0) index += self.length;
  return self.charCodeAt(index);
}

sys_Str.index = function(self, s, off)
{
  var i = 0;
  if (off != null) i = off;
  if (i < 0) i = self.length+i;
  var r = self.indexOf(s, i);
  if (r < 0) return null;
  return r;
}

sys_Str.indexr = function(self, s, off)
{
  var i = -1;
  if (off != null) i = off;
  if (i < 0) i = self.length+i;
  var r = self.lastIndexOf(s, i);
  if (r < 0) return null;
  return r;
}

sys_Str.indexIgnoreCase = function(self, s, off)
{
  return sys_Str.index(self.toLowerCase(), s.toLowerCase(), off);
}

sys_Str.indexrIgnoreCase = function(self, s, off)
{
  return sys_Str.indexr(self.toLowerCase(), s.toLowerCase(), off);
}

sys_Str.intern = function(self)
{
  return self;
}

sys_Str.isAscii = function(self)
{
  for (var i=0; i<self.length; i++)
    if (self.charCodeAt(i) > 127)
      return false;
  return true;
}

sys_Str.isEmpty = function(self)
{
  return self.length == 0;
}

sys_Str.isLower = function(self)
{
  for (var i=0; i<self.length; i++)
  {
    var ch = self.charCodeAt(i);
    if (ch < 97 || ch > 122) return false;
  }
  return true;
}

sys_Str.isSpace = function(self)
{
  for (var i=0; i<self.length; i++)
  {
    var ch = self.charCodeAt(i);
    if (ch != 32 && ch != 9 && ch != 10 && ch != 12 && ch != 13)
      return false;
  }
  return true;
}

sys_Str.isUpper = function(self)
{
  for (var i=0; i<self.length; i++)
  {
    var ch = self.charCodeAt(i);
    if (ch < 65 || ch > 90) return false;
  }
  return true;
}

sys_Str.lower = function(self)
{
  return self.toLowerCase();
}

sys_Str.replace = function(self, oldstr, newstr)
{
  return self.replace(oldstr, newstr);
}

sys_Str.reverse = function(self)
{
  var rev = "";
  for (var i=self.length-1; i>=0; i--)
    rev += self[i];
  return rev;
}

sys_Str.size = function(self)
{
  return self.length;
}

sys_Str.slice = function(self, range)
{
  var size = self.length;
  var s = range.start(size);
  var e = range.end(size);
  if (e+1 < s) throw new sys_IndexErr(range);
  return self.substr(s, (e-s)+1);
}

sys_Str.spaces = function(n)
{
  if (sys_Str.$spaces == null)
  {
    sys_Str.$spaces = new Array();
    var s = "";
    for (var i=0; i<20; i++)
    {
      sys_Str.$spaces[i] = s;
      s += " ";
    }
  }
  if (n < 20) return sys_Str.$spaces[n];
  var s = "";
  for (var i=0; i<n; i++) s += " ";
  return s;
}
sys_Str.$spaces = null;

sys_Str.startsWith = function(self, test)
{
  if (self.length < test.length) return false;
  for (var i=0; i<test.length; i++)
    if (self[i] != test[i])
      return false;
  return true;
}

sys_Str.toBool = function(self, checked) { return sys_Bool.fromStr(self, checked); }
sys_Str.toFloat = function(self, checked) { return sys_Float.fromStr(self, checked); }
sys_Str.toInt = function(self, radix, checked) { return sys_Int.fromStr(self, radix, checked); }

sys_Str.trim = function(self, trimStart, trimEnd)
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
sys_Str.trimStart = function(self) { return sys_Str.trim(self, true, false); }
sys_Str.trimEnd   = function(self) { return sys_Str.trim(self, false, true); }

sys_Str.upper = function(self)
{
  return self.toUpperCase();
}