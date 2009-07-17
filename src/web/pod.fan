//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jul 09  Brian Frank  Creation
//

**
** Standard weblet APIs for processing HTTP requests
**

// TODO-SYM (move to webapp?)
@indexFacets = ["web::webView"]

pod web
{

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  **
  ** Indicates a web based view on the given types.
  ** See `docLib::WebApp`.
  **
  Type[] webView := Type[,]

  **
  ** Indicates priority of web view: 0 is lowest.
  ** See `docLib::WebApp`.
  **
  Int webViewPriority := 0
}

