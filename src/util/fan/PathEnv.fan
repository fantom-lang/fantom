//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  31 Jan 10  Brian Frank  Creation
//

**
** PathEnv is a simple implementation of a Fantom
** environment which uses a search path to resolve files.
**
const class PathEnv : Env
{

  **
  ** Constructor initializes the search path using the
  ** 'FAN_ENV_PATH' environment variable (see `sys::Env.vars`).
  **
  new make() : super(Env.cur)
  {
    try
    {
      var := vars["FAN_ENV_PATH"] ?: ""
      acc := File[,]
      var.split(File.pathSep[0]).each |item|
      {
        if (item.isEmpty) return
        dir := File.os(item).normalize
        if (!dir.exists) dir = File(item.toUri.plusSlash, false).normalize
        if (!dir.exists) { log.warn("Dir not found: $dir"); return }
        if (!dir.isDir) { log.warn("Not a dir: $dir"); return }
        acc.add(dir)
      }
      acc.add(Env.cur.homeDir)
      this.path = acc
    }
    catch (Err e)
    {
      log.err("Initialization error", e)
      this.path = [Env.cur.homeDir]
    }
    this.workDir = path.first
    this.tempDir = workDir + `temp/`
  }

  **
  ** Search path of directories in priority order.  The
  ** last item in the path is always the `sys::Env.homeDir`
  **
  const File[] path

  **
  ** Working directory is always first item in `path`.
  **
  override const File workDir

  **
  ** Temp directory is always under `workDir`.
  **
  override const File tempDir

  **
  ** Search `path` for given file.
  **
  override File? findFile(Uri uri, Bool checked := true)
  {
    if (!uri.isRel) throw ArgErr("Uri must be rel: $uri")
    result := path.eachWhile |dir|
    {
      f := dir + uri
      return f.exists ? f : null
    }
    if (result != null) return result
    if (checked) throw UnresolvedErr(uri.toStr)
    return null
  }

  **
  ** Search `path` for all versions of given file.
  **
  override File[] findAllFiles(Uri uri)
  {
    acc := File[,]
    path.each |dir|
    {
      f := dir + uri
      if (f.exists) acc.add(f)
    }
    return acc
  }

  **
  ** Search `path` for all "lib/fan/*.pod" files.
  **
  override Str[] findAllPodNames()
  {
    acc := Str[,]
    path.each |dir|
    {
      lib := dir + `lib/fan/`
      lib.list.each |f|
      {
        if (f.isDir || f.ext != "pod") return
        acc.add(f.basename)
      }
    }
    return acc
  }

  private const Log log := Log.get("pathenv")
}