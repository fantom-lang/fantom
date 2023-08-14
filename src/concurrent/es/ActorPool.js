//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 10  Andy Frank  Creation
//   13 May 10  Andy Frank  Move from sys to concurrent
//   22 Jun 23  Matthew Giannini  Refactor for ES
//

/**
 * ActorPool.
 */
class ActorPool extends sys.Obj {
  constructor() {
    super();
  }

  #name = "ActorPool";
  name$() { return this.#name; }
  __name$(it) { this.#name = it; }

  #maxThreads = 100;
  maxThreads() { return this.#maxThreads; }
  __maxThreads(it) { this.#maxThreads = it; }

  typeof$() { return ActorPool.type$; }

  static make(f) {
    const self = new ActorPool();
    ActorPool.make$(self, f);
    return self;
  }

  static make$(self, f) {
    if (f) f(self);
  }
}