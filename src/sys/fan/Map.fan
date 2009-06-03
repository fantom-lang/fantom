//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 06  Brian Frank  Creation
//

**
** Map is a hash map of key/value pairs.
**
** See `docCookbook::Maps` for coding examples.
**
final class Map
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor with of type (must be Map type).
  **
  new make(Type type)

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Two Maps are equal if they have the same type and number
  ** of equal key/value pairs.
  **
  ** Examples:
  **   a := Int:Str[1:"one", 2:"two"]
  **   b := Int:Str[2:"two", 1:"one"]
  **   c := Int:Str?[2:"two", 1:"one"]
  **   a == b  =>  true
  **   a == c  =>  false
  **
  override Bool equals(Obj? that)

  **
  ** Return platform dependent hashcode based on hash of the keys and values.
  **
  override Int hash()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if size() == 0.  This method is idempotent.
  **
  Bool isEmpty()

  **
  ** Get the number of key/value pairs in the list.  This
  ** method is idempotent.
  **
  Int size()

  **
  ** Get the value for the specified key.  If key is not mapped,
  ** then return the value of the def parameter.  If def is omitted
  ** it defaults to the `def` field.  This method is idempotent.
  ** Shortcut is a[key].
  **
  V? get(K key, V? def := this.def)

  **
  ** Return if the specified key is mapped.
  ** This method is idempotent.
  **
  Bool containsKey(K key)

  **
  ** Get a list of all the mapped keys.  This method is idempotent.
  **
  K[] keys()

  **
  ** Get a list of all the mapped values.  This method is idempotent.
  **
  V[] values()

  **
  ** Create a shallow duplicate copy of this Map.  The keys and
  ** values themselves are not duplicated.  This method is idempotent.
  **
  M dup()

  **
  ** Set the value for the specified key.  If the key is already
  ** mapped, this overwrites the old value.  If key is not yet mapped
  ** this adds the key/value pair to the map.  Return this.  If key
  ** does not return true for Obj.isImmutable, then throw NotImmutableErr.
  ** If key is null throw NullErr.  Throw ReadonlyErr if readonly.
  **
  M set(K key, V val)

  **
  ** Add the specified key/value pair to the map.  If the key is
  ** already mapped, then throw the ArgErr.  Return this.  If key
  ** does not return true for Obj.isImmutable, then throw NotImmutableErr.
  ** If key is null throw NullErr.  Throw ReadonlyErr if readonly.
  **
  M add(K key, V val)

  **
  ** Append the specified map to this map by setting every key/value in
  ** m in this map.  Keys in m not yet mapped are added and keys already
  ** mapped are overwritten.  Return this.  Throw ReadonlyErr if readonly.
  ** Also see `addAll`.  This method is semanatically equivalent to:
  **   m.each |K k, V v| { this.set(k, v) }
  **
  M setAll(M m)

  **
  ** Append the specified map to this map by adding every key/value in
  ** m in this map.  If any key in m is already mapped then this method
  ** will fail (any previous keys will remain mapped potentially leaving
  ** this map in an inconsistent state).  Return this.  Throw ReadonlyErr if
  ** readonly.  Also see `setAll`. This method is semanatically equivalent to:
  **   m.each |K k, V v| { this.add(k, v) }
  **
  M addAll(M m)

  **
  ** Add the specified list to this map where the values are the list items
  ** and the keys are derived by calling the specified function on each item.
  ** If the function is null, then the items themselves are used as the keys.
  ** If any key already mapped then it is overwritten.  Return this.  Throw
  ** ReadonlyErr if readonly.  Also see `addList`.
  **
  ** Examples:
  **   m := [0:"0", 2:"old"]
  **   m.setList(["1","2"]) |Str s->Int| { return s.toInt }
  **   m  =>  [0:0, 1:1, 2:2]
  **
  M setList(V[] list, |V item, Int index->K|? c := null)

  **
  ** Add the specified list to this map where the values are the list items
  ** and the keys are derived by calling the specified function on each item.
  ** If the function is null, then the items themselves are used as the keys.
  ** If any key already mapped then this method will fail (any previous keys
  ** will remain mapped potentially leaving this map in an inconsistent state).
  ** Return this.  Throw ReadonlyErr if readonly.  Also see `setList`.
  **
  ** Examples:
  **   m := [0:"0"]
  **   m.addList(["1","2"]) |Str s->Int| { return s.toInt }
  **   m  =>  [0:0, 1:1, 2:2]
  **
  M addList(V[] list, |V item, Int index->K|? c := null)

  **
  ** Remove the key/value pair identified by the specified key
  ** from the map and return the value.   If the key was not mapped
  ** then return null.  Throw ReadonlyErr if readonly.
  **
  V? remove(K key)

  **
  ** Remove all key/value pairs from the map.  Return this.
  ** Throw ReadonlyErr if readonly.
  **
  Void clear()

  **
  ** This field configures case sensitivity for maps with Str keys.  When
  ** set to true, Str keys are compared without regard to case for the following
  ** methods:  get, containsKey, set, add, setAll, addAll, and remove methods.
  ** Only ASCII character case is taken into account.  The original case
  ** is preserved (keys aren't made all lower or upper case).  This field
  ** defaults to false.
  **
  ** Getting this field is idempotent.  If you attempt to set this method
  ** on a map which is not empty or not typed to use Str keys, then throw
  ** UnsupportedOperation.  Throw ReadonlyErr if set when readonly.  This
  ** mode cannot be used concurrently with `ordered`.
  **
  Bool caseInsensitive := false

  **
  ** When set to true, the map maintains the order in which key/value
  ** pairs are added to the map.  The implementation is based on using
  ** a linked list in addition to the normal hashmap.  This field defaults
  ** to false.
  **
  ** Getting this field is idempotent.  If you attempt to set this method
  ** on a map which is not empty, then throw UnsupportedOperation.  Throw
  ** ReadonlyErr if set when readonly.  This mode cannot be used concurrently
  ** with `caseInsensitive`.
  **
  Bool ordered := false

  **
  ** The default value to use for `get` when a key isn't mapped.
  ** This field defaults to null.  The value of 'def' must be immutable
  ** or NotImmutableErr is thrown.  Getting this field is idempotent.
  ** Throw ReadonlyErr if set when readonly.
  **
  V? def

//////////////////////////////////////////////////////////////////////////
// Str
//////////////////////////////////////////////////////////////////////////

  **
  ** Return a string representation the Map.  This method is idempotent.
  **
  override Str toStr()

  **
  ** Return a string by concatenating each key/value pair using
  ** the specified separator string.  If c is non-null then it
  ** is used to format each pair into a string, otherwise "$k: $v"
  ** is used.  This method is idempotent.
  **
  ** Example:
  **
  Str join(Str separator, |V val, K key->Str|? c := null)

  **
  ** Get this map as a Fan expression suitable for code generation.
  ** The individual keys and values must all respond to the 'toCode' method.
  **
  Str toCode()

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

  **
  ** Call the specified function for every key/value in the list.
  ** This method is idempotent.
  **
  Void each(|V val, K key| c)

  **
  ** Iterate every key/value pair in the map until the function
  ** returns non-null.  If function returns non-null, then break
  ** the iteration and return the resulting object.  Return null
  ** if the function returns null for every key/value pair.
  ** This method is idempotent.
  **
  Obj? eachWhile(|V val, K key->Obj?| c)

  **
  ** Return the first value in the map for which c returns true.
  ** If c returns false for every pair, then return null.  This
  ** method is idempotent.
  **
  V? find(|V val, K key->Bool| c)

  **
  ** Return a new map containing the key/value pairs for which c
  ** returns true.  If c returns false for every item, then return
  ** an empty map.  The inverse of this method is exclude(). This
  ** method is idempotent.
  **
  M findAll(|V val, K key->Bool| c)

  **
  ** Return a new map containing the key/value pairs for which c
  ** returns false.  If c returns true for every item, then return
  ** an empty list.  The inverse of this method is findAll().  This
  ** method is idempotent.
  **
  ** Example:
  **   map := ["off":0, "slow":50, "fast":100]
  **   map.exclude |Int v->Bool| { return v == 0 } => ["slow":50, "fast":100]
  **
  M exclude(|V val, K key->Bool| c)

  **
  ** Return true if c returns true for any of the key/value pairs
  ** in the map.  If the map is empty, return false.  This method
  ** is idempotent.
  **
  Bool any(|V val, K key->Bool| c)

  **
  ** Return true if c returns true for all of the key/value pairs
  ** in the map.  If the list is empty, return true.  This method
  ** is idempotent.
  **
  Bool all(|V val, K key->Bool| c)

  **
  ** Reduce is used to iterate through every value in the map
  ** to reduce the map into a single value called the reduction.
  ** The initial value of the reduction is passed in as the init
  ** parameter, then passed back to the closure along with each
  ** item.  This method is idempotent.
  **
  ** Example:
  **   m := ["2":2, "3":3, "4":4]
  **   m.reduce(100) |Obj r, Int v->Obj| { return (Int)r + v } => 109
  **
  Obj? reduce(Obj? init, |Obj? reduction, V val, K key->Obj?| c)

  **
  ** Create a new map with the same keys, but apply the specified
  ** closure to generate new values.  The new mapped is typed based
  ** on the return type of c.  This method is idempotent.  Return
  ** the acc parameter.
  **
  ** Example:
  **   m := [2:2, 3:3, 4:4]
  **   x := m.map |Int v->Int| { return v*2 }
  **   x => [2:4, 3:6, 4:8]
  **
  Map map(|V val, K key->Obj| c)

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if this Map is readonly.  A readonly Map is guaranteed
  ** to be immutable (although its values may be mutable themselves).
  ** Any attempt to modify a readonly Map will result in ReadonlyErr.
  ** Use rw() to get a read-write Map from a readonly Map.  Methods
  ** documented as idempotent may be used safely with a readonly Map.
  ** This method is idempotent.
  **
  Bool isRO()

  **
  ** Return if this Map is read-write.  A read-write Map is mutable
  ** and may be modified.  Use ro() to get a readonly Map from a
  ** read-write Map.  This method is idempotent.
  **
  Bool isRW()

  **
  ** Get a readonly, immutable Map instance with the same contents
  ** as this Map (although its values may be mutable themselves).
  ** If this Map is already readonly, then return this.  Only methods
  ** documented as idempotent may be used safely with a readonly
  ** Map, all others will throw ReadonlyErr.  This method is
  ** idempotent.
  **
  M ro()

  **
  ** Get a read-write, mutable Map instance with the same contents
  ** as this Map.  If this Map is already read-write, then return this.
  ** This method is idempotent.
  **
  M rw()

  **
  ** Return an immutable Map which returns true for Obj.isImmtable.
  ** If this Map is already immutable, then return this.  This method
  ** is effectively a "deep ro()" which guarantees that if any values
  ** are Lists or Maps, then they are made immutable by recursively calling
  ** toImmutable.  All other values must return true for Obj.isImmutable,
  ** otherwise NotImmutableErr is thrown.  This method must be used
  ** whenever setting a const Map field.  This method is idempotent.
  **
  M toImmutable()

}