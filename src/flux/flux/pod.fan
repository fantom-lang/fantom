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

@podIndexFacets = [@fluxResource, @fluxSideBar, @fluxView, @fluxViewMimeType]

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
  ** The strings are either full MIME types such as "text/html" or
  ** just the media type such as "text".
  ** See `docLib::Flux`.
  **
  Str[] fluxViewMimeType := Str[,]

  **
  ** Used to mark a widget as a flux side bar.
  ** See `docLib::Flux`.
  **
  Bool fluxSideBar := false

//////////////////////////////////////////////////////////////////////////
// Options
//////////////////////////////////////////////////////////////////////////

  **
  ** Default uri to display on startup.
  **
  virtual Uri homePage := `flux:start`

  **
  ** Directories to index for Goto-File command.
  **
  virtual Uri[] indexDirs := Uri[,]

  **
  ** Binding of command ids to key accelerators.  The keys of this
  ** map are [FluxCommand.ids]`FluxCommand.id`.  See `CommandId` for
  ** the commonly used predefined commmands.  The values of the map
  ** are string representations of `fwt::Key`.  If a command is not mapped
  ** in this table, then it defaults to the accelerator defined by
  ** the command's localized props.
  **
  virtual Str:Str keyBindings := Str:Str[:]

}

