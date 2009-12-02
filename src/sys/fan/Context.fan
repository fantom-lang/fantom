//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//

**
** Context is used to encapsulate the mutable world state of
** an actor as it moves between threads during its execution
** lifetime.  Context provides a map of arbitrary objects keyed
** by a string name to store state.
**
final class Context
{

  **
  ** Private make
  **
  private new make()

  **
  ** Get the actor associated with this context.
  **
  Actor actor()

  **
  ** Get the map used to store the actor's mutable state.
  **
  Str:Obj? map()

  **
  ** Conveniece for getting a value from the `map`.
  **
  Obj? get(Str name, Obj? def := null)

  **
  ** Conveniece for setting a value from the `map`.
  **
  This set(Str name, Obj? val)

  **
  ** Trap is implemented to get and set the map via
  ** the dynamic invoke operator:
  **
  **   cx->foo      =>  cx.get("foo")
  **   cx->foo = 8  =>  cx.set("foo", 8)
  **
  ** If you attempt to call trap with no arguments on a
  ** name not in the map, then UnknownSlotErr is raised.
  **
  override Obj? trap(Str name, Obj?[]? args)

}