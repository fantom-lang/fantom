//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Dec 11  Brian Frank  Creation
//

**
** Doc is the base class for document types.  All Docs are organized
** under a `DocSpace` for  a two level namespace of "spaceName/docName".
**
** Subclasses include:
**  - `DocPodIndex`: pod index
**  - `DocType`: type API
**  - `DocChapter`: chapter in manual
**  - `DocRes`: resource file
**  - `DocSrc`: source file
**
const abstract class Doc
{
  **
  ** Space which contains this document
  **
  abstract DocSpace space()

  **
  ** Name which uniquely identifies this document under its space.
  **
  abstract Str docName()

  **
  ** Default title for the document
  **
  abstract Str title()

  **
  ** String to use for this document in the breadcrumb.
  ** By default this is the `docName`.
  **
  virtual Str breadcrumb() { docName }

  **
  ** Get the default `DocRenderer` type to use for renderering this document.
  **
  abstract Type renderer()
}

