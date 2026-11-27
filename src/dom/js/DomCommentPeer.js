//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 2026  Brian Frank  Creation
//

class DomCommentPeer extends DomNodePeer {

  constructor(self) { super(self); }

  _make(self, text) { this.bind(self, DomNodePeer.doc().createComment(text)); }
}
