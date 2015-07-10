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
    this.vars = super.vars
    this.path = parsePath(super.vars["FAN_ENV_PATH"] ?: "")
    this.workDir = path.first
    this.tempDir = workDir + `temp/`
  }

  **
  ** Prototype to explore using directory structure to setup
  ** path by placing a "fan.props" in working directory.
  **
  @NoDoc new makeProps(File file) : super.make(Env.cur)
  {
    props := file.readProps

    vars := super.vars.rw
    props.each |v, n|
    {
      if (n.startsWith("env.") && n.size > 5) vars[n[4..-1]] = v
    }

    this.vars = vars
    this.path = parsePath(props["path"] ?: "").insert(0, file.parent.normalize)
    this.workDir = path.first
    this.tempDir = workDir + `temp/`
  }

  private File[] parsePath(Str path)
  {
    acc := File[,]
    try
    {
      path.split(File.pathSep[0]).each |item|
      {
        if (item.isEmpty) return
        dir := File.os(item).normalize
        if (!dir.exists) dir = File(item.toUri.plusSlash, false).normalize
        if (!dir.exists) { log.warn("Dir not found: $dir"); return }
        if (!dir.isDir) { log.warn("Not a dir: $dir"); return }
        acc.add(dir)
      }
    }
    catch (Err e) log.err("Cannot parse path: $path", e)
    acc.add(Env.cur.homeDir)
    return acc
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
  ** Get the environment variables as a case insensitive, immutable
  ** map of Str name/value pairs.  The environment map is initialized
  ** from the following sources from lowest priority to highest priority:
  **   1. shell environment variables
  **   2. Java system properties (Java VM only obviously)
  **   3. props in "fan.props" prefixed with "env."
  **
  override const Str:Str vars

  **
  ** Search `path` for given file.
  **
  override File? findFile(Uri uri, Bool checked := true)
  {
    if (uri.isPathAbs) throw ArgErr("Uri must be rel: $uri")
    result := path.eachWhile |dir|
    {
      f := dir.plus(uri, false)
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