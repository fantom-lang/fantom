//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Aug 08  Brian Frank  Creation
//

**
** Used to implement flux application specific uris
**
@uriScheme="flux"
internal const class FluxScheme : UriScheme
{

  override Obj get(Uri uri, Obj base)
  {
    switch (uri.pathStr)
    {
      case "about": return AboutResource(uri)
      case "start": return StartResource(uri)
      default: return null
    }
  }

}
