//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Dec 11  Brian Frank  Creation
//

**
** DocSpace manages a namespace of documents.  All documentation
** is organized into a two level namespace of "spaceName/docName".
**
const abstract class DocSpace
{
  **
  ** Get the name of this space which is unique with the environment.
  **
  abstract Str spaceName()

  **
  ** String to use for this space in the breadcrumb.
  ** By default this is the `spaceName`.
  **
  virtual Str breadcrumb() { spaceName }

  **
  ** Lookup the document in this space.  If not found
  ** raise `UnknownDocErr` or return null based on checked flag.
  **
  abstract Doc? doc(Str docName, Bool checked := true)

  **
  ** Iterate all the documents in this space.
  **
  abstract Void eachDoc(|Doc| f)

  **
  ** Return spaceName by default
  **
  override Str toStr() { spaceName }
}