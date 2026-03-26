//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2022  Andy Frank  Creation
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class TextSelPeer extends sys.Obj {
  constructor(self)
  {
    super();
    this.sel = null;
  }

  clear(self)
  {
    return this.sel.removeAllRanges();
  }
}