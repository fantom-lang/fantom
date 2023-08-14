//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 2023  Matthew Giannini  Creation
//

/**
 * Process
 */
class Process extends Obj {
  constructor() { super(); }

  static make(cmd=List.make(Str.type$), dir=null) {
    throw UnsupportedErr.make();
  }

}