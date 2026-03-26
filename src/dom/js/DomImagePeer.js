//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 2022  Brian Frank  Creation
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class DomImagePeer extends sys.Obj {

  constructor(self) { super(); }

  init(self, elem)
  {
    // map dom::Elem("img") to its HTMLImageElement
    this.elem = elem.peer.elem
  }

  isLoaded(self)
  {
    return this.elem.complete;
  }

  size(self)
  {
    return graphics.Size.make(this.w(), this.h());
  }

  w(self)
  {
    return sys.Float.make(this.elem.naturalWidth);
  }

  h(self)
  {
    return sys.Float.make(this.elem.naturalHeight);
  }
}