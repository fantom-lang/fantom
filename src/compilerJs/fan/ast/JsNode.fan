//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsNode translates a compiler::Node into the equivalent JavaScript
** source code.
**
abstract class JsNode
{

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  **
  ** Write the JavaScript source code for this node.
  **
  abstract Void write(JsWriter out)

//////////////////////////////////////////////////////////////////////////
// JavaScript
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the JavaScript qname for this CType.
  **
  Str qnameToJs(CType ctype)
  {
    return "fan.${ctype.pod.name}.$ctype.name"
  }

  **
  ** Return the JavaScript variable name for the given Fan
  ** variable name.
  **
  Str vnameToJs(Str name)
  {
    if (vnames.get(name, false)) return "\$$name";
    return name;
  }

  private const Str:Bool vnames :=
  [
    "char":   true,
    "delete": true,
    "in":     true,
    "var":    true,
    "with":   true
  ].toImmutable

}