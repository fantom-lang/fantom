//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Mar 2016  Andy Frank  Creation
//   10 Jun 2023 Kiera O'Flynn  Refactor to ES
//

class WeakMapPeer extends sys.Obj {

  constructor(self)   { super(); this.map = new js.WeakMap(); }
  has(self, key)      { return this.map.has(key); }
  get(self, key)      { return this.map.get(key); }
  set(self, key, val) { this.map.set(key, val); return self; }
  delete$(self, key)  { return this.map.delete$(key); }

}