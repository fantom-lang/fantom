//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** Flux provides system level utilities for flux applications
**
class Flux
{

  **
  ** The flux home defaults to "{Sys.homeDir}/flux/".
  **
  static File homeDir() { return (Sys.homeDir + `flux/`).normalize }

  **
  ** Standard log for flux pod.
  **
  static const Log log := Flux#.log

  **
  ** Read an options file into memory.  An option file is a
  ** serialized object stored at "{fluxHome}/{name}.fog".
  ** The serialized object can be any const class; by
  ** convention flux option classes end in "Options".  If
  ** the options file is not found, then return 't?.make'.
  **
  static Obj loadOptions(Str name, Type t)
  {
    Str:CachedOptions options := Thread.locals["flux.options"]
    if (options == null) Thread.locals["flux.options"] = options = Str:CachedOptions[:]

    // check cache
    cached := options[name]
    if (cached != null && cached.file.modified == cached.modified)
      return cached.value

    // not cached or modified since we loaded cache
    file := Flux.homeDir + "${name}.fog".toUri
    value := null
    try
    {
      if (file.exists)
      {
        log.debug("Load options: $file")
        value = file.readObj
      }
    }
    catch (Err e)
    {
      log.error("Cannot load options: $file", e)
    }
    if (value == null) value = t?.make

    // update cache
    options[name] = CachedOptions(file, value)

    return value
  }

  // convenience for icons
  internal const static Uri:File icons := Pod.find("icons").files
  internal static Image icon(Uri uri) { return Image(icons[uri]) }

}

**************************************************************************
** CachedOptions
**************************************************************************

internal class CachedOptions
{
  new make(File f, Obj v) { file = f; modified = f.modified; value = v }
  File file
  DateTime modified
  Obj value
}

**************************************************************************
** FluxUtilThread
**************************************************************************

/*
internal const class FluxUtilThread : Thread
{
  new make() : super("FluxUtilThread") {}

  override Obj run()
  {
    options := Str:Obj[:]
    loop |Obj msg->Obj|
    {
      echo("---> $msg")
      fm := (FluxMsg)msg
      return trap(fm.name, fm.args)
    }
    return null
  }

  Obj readOptions(Type t, Str name)
  {
    file := Flux.homeDir + "${name}.fog".toUri
    try
    {
      if (file.exists) return file.readObj
    }
    catch (Err e)
    {
      type.log.error("Cannot load options: $file", e)
    }
    return t.make
  }
}

internal const class FluxMsg
{
  new make(Str n, Obj[] a) { name = n; args = a }
  override Str toStr() { return "${name}(${args})" }
  const Str name
  const Obj[] args
}
*/