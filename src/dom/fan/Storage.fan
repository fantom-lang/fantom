//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 19  Andy Frank  Creation
//

**
** Storage models a DOM Storage.
**
** See [pod doc]`pod-doc#win` for details.
**
@Js
class Storage
{

//////////////////////////////////////////////////////////////////////////
// Constrcutor
//////////////////////////////////////////////////////////////////////////

  **
  ** Private ctor.
  **
  private new make() {}

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the number of items in storage.
  **
  native Int size()

  **
  ** Return the key value for this index. If the index is greater
  ** than or equal to 'size' returns null.
  **
  native Str? key(Int index)

  **
  ** Return Obj stored under this key, or null if key does not exist.
  **
  @Operator
  native Obj? get(Str key)

  **
  ** Store value under this key.
  **
  @Operator
  native Void set(Str key, Obj val)

  **
  ** Remove value for this key. If no value for this key exists,
  ** this method does nothing.
  **
  native Void remove(Str key)

  **
  ** Remove all items from storage.  If store was empty, this
  ** method does nothing.
  **
  native Void clear()

}