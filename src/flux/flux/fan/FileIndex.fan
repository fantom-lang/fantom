//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 May 09  Brian Frank  Creation
//

using concurrent

**
** FileIndex is used to keep a working index of the files
** we care about (those in your Goto Into nav sidebar).
**
internal const class FileIndex : Actor
{

//////////////////////////////////////////////////////////////////////////
// Singleton
//////////////////////////////////////////////////////////////////////////

  static const FileIndex instance := make

  private new make() : super(ActorPool()) {}

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  const Log log := Log.get("fluxFileIndex")

  **
  ** Kick off index rebuild asynchronously.
  **
  Void rebuild() { send(`rebuild`) }

  **
  ** Check if done indexing and ready to search.
  **
  Bool ready()
  {
    try
      return send(`ready`).get(300ms)
    catch (TimeoutErr e)
      return false
  }

  **
  ** Find where target is a glob like "Str*" of either the
  ** file name or base name (without ext).  Or the target can
  ** be camel case abbr such as "FBB" for "FooBarBaz".
  **
  Uri[] find(Str target)
  {
    return send(target).get(5sec)
  }

//////////////////////////////////////////////////////////////////////////
// Actor
//////////////////////////////////////////////////////////////////////////

  override Obj? receive(Obj? msg)
  {
    // handle ready msg
    if (msg === `ready`) return true
    if (msg === `rebuild`) { doRebuild; return null }

    // handle find msg
    map := Actor.locals["fileIndexMap"] as Uri:FileItem
    if (map == null) throw Err("Must configure @indexDirs")
    return doFind(map, msg)
  }

//////////////////////////////////////////////////////////////////////////
// Matching
//////////////////////////////////////////////////////////////////////////

  Uri[] doFind(Uri:FileItem map, Str target)
  {
    // map glob to regex
    regex := Regex.glob(target)

    // find all matches
    matches := Uri[,]
    map.each |FileItem item|
    {
      if (item.match(target, regex)) matches.add(item.uri)
    }
    return matches
  }

//////////////////////////////////////////////////////////////////////////
// Indexing
//////////////////////////////////////////////////////////////////////////

  Void doRebuild()
  {
    Actor.locals["fileIndexMap"] = null
    dirs := GeneralOptions.load.indexDirs
    if (dirs.isEmpty) return

    map := Uri:FileItem[:]
    Actor.locals["fileIndexDir"] = dirs
    Actor.locals["fileIndexMap"] = map

    t1 := Duration.now
    dirs.each |dir|
    {
      try
      {
        f := File.make(dir, false).normalize
        if (!f.exists)
          log.warn("indexDir does not exist: $dir")
        else
          doIndex(map, f)
      }
      catch (Err e) log.info("indexDir invalid: $dir", e)
    }
    t2 := Duration.now
    log.info("Index rebuild ${(t2-t1).toLocale}")
  }

  Void doIndex(Uri:FileItem map, File f)
  {
    // skip if we've already crawled it
    if (map.containsKey(f.uri)) return
    if (include(f)) map[f.uri] = FileItem(f)
    if (crawl(f)) f.list.each |File kid| { doIndex(map, kid) }
  }

  Bool include(File f)
  {
    if (f.isDir) return true
    ext := f.ext
    if (ext == null) return true
    if (ext == "class" || ext == "exe") return false
    return true
  }

  Bool crawl(File f)
  {
    if (!f.isDir) return false
    name := f.name.lower
    if (name.startsWith(".")) return false
    if (name == "temp" || name == "tmp") return false
    return true
  }
}

internal class FileItem
{
  new make(File f) { uri = f.uri; abbr = toAbbr(uri.name) }

  Str toAbbr(Str n)
  {
    s := StrBuf()
    n.each |ch| { if (ch.isUpper) s.addChar(ch) }
    return s.toStr
  }

  Bool match(Str target, Regex regex)
  {
    abbr == target || regex.matches(uri.basename) || regex.matches(uri.name)
  }

  Uri uri      // URI of the file
  Str abbr    // camel case abbreviation such as FB for FooBar
}