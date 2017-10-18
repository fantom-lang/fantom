//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

using concurrent

**
** FileRepoDb maintains a mutable cache of the current database
** of PodSpecs.  It handles implementation of all the actor messaging.
**
internal class FileRepoDb
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(FileRepo repo)
  {
    this.repo = repo
    this.dir  = repo.dir
    this.log  = Log.get("fanr")
    // this.log.level = LogLevel.debug
  }

//////////////////////////////////////////////////////////////////////////
// Dispatch
//////////////////////////////////////////////////////////////////////////

  Obj? dispatch(FileRepoMsg msg)
  {
    switch (msg.id)
    {
      case FileRepoMsg.load:     return load
      case FileRepoMsg.find:     return find(msg.a, msg.b)
      case FileRepoMsg.query:    return query(msg.a, msg.b)
      case FileRepoMsg.publish:  return publish(msg.a)
      case FileRepoMsg.refresh:  return refresh
      default:                   throw Err("Unknown msg: $msg")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  private Obj? load()
  {
    t1 := Duration.now
    log.debug("FileRepoDb.loading...")

    dir.listDirs.each |podDir| { loadPod(podDir) }

    t2 := Duration.now
    log.debug("FileRepoDb.loaded ($podDirs.size pods loaded in ${(t2-t1).toLocale})")
    return null
  }

  private Void loadPod(File dir)
  {
    // look thru directory to find current version
    Version? curVer := null
    File? curFile := null
    dir.listFiles.each |file|
    {
      n := file.name
      dash := n.indexr("-")
      if (!n.endsWith(".pod") || dash == null) return
      ver := Version.fromStr(n[dash+1..-5], false)
      if (ver == null) return
      if (curVer == null || ver > curVer)
      {
        curVer = ver
        curFile = file
      }
    }

    // if we found a current version, load it
    if (curFile != null)
    {
      try
      {
        curSpec := PodSpec.load(curFile)
        podDirs[curSpec.name] = PodDir(dir, curSpec)
      }
      catch (Err e)
      {
        log.err("Corrupt pod: $curFile", e)
      }
    }
  }

  private Void loadAll(PodDir podDir)
  {
    // if already loaded, we can bail
    if (podDir.all != null) return

    // load all files
    podDir.all = PodSpec[,]
    podDir.dir.list.each |file|
    {
      if (file.ext != "pod") return
      try
        podDir.all.add(PodSpec.load(file))
      catch (Err e)
        log.err("Corrupt pod: $file", e)
    }

    // sort by highest to lowest version
    podDir.sortAll
  }

  private Obj? refresh()
  {
    podDirs.clear
    return load
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  private PodSpec? find(Str name, Version? ver)
  {
    // lookup dir record for name
    dir := podDirs[name]
    if (dir == null) return null

    // if version null, then find latest one
    if (ver == null) return dir.cur

    // ensure all pod versions are fully loaded
    loadAll(dir)

    // find exact version match
    return dir.all.find |pod| { pod.version == ver }
  }

//////////////////////////////////////////////////////////////////////////
// Query
//////////////////////////////////////////////////////////////////////////

  private Unsafe query(Str query, Int numVersions)
  {
    // sanity checks
    if (numVersions < 1) throw ArgErr("numVersions < 1")

    // parse the query
    q := Query.fromStr(query)

    // match
    acc := PodSpec[,]
    podDirs.each |podDir|
    {
      // check if we don't match on name we can short circuit
      if (!q.includeName(podDir.cur)) return

      // if numVersions is one and we match against cur,
      // we can avoid any lazy loading of all the pods
      if (numVersions == 1 && q.include(podDir.cur))
      {
        acc.add(podDir.cur)
        return
      }

      // ensure all pod versions are fully loaded
      loadAll(podDir)

      // check every pod until we hit our limit
      matches := 0
      for (i:=0; i<podDir.all.size; ++i)
      {
        spec := podDir.all[i]
        if (q.include(spec))
        {
          acc.add(spec)
          matches++
          if (matches >= numVersions) break
        }
      }
    }
    return Unsafe(acc)
  }

//////////////////////////////////////////////////////////////////////////
// Publish
//////////////////////////////////////////////////////////////////////////

  private PodSpec publish(File inputFile)
  {
    // verify its valid pod and parse its meta as PodSpec
    spec := PodSpec.load(inputFile)

    // get dest file in our db and verify it doesnt already exist
    dbFile := repo.specToFile(spec)
    if (dbFile.exists) throw Err("Pod already published: $spec")

    // copy it
    inputFile.copyTo(dbFile)

    // re-read spec using correct dbFile
    spec = PodSpec.load(dbFile)

    // check if we need to update our data structures
    podDir := podDirs[spec.name]
    if (podDir == null)
    {
      // add new pod
      podDirs[spec.name] = PodDir(dbFile.parent, spec)
    }
    else
    {
      // update existing pod cur/all
      if (spec.version > podDir.cur.version) podDir.cur = spec
      if (podDir.all != null) { podDir.all.add(spec); podDir.sortAll }
    }

    // return spec
    return spec
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  const FileRepo repo
  const File dir
  const Log log
  private Str:PodDir podDirs := [:]
}

**************************************************************************
** PodDir
**************************************************************************

internal class PodDir
{
  new make(File dir, PodSpec cur) { this.dir = dir; this.cur = cur }
  const File dir   // directory used to store pod files
  PodSpec cur      // current version
  PodSpec[]? all   // lazily loaded all versions

  // sort by highest to lowest version
  Void sortAll() { all.sortr |a, b| { a.version <=> b.version } }
}

**************************************************************************
** FileRepoMsg
**************************************************************************

internal const class FileRepoMsg
{
  const static Int load     := 0  //
  const static Int find     := 1  // a=name, b=version
  const static Int query    := 2  // a=query, b=numVersions
  const static Int versions := 3  // a=Str
  const static Int publish  := 4  // a=File
  const static Int refresh  := 5  //

  new make(Int id, Obj? a := null, Obj? b := null) { this.id = id; this.a = a; this.b = b}

  const Int id
  const Obj? a
  const Obj? b
}

