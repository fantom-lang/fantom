//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Bool
 */
fan.sys.Bool = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Bool.prototype.$ctor = function() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Bool.prototype.$typeof = function()
{
  return fan.sys.Boo.$type;
}

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

fan.sys.Bool.not = function(self)    { return !self; }
fan.sys.Bool.and = function(self, b) { return self && b; }
fan.sys.Bool.or  = function(self, b) { return self || b; }
fan.sys.Bool.xor = function(self, b) { return self != b; }

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

fan.sys.Bool.fromStr = function(s, checked)
{
  if (checked === undefined) checked = true;
  if (s == "true") return true;
  if (s == "false") return false;
  if (!checked) return null;
  throw fan.sys.ParseErr.make("Bool", s);
}

fan.sys.Bool.toStr  = function(self) { return self ? "true" : "false"; }
fan.sys.Bool.toCode = function(self) { return self ? "true" : "false"; }
fan.sys.Bool.toLocale = function(self)
{
  var key = self ? "boolTrue" : "boolFalse";
  return fan.sys.Env.cur().locale(fan.sys.Pod.find("sys"), key, fan.sys.Bool.toStr(self));
}

