//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Aug 10  Andy Frank  Created
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class StoragePeer extends sys.Obj {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(self) { super(); }

  $instance;

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  size = function(self)
  {
    return this.$instance.length;
  }

  key = function(self, index)
  {
    return this.$instance.key(index);
  }

  get = function(self, key)
  {
    return this.$instance.getItem(key);
  }

  set = function(self, key, val)
  {
    this.$instance.setItem(key, val);
  }

  remove = function(self, key)
  {
    this.$instance.removeItem(key);
  }

  clear = function(self)
  {
    this.$instance.clear();
  }
}