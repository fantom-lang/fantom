//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Mar 2016  Andy Frank  Creation
//

using web

**
** WeakMap is a collection of key/value pairs in which the keys are
** weakly referenced.  The keys must be objects and the values can
** be arbitrary values.
**
@Js
class WeakMap
{
  ** Return 'true' if key exists in this map.
  native Bool has(Obj key)

  ** Returns the value associated to the key, or 'null' if there is none.
  @Operator native Obj? get(Obj key)

  ** Sets value for given key in this map.  Returns this.
  @Operator native This set(Obj key, Obj val)

  ** Removes any value associated to the key. Returns 'true'
  ** if an element has been removed successfully.
  native Bool delete(Obj key)
}