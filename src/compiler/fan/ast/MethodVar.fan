//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Feb 06  Brian Frank  Creation
//   11 Sep 06  Brian Frank  Ported from Java to Fan
//

**
** MethodVar is a variable used in a method - either param or local.
**
class MethodVar
{

  new make(Int register, CType ctype, Str name, Int flags := 0, Block? scope := null)
  {
    this.register = register
    this.ctype    = ctype
    this.name     = name
    this.flags    = flags
    this.scope    = scope
    this.usedInClosure = false
  }

  new makeForParam(Int register, ParamDef p, CType paramType)
    : this.make(register, paramType, p.name, FConst.Param, null)
  {
    this.paramDef = p
  }

  Bool isParam()
  {
    return (flags & FConst.Param) != 0
  }

  override Str toStr()
  {
    return "$register  $name: $ctype"
  }

  Int register        // register number
  CType ctype         // variable type
  Str name            // variable name
  Int flags           // Param
  Bool isCatchVar     // is this auto-generated var for "catch (Err x)"
  Block? scope        // block which scopes this variable
  ParamDef? paramDef  // if param
  Bool usedInClosure  // local used by closure within containing method
  CField? cvarsField  // if mapped into a field of closure variable class

}