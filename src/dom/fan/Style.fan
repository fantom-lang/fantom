//
// Copyright (c) 2014, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Dec 2014  Andy Frank  Creation
//

using gfx

**
** Style models CSS style properties.
**
@NoDoc @Js
class Style
{
  ** Private ctor.
  private new make() {}

  ** Get the given property value.
  native Obj get(Str name)

  ** Set the given property valye.
  native Void set(Str name, Obj val)

  ** Set all the given property values.
  Void setAll(Str:Obj map)
  {
    map.each |val, name| { set(name, val) }
  }
}