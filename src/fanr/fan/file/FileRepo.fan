//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

using concurrent

**
** FileRepo implements a repository on the file system using
** a simple directory structure:
**
**   alpha/
**     alpha-1.0.1.pod
**     alpha-1.0.2.pod
**   beta/
**     beta-1.0.2.pod
**
** A background actor is used to manage the cached data
** structures read from the disk.
**
internal const class FileRepo : Repo
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Make for given URI which must reference a local dir
  new make(Uri uri)
  {
    // ensure URI maps to valid directory
    obj := uri.scheme == null ? File(uri, false) : uri.get
    file := obj as File
    if (file == null) throw Err("FileRepo uri does not resolve to file: $uri")
    if (!file.exists) throw Err("FileRepo uri does not exist: $uri")
    if (!file.isDir)  throw Err("FileRepo uri does not resolve to dir: $uri")

    // save normalized file/URI
    this.dir = file.normalize
    this.uri = this.dir.uri

    // construct actor and kick off load
    this.actor = Actor(actorPool) |msg| { receive(msg) }
    actor.send(FileRepoMsg(FileRepoMsg.load))
  }

//////////////////////////////////////////////////////////////////////////
// Repo
//////////////////////////////////////////////////////////////////////////

  override const Uri uri

  override Str:Str ping()
  {
    ["fanr.type":    typeof.toStr,
     "fanr.version": FileRepo#.pod.version.toStr]
  }

  override PodSpec? find(Str name, Version? ver, Bool checked := true)
  {
    msg := FileRepoMsg(FileRepoMsg.find, name, ver)
    spec := actor.send(msg).get(timeout) as PodSpec
    if (spec != null) return spec
    if (checked) throw UnknownPodErr("$name-$ver")
    return null
  }

  override PodSpec[] query(Str query, Int numVersions := 1)
  {
    msg := FileRepoMsg(FileRepoMsg.query, query, numVersions)
    Unsafe r := actor.send(msg).get(timeout)
    return r.val
  }

  override InStream read(PodSpec spec)
  {
    specToFile(spec).in
  }

  override PodSpec publish(File podFile)
  {
    msg := FileRepoMsg(FileRepoMsg.publish, podFile)
    PodSpec r := actor.send(msg).get(timeout)
    return r
  }

  ** Send actor message to refresh entire cache from disk
  Future refresh()
  {
    msg := FileRepoMsg(FileRepoMsg.refresh)
    return actor.send(msg)
  }

  ** Dispatch actor message to our FileRepoDb
  private Obj? receive(Obj? msg)
  {
    db := Actor.locals["fanr.file.db"] as FileRepoDb
    if (db == null)  Actor.locals["fanr.file.db"] = db = FileRepoDb(this)
    return db.dispatch(msg)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  internal File specToFile(PodSpec spec)
  {
    dir + `${spec.name}/${spec.toStr}.pod`
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static const ActorPool actorPool := ActorPool()
  private static const Duration timeout    := 30sec

  const File dir              // Root directory of the repo
  private const Actor actor   // FileRepoActor which manages database
}