//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Feb 07  Brian Frank  Creation
//

**
** DocWriter is used to output a fandoc model using a series of callbacks.
**
** See [pod doc]`pod-doc#api` for usage.
**
mixin DocWriter
{

  **
  ** Enter a document.
  **
  abstract Void docStart(Doc doc)

  **
  ** Exit a document.
  **
  abstract Void docEnd(Doc doc)

  **
  ** Enter an element.
  **
  abstract Void elemStart(DocElem elem)

  **
  ** Exit an element.
  **
  abstract Void elemEnd(DocElem elem)

  **
  ** Write text node.
  **
  abstract Void text(DocText text)

}


