//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 May 09  Brian Frank  Creation
//

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
  ** Find where target is a glob like "Str*" of either the
  ** file name or base name (without ext).  Or the target can
  ** be camel case abbr such as "FBB" for "FooBarBaz".
  **
  Uri[] find(Str target)
  {
    return send(target).get(5sec)
  }

  **
  ** Ensure given URI is in our index.
  **
  Void index(Uri uri)
  {
    try
      send(uri.toFile.normalize)
    catch (Err e)
      e.trace
  }

//////////////////////////////////////////////////////////////////////////
// Actor
//////////////////////////////////////////////////////////////////////////

  override Obj? receive(Obj? msg, Context cx)
  {
    // init list if not created yet
    map := cx["map"] as Uri:FileItem
    if (map == null) cx["map"] = map = Uri:FileItem[:]

    // handle find message
    if (msg is Str)  return doFind(map, msg)

    // handle index message
    t1 := Duration.now
    doIndex(map, msg)
    t2 := Duration.now
    log.debug("Indexed $msg [${(t2-t1).toLocale}] (total items=$map.size)")
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Matching
//////////////////////////////////////////////////////////////////////////

  Uri[] doFind(Uri:FileItem map, Str target)
  {
    // map glob to regex
    regex := Regex(target.replace("*", ".*").replace("?", "."))

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