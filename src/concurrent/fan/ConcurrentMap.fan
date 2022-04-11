//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Feb 16  Brian Frank  Creation
//

**
** ConcurrentMap is a Fantom wrapper around Java's ConcurrentHashMap.
** It provides high performance concurrency and allows many operations
** to be performed without locking.  Refer to the ConcurrentHashMap Javadoc
** for the detailed semanatics on behavior and performance.
**
@Js
native const final class ConcurrentMap
{
  ** Make with initial capacity
  new make(Int initialCapacity := 256)

  ** Return if size is zero (this is expensive and requires full segment traveral)
  Bool isEmpty()

  ** Return size (this is expensive and requires full segment traveral)
  Int size()

  ** Get a value by its key or return null
  @Operator Obj? get(Obj key)

  ** Set a value by key
  @Operator Void set(Obj key, Obj val)

  ** Set a value by key and return old value.  Return the old value
  ** mapped by the key or null if it is not currently mapped.
  Obj? getAndSet(Obj key, Obj val)

  ** Add a value by key, raise exception if key was already mapped
  Void add(Obj key, Obj val)

  ** Get the value for the specified key, or if it doesn't exist
  ** then automatically add it with the given default value.
  Obj getOrAdd(Obj key, Obj defVal)

  ** Append the specified map to this map be setting every key/value from
  ** 'm' in this map. Keys in m not yet mapped are added and keys already
  ** mapped are overwritten. Return this.
  This setAll(Map m)

  ** Remove a value by key, ignore if key not mapped
  Obj? remove(Obj key)

  ** Remove all the key/value pairs
  Void clear()

  ** Iterate the map's key value pairs
  Void each(|Obj val, Obj key| f)

  ** Iterate the map's key value pairs until given function
  ** returns non-null and return that as the result of this
  ** method.  Otherwise itereate every pair and return null
  Obj? eachWhile(|Obj val, Obj key->Obj?| f)

  ** Return true if the specified key is mapped
  Bool containsKey(Obj key)

  ** Return list of keys
  Obj[] keys(Type of)

  ** Return list of values
  Obj[] vals(Type of)
}

