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

  ** Open this pod file as a zip file.
  Zip open()
  {
    file := env.loader.envFindPodFile(name)
    if (file == null) throw Err("Cannot map '$name' to pod file")
    return Zip.open(file)
  }

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
    if (loaded) return this

    // these are the data structures we'll be building up
    types     := Str:DocType[:]
    chapters  := Str:DocChapter[:]
    indexFog  := null
    resources := Uri[,]
    sources   := Uri[,]

    // process zip contents
    zip := open
    try
    {
      // iterate thru the zip file looking for the files we need
      zip.contents.each |f|
      {
        try
        {
          // if this is src/{file}, save to source list
          if (f.path[0] == "src")
          {
            if (f.path.size == 2) sources.add(f.uri)
            return
          }

          // we only care about files in doc/*
          if (f.path[0] != "doc") return

          // if doc/{type}.apidoc
          if (f.ext == "apidoc")
          {
            type := ApiDocParser(name, f.in).parseType
            types[type.name] = type
          }

          // if doc/{type}.fandoc
          if (f.ext == "fandoc")
          {
            chapter := DocChapter(this, f)
            chapters[chapter.name] = chapter
          }

          // if doc/index.fog
          else if (f.name == "index.fog")
          {
            indexFog = f.readObj
          }

          // otherwise assume its a resource
          else
          {
            resources.add(f.uri)
          }
        }
        catch (Err e) env.err("Cannot parse", DocLoc("${name}::${f}", 0), e)
      }
    }
    finally zip.close

    // save state
    saveTypes(types)
    saveChapters(chapters, indexFog)
    saveResources(resources)
    saveSources(sources)
    loaded = true
    return this
  }

  private Void saveTypes(Str:DocType map)
  {
    // create sorted list
    list := map.vals.sort|a, b| { a.name <=> b.name }

    // build toc
    toc := Obj[,]
    mixins  := DocType[,]
    classes := DocType[,]
    enums   := DocType[,]
    facets  := DocType[,]
    errs    := DocType[,]
    list.each |t|
    {
      if (t.isEnum) enums.add(t)
      else if (t.isFacet) facets.add(t)
      else if (t.isMixin) mixins.add(t)
      else if (t.isErr) errs.add(t)
      else classes.add(t)
    }
    if (mixins.size  > 0) toc.add("Mixins").addAll(mixins)
    if (classes.size > 0) toc.add("Classes").addAll(classes)
    if (enums.size   > 0) toc.add("Enums").addAll(enums)
    if (facets.size  > 0) toc.add("Facets").addAll(facets)
    if (errs.size    > 0) toc.add("Errs").addAll(errs)

    // save to fields
    this.typeMap  = map
    this.typeList = list.ro
    this.tocRef = toc.ro
  }

  private Void saveChapters(Str:DocChapter map, Obj[]? indexFog)
  {
    // create sorted list of chapters
    list := map.vals.sort |a, b| { a.name <=> b.name }

    // if this pod has types, it can't be a manual
    if (!typeList.isEmpty)
    {
      if (list.size == 1 && list.first.isPodDoc)
        this.podDocRef = list.first
      return
    }

    // generate indexFog if not specified
    if (indexFog == null)
    {
      if (!map.isEmpty) env.err("Manual missing '${name}::index.fog'", DocLoc(name, 0))
      indexFog = [,]
      list.each |c| { indexFog.add([c.name.toUri, ""]) }
    }

    // order the chapters by indexFog:
    //   - map DocChapter summary
    //   - check that chapters/index.fog match
    toc := Obj[,]
    indexLoc := DocLoc("${name}::index.fog", 0)
    indexMap := map.dup
    indexFog.each |item|
    {
      // grouping header
      if (item is Str) { toc.add(item); return }

      // get item as Uri/Str pair
      Uri? uri
      Str? summary
      try
      {
        uri = ((List)item).get(0)
        summary = ((List)item).get(1)
      }
      catch { env.err("Invalid item: $item", indexLoc); return }

      // lookup chapter and remove from map so we know it was indexed
      c := indexMap.remove(uri.toStr)
      if (c == null) { env.err("Unknown chapter: $uri", indexLoc); return }

      // add it toc
      toc.add(c)

      // map summary
      c.summaryRef.val = summary
    }

    // report errors for chapters not in index
    indexMap.each |c| { env.err("Chapter not in index: $c.name", indexLoc) }

    // redo list now that we have chapters ordered by index
    list = toc.findType(DocChapter#)

    // map DocChapter num/prev/next
    list.each |c, i|
    {
      c.numRef.val = i+1
      if (i > 0) c.prevRef.val = list[i-1]
      c.nextRef.val = list.getSafe(i+1)
    }

    // save to fields
    this.chapterMap  = map
    this.chapterList = list.ro
    this.tocRef = toc.ro
  }

  private Void saveResources(Uri[] list)
  {
    this.resourceList = list.sort.ro
  }

  private Void saveSources(Uri[] list)
  {
    this.sourceList = list.sort.ro
    this.sourceMap  = Str:Uri[:].addList(list) |uri| { uri.name }
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
  ** If this a API pod, this is the Str/DocType where the string indicates
  ** groupings such as "Classes", "Mixins", etc.  If this is a manual return
  ** the list of Str/DocChapter where Str indicates index grouping headers.
  **
  Obj[] toc() { load.tocRef }

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

  **
  ** Resource files in pod which are used to support the
  ** documentation such as images used by the fandoc chapters.
  ** The Uris are internal to the pod zip file.
  **
  Uri[] resources() { load.resourceList }

  **
  ** Source files in pod which should be included in documentation.
  ** The Uris are internal to the pod zip file.
  **
  Uri[] sources() { load.sourceList }

  **
  ** Return pod internal URI to source code for filename, or
  ** if not available return null/raise exception.
  **
  Uri? source(Str filename, Bool checked := true)
  {
    load
    uri := sourceMap[filename]
    if (uri != null) return uri
    if (checked) throw UnresolvedErr("source file: $filename")
    return null
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  private Bool loaded
  private DocType[]? typeList
  private [Str:DocType]? typeMap
  private DocChapter? podDocRef
  private DocChapter[]? chapterList := [,]
  private [Str:DocChapter]? chapterMap := [:]
  private Obj[]? tocRef
  private Uri[]? resourceList
  private Uri[]? sourceList
  private [Str:Uri]? sourceMap
}