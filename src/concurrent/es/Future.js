//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 2010  Andy Frank  Creation
//   13 May 2010  Andy Frank  Move from sys to concurrent
//   22 Jun 2023  Matthew Giannini  Refactor for ES
//

/**
 * Future.
 */
class Future extends sys.Obj {
  constructor() { super(); }

  typeof$() { return Future.type$; }

  static makeCompletable() {
    const self = new Future();
    Future.make$(self);
    return self;
  }

  static make$(self) {
  }

}
