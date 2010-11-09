//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 10  Brian Frank  Creation
//

**
** COperators is used to manage methods annoated with the
** Operator facet for efficient operator method resolution.
**
class COperators
{
  new make(CType parent)
  {
    this.parent = parent
    parent.slots.each |slot|
    {
      if (slot is CMethod && slot.hasFacet("sys::Operator"))
      {
        prefix := toPrefix(slot.name)
        if (prefix == null) echo("WARN: operator method has invalid perfix: $slot.qname")
        else
        {
          acc := byPrefix[prefix]
          if (acc == null) byPrefix[prefix] = acc = CMethod[,]
          acc.add(slot)
        }
      }
    }
  }

  **
  ** Given a method name get the operator prefix:
  **   "plus"     =>  "plus"
  **   "plusInt"  =>  "plus"
  **   "fooBar"   =>  null
  **
  static Str? toPrefix(Str methodName)
  {
    exacts[methodName] ?: prefixes.find |p| { methodName.startsWith(p) }
  }

  CMethod[] find(Str prefix)
  {
    byPrefix[prefix] ?: CMethod#.emptyList
  }

  private static const Str[] prefixes := ["get", "plus", "minus", "mult", "div", "mod"]
  private static const Str:Str exacts := Str:Str[:].setList(prefixes).setList(["set", "negate", "increment", "decrement"])

  readonly CType parent
  private readonly Str:CMethod[] byPrefix := [:]
}