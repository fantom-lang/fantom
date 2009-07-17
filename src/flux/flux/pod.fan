//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Original
//   14 Jul 09  Brian Frank  Create from "build.fan"
//

**
** Flux: Core Application
**

@podDepends = [Depend("sys 1.0"),
               Depend("gfx 1.0"),
               Depend("fwt 1.0"),
               Depend("compiler 1.0")]

@podSrcDirs = [`fan/`, `fan/views/`, `fan/sidebars/`, `test/`]

@podResDirs = [`locale/`, `test/files/`, `test/files/sub/`]

@indexFacets = ["flux::fluxResource",
                "flux::fluxSideBar",
                "flux::fluxView",
                "flux::fluxViewMimeType"]

pod flux
{

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  **
  ** Used on `Resource` to indicate what types are wrapped.
  ** See `docLib::Flux`.
  **
  Type[] fluxResource := Type[,]

  **
  ** Indicates a flux based view on the given types.
  ** See `docLib::Flux`.
  **
  Type[] fluxView := Type[,]

  **
  ** Indicates a flux based view on files with the given MIME types.
  ** See `docLib::Flux`.
  **
  MimeType[] fluxViewMimeType := MimeType[,]

  **
  ** Used to mark a widget as a flux side bar.
  ** See `docLib::Flux`.
  **
  Bool fluxSideBar := false

}

