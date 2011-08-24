//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

**
** DocPod models the documentation of a `sys::Pod`.
**
class DocPod
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Construct from meta.props
  new make(DocEnv env, Str:Str meta)
  {
    this.env     = env
    this.name    = getReq(meta, "pod.name")
    this.version = Version.fromStr(getReq(meta, "pod.version"))
    this.depends = parseDepends(meta)
    this.summary = getReq(meta, "pod.summary")
    this.meta    = meta
  }

  private static Str getReq(Str:Str m, Str n)
  {
    m[n] ?: throw Err("Missing '$n' in meta.props")
  }

  private static Depend[] parseDepends(Str:Str m)
  {
    s := getReq(m, "pod.depends").trim
    if (s.isEmpty) return Depend#.emptyList
    return s.split(';').map |tok->Depend| { Depend(tok) }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** Environment used to load and manage this pod
  DocEnv env { private set }

  ** Simple name of the pod such as "sys".
  const Str name

  ** Version number for this pod.
  const Version version

  ** Get the declared list of dependencies for this pod.
  const Depend[] depends

  ** Summary string for the pod
  const Str summary

  ** Always return `name`.
  override Str toStr() { name }

  ** Get the meta name/value pairs for this pod.
  ** See [docLang]`docLang::Pods#meta`.
  const Str:Str meta

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  **
  ** List of the all defined types.
  **
  DocType[] types() { load.typeList }

  **
  ** Find a type by name.  If the type doesn't exist and checked
  ** is false then return null, otherwise throw UnknownTypeErr.
  **
  DocType? type(Str typeName, Bool checked := true)
  {
    load
    t := typeMap[typeName]
    if (t != null) return t
    if (checked) throw UnknownTypeErr("${this.name}::${typeName}")
    return null
  }

  **
  ** Lazily perform a deep load of a DocPod.  When the DocPod is
  ** constructed it is "hollow" and we only know summary information
  ** gleaned from meta.props - this is all we need for top-level
  ** index.  But once we need to know types, etc it is time to perform
  ** a deep load.  To avoid pinning open the pod zip file we just
  ** load every type at once.
  **
  private This load()
  {
    // short circuit if already loaded
    if (typeList != null) return this

    // these are the data structures we'll be building up
    typeMap  := Str:DocType[:]
    DocChapter? podDoc := null
    chapterMap := Str:DocChapter[:]
    Obj[]? chapterIndex := null

    // get file to use from DocLoader
    file := env.loader.findPodFile(name) ?: throw Err("File not found: $name")
    zip := Zip.open(file)
    try
    {
      // iterate thru the zip file looking for the files we need
      zip.contents.each |f|
      {
        // if doc/{type}.apidoc
        if (f.path[0] == "doc2" && f.ext == "apidoc")
        {
          type := ApiDocParser(name, f.in).parseType
          typeMap[type.name] = type
        }

        // if doc/{type}.fandoc
        if (f.path[0] == "doc" && f.ext == "fandoc")
        {
          isPodDoc := f.basename == "pod"
          chapter := DocChapter
          {
            it.pod  = this.name
            it.name = isPodDoc ? "pod-doc" : f.basename
            it.loc  = DocLoc(f.name, 1)
            it.doc  = DocFandoc(it.loc, f.in.readAllStr)
          }
          if (isPodDoc)
            podDoc = chapter
          else
            chapterMap[chapter.name] = chapter
        }

        // if doc/index.fog
        if (f.path[0] == "doc" && f.name == "index.fog")
          chapterIndex = f.readObj
      }
    }
    finally zip.close

    // generate chapterIndex if not specified
    if (chapterIndex == null)
    {
      chapterIndex = [,]
      chapterMap.each |c| { chapterIndex.add([c.name, ""]) }
    }

    // save state
    this.typeList    = typeMap.vals.sort(|a, b| { a.name <=> b.name }).ro
    this.typeMap     = typeMap
    this.podDocRef   = podDoc
    this.chapterList = chapterMap.vals.ro
    this.chapterMap  = chapterMap.ro
    this.chapterIndexRef = chapterIndex
    return this
  }

//////////////////////////////////////////////////////////////////////////
// Chapters
//////////////////////////////////////////////////////////////////////////

  **
  ** Return pod-doc file as a chapter instance or null
  **
  DocChapter? podDoc() { load.podDocRef }

  **
  ** A *manual* pod is a pod with only fandoc chapters and no types.
  **
  Bool isManual() { load; return typeList.isEmpty && !chapterList.isEmpty }

  **
  ** Return parsed "index.fog" if specified which is a list
  ** of sections as a 'Str' or chapter links as '[Uri, Str]'
  **
  Obj[] chapterIndex() { load.chapterIndexRef }

  **
  ** Find a chapter by name.  If the chapter doesn't exist and checked
  ** is false then return null, otherwise throw Err.
  **
  DocChapter? chapter(Str chapterName, Bool checked := true)
  {
    load
    c := chapterMap[chapterName]
    if (c != null) return c
    if (checked) throw Err("Unknown chapter: ${this.name}::${chapterName}")
    return null
  }

  **
  ** If this is a manual like docLang, return list of chapters.
  **
  DocChapter[] chapters() { load.chapterList }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  private DocType[]? typeList
  private [Str:DocType]? typeMap
  private DocChapter? podDocRef
  private DocChapter[]? chapterList
  private [Str:DocChapter]? chapterMap
  private Obj[]? chapterIndexRef
}