//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  31 Jan 10  Brian Frank  Creation
//

using concurrent

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
    vars := super.vars
    path := parsePath(null, vars["FAN_ENV_PATH"] ?: "")

    this.vars = vars
    this.pathRef = AtomicRef(path.toImmutable)
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

    path := parsePath(file, props["path"] ?: "")
    doAdd(path, file.parent.normalize, 0)

    this.vars = vars
    this.pathRef = AtomicRef(path.toImmutable)
  }

  private File[] parsePath(File? ref, Str path)
  {
    acc := File[,]
    try
    {
      path.split(File.pathSep[0]).each |item|
      {
        if (item.isEmpty) return
        dir := (item.startsWith("..") && ref != null)
          ? File.os("$ref.parent.osPath/$item").normalize
          : File.os(item).normalize
        if (!dir.exists) dir = File(item.toUri.plusSlash, false).normalize
        if (!dir.exists) { log.warn("Dir not found: $dir"); return }
        if (!dir.isDir) { log.warn("Not a dir: $dir"); return }
        doAdd(acc, dir)

      }
    }
    catch (Err e) log.err("Cannot parse path: $path", e)
    doAdd(acc, Env.cur.homeDir)
    return acc
  }

  **
  ** Search path of directories in priority order.  The
  ** last item in the path is always the `sys::Env.homeDir`
  **
  File[] path() { pathRef.val }
  private const AtomicRef pathRef

  **
  ** Working directory is always first item in `path`.
  **
  override File workDir() { path.first }

  **
  ** Temp directory is always under `workDir`.
  **
  override File tempDir() { workDir + `temp/` }

  **
  ** Add given directory to the front of the path which
  ** will update both the workDir and tempDir
  **
  @NoDoc Void addToPath(File dir)
  {
    dir = dir.normalize
    pathRef.val = doAdd(path.dup, dir, 0).toImmutable
  }

  **
  ** Add a directory to the path only if its not already mapped
  **
  private static File[] doAdd(File[] path, File dir, Int insertIndex := -1)
  {
    if (!path.contains(dir))
    {
      if (insertIndex < 0) path.add(dir)
      else path.insert(insertIndex, dir)
    }
    return path
  }

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