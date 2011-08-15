//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Aug 11  Brian Frank  Creation
//

using concurrent

**
** DocChapter models a fandoc "chapter" in a manual like docLang
**
const class DocChapter
{
  ** Constructor
  internal new make(|This| f) { f(this) }

  ** Pod name which defines this chapter such as "docLang"
  const Str pod

  ** Simple name of the chapter such as "Overview" or "pod-doc"
  const Str name

  ** Qualified name as "pod::name"
  Str qname() { "$pod::$name" }

  ** Location for chapter file
  const DocLoc loc

  ** Chapter contents as Fandoc string
  const DocFandoc doc

  ** Return qname
  override Str toStr() { qname }

}