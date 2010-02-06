//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 08  Brian Frank  Creation
//

using web

**
** PipelineMod routes seriallly through a list of sub-WebMods.
**
** See [pod doc]`pod-doc#pipeline`
**
const class PipelineMod : WebMod
{
  **
  ** Constructor with it-block.
  **
  new make(|This|? f)
  {
    f?.call(this)
    if (before.isEmpty && steps.isEmpty && after.isEmpty)
      throw ArgErr("PipelineMod has not steps configured")
  }

  **
  ** Steps to run serially regardless of 'WebRes.isDone'
  ** before every request.
  **
  const WebMod[] before := WebMod[,]

  **
  ** Steps to run serially until 'WebRes.isDone' returns true.
  **
  const WebMod[] steps := WebMod[,]

  **
  ** Steps to run serially regardless of 'WebRes.isDone'
  ** after every request.
  **
  const WebMod[] after := WebMod[,]

  **
  ** Call 'onStart' on sub-mods.
  **
  override Void onStart()
  {
    before.each |mod| { mod.onStart }
    steps.each  |mod| { mod.onStart }
    after.each  |mod| { mod.onStart }
  }

  **
  ** Call 'onStop' on sub-mods.
  **
  override Void onStop()
  {
    before.each |mod| { mod.onStop}
    steps.each  |mod| { mod.onStop }
    after.each  |mod| { mod.onStop }
  }

  **
  ** Service the pipeline.
  **
  override Void onService()
  {
    before.each |mod| { req.mod = mod; mod.onService }
    steps.each  |mod| { req.mod = mod; if (!res.isDone) mod.onService }
    after.each  |mod| { req.mod = mod; mod.onService }
  }

}