//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 2026  Brian Frank  Creation
//

class DomTextPeer extends DomNodePeer {

  constructor(self) { super(self); }

  _make(self, text) { this.bind(self, DomNodePeer.doc().createTextNode(text)); }
}
