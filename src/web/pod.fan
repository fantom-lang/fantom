//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 Nov 06  Brian Frank  Original
//   14 Jul 09  Brian Frank  Create from "build.fan"
//

**
** Standard weblet APIs for processing HTTP requests
**

@podDepends  = [Depend("sys 1.0"), Depend("inet 1.0")]
@podSrcDirs  = [`fan/`, `test/`]
@indexFacets = ["web::webView"]

pod web
{
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

