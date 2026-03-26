//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   13 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Bool
 */
class Bool extends Obj {

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  static defVal() { return false; }

  static hash(self) { return self ? 1231 : 1237; }

  

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  static not(self) { return !self; }
  static and(self, b) { return self && b; }
  static or(self, b) { return self || b; }
  static xor(self, b) { return self != b; }

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

  static fromStr(s, checked=true) {
    if (s == "true") return true;
    if (s == "false") return false;
    if (!checked) return null;
    throw ParseErr.makeStr("Bool", s);
  }

  static toStr(self) { return self ? "true" : "false"; }
  static toCode(self) { return self ? "true" : "false"; }
  static toLocale(self) {
    const key = self ? "boolTrue" : "boolFalse";
    return Env.cur().locale(Pod.find("sys"), key, Bool.toStr(self));
  }

}