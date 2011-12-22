//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Dec 11  Brian Frank  Creation
//

**
** DocIndexer provides hooks to for document specific
** text indexing via `Doc.onIndex`
**
mixin DocIndexer
{
  ** Add plain, unformatted text to the index for current doc
  abstract Void addStr(Str str)

  ** Add fandoc formatted text to the index for current doc
  abstract Void addFandoc(DocFandoc fandoc)
}