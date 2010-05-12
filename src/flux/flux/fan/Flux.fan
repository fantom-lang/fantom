//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using concurrent
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
  ** Read an session options file into memory.  An option file
  ** is a serialized object stored at "etc/{pod}/{name}.fog".
  **
  static Obj? loadOptions(Pod pod, Str name, Type? t)
  {
    [Str:CachedOptions]? options := Actor.locals["flux.options"]
    if (options == null) Actor.locals["flux.options"] = options = Str:CachedOptions[:]

    // check cache
    path := "etc/${pod.name}/${name}.fog"
    cached := options[path]
    if (cached != null && cached.file.modified == cached.modified)
      return cached.val

    // not cached or modified since we loaded cache
    pathUri := path.toUri
    file := Env.cur.findFile(pathUri, false)
    if (file == null) file = Env.cur.workDir + pathUri
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
    options[path] = CachedOptions(file, value)

    return value
  }

  **
  ** Save sessions options back to file. An option file is a
  ** serialized object stored at "etc/{pod}/{name}.fog".
  ** Return true on success, false on failure.
  **
  static Bool saveOptions(Pod pod, Str name, Obj options)
  {
    uri := `etc/${pod.name}/${name}.fog`
    file := Env.cur.workDir + uri
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

  ** convenience 'flux' pod
  internal static const Pod pod := Flux#.pod

  ** convenience for images loaded out of icons
  internal static Image icon(Uri uri)
  {
    Image(("fan://icons"+uri).toUri)
  }

  ** Convenience for looking up a locale prop in the 'flux' pod.
  static Str locale(Str key)
  {
    Flux#.pod.locale(key)
  }

  ** Map list of qualified type names to types
  internal static Type[] qnamesToTypes(Str[] qnames)
  {
    qnames.map |qn->Type| { Type.find(qn) }
  }

  ** Given key like "flux.resource." find all indexed prop matches
  ** for t, t.super, etc where the values are qualified type names
  internal static Type[] indexForInheritance(Str base, Type? t)
  {
    acc := Type[,]
    while (t != null)
    {
      acc.addAll(qnamesToTypes(Env.cur.index(base + t.qname)))
      t = t.base
    }
    return acc
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