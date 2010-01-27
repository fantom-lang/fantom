//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using gfx
using fwt

**
** Flux provides system level utilities for flux applications
**
class Flux
{

  **
  ** Standard log for flux pod.
  **
  static const Log log := Flux#.pod.log

  **
  ** Read an session options file into memory.  An option file is a
  ** serialized object stored at "etc/flux/session/{name}.fog".
  **
  internal static Obj? loadSession(Str name, Type? t)
  {
    [Str:CachedOptions]? options := Actor.locals["flux.options"]
    if (options == null) Actor.locals["flux.options"] = options = Str:CachedOptions[:]

    // check cache
    cached := options[name]
    if (cached != null && cached.file.modified == cached.modified)
      return cached.val

    // not cached or modified since we loaded cache
    file := Env.cur.workDir + `etc/flux/session/${name}.fog`
    Obj? value := null
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
      log.err("Cannot load options: $file", e)
    }
    if (value == null) value = t?.make

    // update cache
    options[name] = CachedOptions(file, value)

    return value
  }

  **
  ** Save sessions options back to file. An option file is a
  ** serialized object stored at "etc/flux/session/{name}.fog".
  ** Return true on success, false on failure.
  **
  internal static Bool saveSession(Str name, Obj options)
  {
    file := Env.cur.workDir + `etc/flux/session/${name}.fog`
    try
    {
      log.debug("Save options: $file")
      file.writeObj(options, ["indent":2, "skipDefaults":true])
      return true
    }
    catch (Err e)
    {
      log.err("Cannot save options: $file", e)
      return false
    }
  }

  // convenience for icons
  internal static Image icon(Uri uri)
  {
    return Image(("fan:/sys/pod/icons"+uri).toUri)
  }

}

**************************************************************************
** CachedOptions
**************************************************************************

internal class CachedOptions
{
  new make(File f, Obj? v) { file = f; modified = f.modified; val = v }
  File file
  DateTime? modified
  Obj? val
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
      type.log.err("Cannot load options: $file", e)
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